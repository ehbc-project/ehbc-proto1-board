library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity isa_controller is
    port (
        i_rst:              in std_logic;
        i_clk:              in std_logic;
        i_isaclk:           in std_logic;
        i_select:           in std_logic;
        i_sel_isar:         in std_logic;

        -- Internal Bus Signals
        i_size:             in std_logic_vector(1 downto 0);
        i_rd:               in std_logic;
        i_wr:               in std_logic;
        i_a:                in std_logic_vector(23 downto 16);
        i_d:                in std_logic_vector(7 downto 0);
        o_d:                out std_logic_vector(7 downto 0) := (others => '0');
        o_berr:             out std_logic := '0';
        o_ack8:             out std_logic := '0';
        o_ack16:            out std_logic := '0';

        -- ISA Bus Signals
        i_nows:             in std_logic;
        i_iochrdy:          in std_logic;
        i_iochck:           in std_logic;
        o_ale:              out std_logic := '0';
        o_sbhe:             out std_logic := '0';
        o_smemr:            out std_logic := '0';
        o_smemw:            out std_logic := '0';
        o_memr:             out std_logic := '0';
        o_memw:             out std_logic := '0';
        o_ior:              out std_logic := '0';
        o_iow:              out std_logic := '0';
        o_memcs16:          out std_logic := '0';
        o_iocs16:           out std_logic := '0';

        -- Buffer Control Signals
        o_bufen:            out std_logic := '0';
        o_bufdir:           out std_logic := '0'
    );
end isa_controller;

architecture behavioral of isa_controller is
    type state_t is (S_IDLE, S_CMD, S_WAIT, S_END);
    signal state: state_t := S_IDLE;
    signal wait_count: unsigned(2 downto 0) := (others => '0');
    signal xferend: boolean := false;
    signal error: boolean := false;

    signal io: boolean;
    signal mem: boolean;
    signal smem: boolean;

    signal command_enable: boolean;

    signal isar_data: std_logic_vector(7 downto 0);
    signal isa_enable: boolean;
    signal isa8_default_ws: boolean;
    signal isa16_default_ws: boolean;
    signal isa8_cmd_delay: unsigned(1 downto 0);
    signal isa16_cmd_delay: unsigned(1 downto 0);

    signal ack8_array: std_logic_vector(1 downto 0) := (others => '0');
begin
    o_ack8 <= or ack8_array;

    register_isar: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => i_sel_isar,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => o_d,
            o_ack8      => ack8_array(0),

            o_reg       => isar_data
        );
    isa_enable <= isar_data(7) = '1';
    isa8_default_ws <= isar_data(5) = '1';
    isa16_default_ws <= isar_data(4) = '1';
    isa8_cmd_delay <= unsigned(isar_data(3 downto 2));
    isa16_cmd_delay <= unsigned(isar_data(1 downto 0));

    io <= i_a(23 downto 16) = x"00";
    mem <= i_a(23 downto 20) = x"0" and not io;
    smem <= i_a(23 downto 20) /= x"0";

    o_ior <= '1' when io and i_rd = '1' and command_enable else '0';
    o_iow <= '1' when io and i_wr = '1' and command_enable else '0';
    o_memr <= '1' when mem and i_rd = '1' and command_enable else '0';
    o_memw <= '1' when mem and i_wr = '1' and command_enable else '0';
    o_smemr <= '1' when smem and i_rd = '1' and command_enable else '0';
    o_smemw <= '1' when smem and i_wr = '1' and command_enable else '0';

    o_iocs16 <= '1' when io and (i_rd or i_wr) = '1' and i_size /= SIZE_8 and command_enable else '0';
    o_memcs16 <= '1' when (mem or smem) and (i_rd or i_wr) = '1' and i_size /= SIZE_8 and command_enable else '0';

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' or not isa_enable then
            o_d <= (others => '0');
            o_berr <= '0';
            ack8_array(1) <= '0';
            o_ack16 <= '0';

            o_bufen <= '0';
            o_bufdir <= '0';

            xferend <= false;
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    -- clear ack and error
                    ack8_array(1) <= '0';
                    o_ack16 <= '0';
                    o_berr <= '0';
                when S_CMD =>
                    -- initialize buffer
                    o_bufen <= '1';
                    o_bufdir <= i_rd;  -- '1' when read, '0' when write
                    xferend <= false;
                when S_END =>
                    if error then
                        o_berr <= '1';
                        xferend <= true;
                    elsif not xferend then
                        -- send ack
                        if i_size = SIZE_8 then
                            -- 8-bit cycle
                            ack8_array(1) <= '1';
                        else
                            -- 16-bit cycle
                            o_ack16 <= '1';
                        end if;
                    elsif not (i_rd or i_wr) then
                        -- clear ack
                        o_bufen <= '0';
                        ack8_array(1) <= '0';
                        o_ack16 <= '0';
                        o_berr <= '0';
                        xferend <= true;
                    end if;
                when others =>
            end case;

        end if;
    end process;

    process(i_isaclk, i_rst) is
    begin
        if i_rst = '1' or not isa_enable then
            state <= S_IDLE;
            command_enable <= false;
            wait_count <= (others => '0');
            error <= false;

            o_ale <= '0';
            o_sbhe <= '0';
        elsif rising_edge(i_isaclk) then
            if i_iochck = '1' then
                error <= true;
            end if;

            case state is
                when S_IDLE =>
                    if i_select and (i_rd or i_wr) then
                        o_ale <= '1';
                        if i_size = SIZE_8 then
                            -- 8-bit cycle
                            wait_count <= '0' & (unsigned(isa8_cmd_delay) - 1);
                        else
                            -- 16-bit cycle
                            wait_count <= '0' & (unsigned(isa16_cmd_delay) - 1);
                        end if;
                        state <= S_CMD;
                    end if;
                when S_CMD =>
                    o_ale <= '1';
                    if wait_count = 0 then
                        command_enable <= true;

                        if i_size = SIZE_8 then -- 8-bit cycle
                            wait_count <= "100" when isa8_default_ws else "101";
                        else -- 16-bit cycle
                            o_sbhe <= '1';
                            wait_count <= "001" when isa16_default_ws else "010";
                        end if;
                    
                        state <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if (wait_count = 0 and i_iochrdy = '1') or i_nows = '1' then
                        state <= S_END;
                    end if;
                when S_END =>
                    command_enable <= false;
                    error <= false;
                    o_sbhe <= '0';
                    o_ale <= '0';
                    state <= S_IDLE;
            end case;

            if wait_count /= 0 then
                wait_count <= wait_count - 1;
            end if;
        end if;
    end process;
end behavioral;
