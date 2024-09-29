library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity isab is
    port (
        i_rst: in std_logic;
        i_clk: in std_logic;
        i_isaclk: in std_logic;

        i_en_isa: in std_logic;
        i_en_isar: in std_logic;

        i_size: in std_logic_vector(1 downto 0);
        i_rd: in std_logic;
        i_wr: in std_logic;
        i_a: in std_logic_vector(23 downto 16);
        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        o_berr: out std_logic;
        
        o_ack8: out std_logic := '0';
        o_ack16: out std_logic := '0';

        i_nows: in std_logic;
        i_iochrdy: in std_logic;
        i_iochck: in std_logic;
        o_ale: out std_logic := '0';
        o_sbhe: out std_logic := '0';
        o_smemr: out std_logic;
        o_smemw: out std_logic;
        o_memr: out std_logic;
        o_memw: out std_logic;
        o_ior: out std_logic;
        o_iow: out std_logic;
        o_memcs16: out std_logic;
        o_iocs16: out std_logic;
        o_bufen: out std_logic;
        o_bufdir: out std_logic := '0'
    );
end isab;

architecture behavioral of isab is
    type state_t is (S_IDLE, S_CMD, S_WAIT, S_END);
    signal state: state_t := S_IDLE;
    signal wait_count: unsigned(2 downto 0) := "000";
    signal xferend: boolean := false;

    signal isar_data: std_logic_vector(7 downto 0);
    signal enable_controller: std_logic;
    signal command_delay_8: unsigned(1 downto 0) := "00";
    signal command_delay_16: unsigned(1 downto 0) := "00";
    signal default_wait_state_8: std_logic;
    signal default_wait_state_16: std_logic;

    signal io: std_logic;
    signal mem: std_logic;
    signal smem: std_logic;

    signal command_enable: std_logic := '0';

    signal ack8_isar: std_logic;
    signal ack8_isa: std_logic;
begin
    o_ior <= io and i_rd and command_enable;
    o_iow <= io and i_wr and command_enable;
    o_memr <= mem and i_rd and command_enable;
    o_memw <= mem and i_wr and command_enable;
    o_smemr <= smem and i_rd and command_enable;
    o_smemw <= smem and i_wr and command_enable;
    o_iocs16 <= io and (i_rd or i_wr) and (i_size(1) or not i_size(0)) and command_enable;
    o_memcs16 <= (mem or smem) and (i_rd or i_wr) and (i_size(1) or not i_size(0)) and command_enable;
    o_berr <= i_iochck;
    
    o_ack8 <= ack8_isa or ack8_isar;

    command_delay_16 <= unsigned(isar_data(7 downto 6));
    command_delay_8 <= unsigned(isar_data(5 downto 4));
    enable_controller <= isar_data(2);
    default_wait_state_16 <= isar_data(1);
    default_wait_state_8 <= isar_data(0);

    isar: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_isar,
            i_rd   => i_rd,
            i_wr   => i_wr,
            o_ack8 => ack8_isar,
            i_d    => i_d,
            o_d    => o_d,
            o_reg  => isar_data
        );

    isa_addr_decoder: entity work.isa_addr_decoder
        port map (
            i_a    => i_a,
            o_io   => io,
            o_mem  => mem,
            o_smem => smem
        );

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            ack8_isa <= '0';
            o_ack16 <= '0';
            o_bufen <= '0';
            xferend <= false;
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    ack8_isa <= '0';
                    o_ack16 <= '0';
                when S_CMD =>
                    o_bufen <= '1';
                    o_bufdir <= i_rd;  -- '1' when read, '0' when write
                    xferend <= false;
                when S_END =>
                    if not xferend then
                        if i_size = "01" then  -- 8-bit cycle
                            ack8_isa <= '1';
                        else  -- 16-bit cycle
                            o_ack16 <= '1';
                        end if;
                    end if;

                    if not i_rd and not i_wr then
                        o_bufen <= '0';
                        ack8_isa <= '0';
                        o_ack16 <= '0';
                        xferend <= true;
                    end if;
                when others =>
            end case;

        end if;
    end process;

    process(i_isaclk, i_rst) is
    begin
        if i_rst = '1' then
            command_enable <= '0';
            o_sbhe <= '0';
            state <= S_IDLE;
        elsif rising_edge(i_isaclk) then
            case state is
                when S_IDLE =>
                    if i_en_isa and enable_controller and (i_rd or i_wr) then
                        o_ale <= '1';
                        if i_size = "01" then -- 8-bit cycle
                            wait_count <= '0' & (command_delay_8 - 1);
                        else -- 16-bit cycle
                            wait_count <= '0' & (command_delay_16 - 1);
                        end if;
                        state <= S_CMD;
                    end if;
                when S_CMD =>
                    o_ale <= '1';
                    if wait_count = 0 then
                        command_enable <= '1';

                        if i_size = "01" then -- 8-bit cycle
                            wait_count <= "100" when default_wait_state_8 else "101";
                        else -- 16-bit cycle
                            o_sbhe <= '1';
                            wait_count <= "001" when default_wait_state_16 else "010";
                        end if;
                    
                        state <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if (wait_count = 0 and i_iochrdy = '1') or i_nows = '1' then
                        state <= S_END;
                    end if;
                when S_END =>
                    command_enable <= '0';
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
