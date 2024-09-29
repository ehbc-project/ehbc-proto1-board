library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity hpt_channel is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_enable: in std_logic;
        i_pause: in std_logic;
        
        o_tick: out std_logic;

        i_data: in unsigned(15 downto 0)
    );
end hpt_channel;

architecture behavioral of hpt_channel is
    type state_t is (S_IDLE, S_COUNT, S_END);
    signal state: state_t := S_IDLE;
    signal counter: unsigned(15 downto 0) := (others => '0');
begin
    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            counter <= (others => '0');
            o_tick <= '0';
        elsif rising_edge(i_clk) then
            if i_enable then
                case state is
                    when S_IDLE =>
                        counter <= i_data;
                        if i_enable then
                            state <= S_COUNT;
                        end if;
                    when S_COUNT =>
                        if counter = 0 then
                            state <= S_END;
                        elsif not i_pause then
                            counter <= counter - 1;
                        end if;
                    when S_END =>
                        state <= S_IDLE;
                end case;
            else
                state <= S_IDLE;
            end if;
        end if;
    end process;
end behavioral;
