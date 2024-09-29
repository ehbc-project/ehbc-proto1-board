library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity ideb is
    port (
        i_rst: in std_logic;
        i_clk: in std_logic;
        
        i_en_ide: out std_logic_vector(1 downto 0);
        i_en_ider: in std_logic;

        i_size: in std_logic_vector(1 downto 0);
        i_rd: in std_logic;
        i_wr: in std_logic;
        i_a0: in std_logic;
        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        
        o_ack8: out std_logic := '0';
        o_ack16: out std_logic := '0';

        o_iocs16: out std_logic := '0';
        o_dior: out std_logic := '0';
        o_diow: out std_logic := '0';
        i_iochrdy: in std_logic := '0';

        o_bufen: out std_logic;
        o_bufdir: out std_logic := '0'
    );
end ideb;

architecture behavioral of ideb is
    type state_t is (S_IDLE, S_CMD, S_WAIT, S_XFER, S_END);
    signal wait_count: unsigned(3 downto 0) := x"0";
    signal state: state_t := S_IDLE;

    signal ider_data: std_logic_vector(15 downto 0);
    signal enable_controller: std_logic;
    signal command_delay: unsigned(3 downto 0) := (others => '0');
    signal default_wait_state_8: unsigned(3 downto 0) := (others => '0');
    signal default_wait_state_16: unsigned(3 downto 0) := (others => '0');

    signal command_enable: std_logic := '0';

    signal d_ider0: std_logic_vector(7 downto 0);
    signal d_ider1: std_logic_vector(7 downto 0);

    signal ack8_ide: std_logic;
    signal ack8_ider0: std_logic;
    signal ack8_ider1: std_logic;
begin
    o_dior <= i_rd and command_enable;
    o_diow <= i_wr and command_enable;
    o_iocs16 <= (i_rd or i_wr) and (i_size(1) or not i_size(0)) and command_enable;

    o_ack8 <= ack8_ider0 or ack8_ider1 or ack8_ide;
    o_d <= d_ider0 or d_ider1;

    enable_controller <= ider_data(15);
    command_delay <= unsigned(ider_data(11 downto 8));
    default_wait_state_8 <= unsigned(ider_data(7 downto 4));
    default_wait_state_16 <= unsigned(ider_data(3 downto 0));

    ider0: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_ider and not i_a0,
            i_rd   => i_rd,
            i_wr   => i_wr,
            o_ack8 => ack8_ider0,
            i_d    => i_d,
            o_d    => d_ider0,
            o_reg  => ider_data(15 downto 8)
        );

    ider1: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_ider and i_a0,
            i_rd   => i_rd,
            i_wr   => i_wr,
            o_ack8 => ack8_ider1,
            i_d    => i_d,
            o_d    => d_ider1,
            o_reg  => ider_data(7 downto 0)
        );

    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            ack8_ide <= '0';
            o_ack16 <= '0';
            command_enable <= '0';
            o_bufen <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    command_enable <= '0';
                    ack8_ide <= '0';
                    o_ack16 <= '0';
                    o_bufen <= '0';

                    if (i_en_ide(0) or i_en_ide(1)) and (i_rd or i_wr) then
                        wait_count <= command_delay - 1;
                        state <= S_CMD;
                    end if;
                when S_CMD =>
                    if wait_count = 0 then
                        if i_size = "01" then  -- 8-bit cycle
                            wait_count <= default_wait_state_8 - 1;
                        else -- 16-bit cycle
                            wait_count <= default_wait_state_16 - 1;
                        end if;
                        command_enable <= '1';
                        o_bufdir <= i_rd; -- '1' when read, '0' when write
                        state <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if wait_count = 0 and i_iochrdy = '1' then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    command_enable <= '0';
                    if i_size = "01" then
                        ack8_ide <= '1';
                    else
                        o_ack16 <= '1';
                    end if;
                    o_bufen <= '1';

                    if not i_rd and not i_wr then
                        command_enable <= '0';
                        ack8_ide <= '0';
                        o_ack16 <= '0';
                        o_bufen <= '0';
                        state <= S_END;
                    end if;
                when S_END =>
                    state <= S_IDLE;
            end case;

            if wait_count /= 0 then
                wait_count <= wait_count - 1;
            end if;
        end if;
    end process;
end behavioral;
