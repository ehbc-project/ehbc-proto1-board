library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity fmcb is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_en_flash: in std_logic;
        i_en_fcr: in std_logic;

        i_rd: in std_logic;
        i_wr: in std_logic;
        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        
        o_ack8: out std_logic := '0';
        o_ack16: out std_logic := '0'
    );
end fmcb;

architecture behavioral of fmcb is
    type state_t is (S_IDLE, S_WAIT, S_XFER, S_END);
    signal wait_count: unsigned(2 downto 0) := "000";
    signal state: state_t := S_IDLE;

    signal fcr_data: std_logic_vector(7 downto 0);
    signal latency: unsigned(2 downto 0) := "000";
begin
    latency <= unsigned(fcr_data(2 downto 0));

    fcr: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_fcr,
            i_rd   => i_rd,
            i_wr   => i_wr,
            o_ack8 => o_ack8,
            i_d    => i_d,
            o_d    => o_d,
            o_reg  => fcr_data
        );

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            o_ack16 <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    o_ack16 <= '0';
                    if i_en_flash and (i_rd or i_wr) then
                        wait_count <= latency - 1;
                        state <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if wait_count = 0 then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    o_ack16 <= '1';
                    if not i_rd and not i_wr then
                        o_ack16 <= '0';
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
