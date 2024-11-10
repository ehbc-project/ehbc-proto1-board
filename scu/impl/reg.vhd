library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity reg is
    generic (
        reset_value:  std_logic_vector(7 downto 0) := (others => '0')
    );
    port (
        i_clk:          in std_logic;
        i_rst:          in std_logic;
        i_select:       in std_logic;

        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_di:           in std_logic_vector(7 downto 0);
        o_do:           out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';

        o_reg:          out std_logic_vector(7 downto 0)
    );
end reg;

architecture behavioral of reg is
    type state_t is (S_IDLE, S_XFER, S_END);
    signal state: state_t := S_IDLE;

    signal data: std_logic_vector(7 downto 0) := reset_value;
begin
    o_reg <= data;

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            data <= reset_value;
            o_do <= (others => '0');
            o_ack8 <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    o_do <= (others => '0');
                    o_ack8 <= '0';
                    if i_select and (i_rd or i_wr) then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    if i_rd = '1' then
                        o_do <= data;
                    end if;
                    if i_wr = '1' then
                        data <= i_di;
                    end if;
                    o_ack8 <= '1';
                    state <= S_END;
                when S_END =>
                    if not (i_rd or i_wr) then
                        o_do <= (others => '0');
                        o_ack8 <= '0';
                        state <= S_IDLE;
                    end if;
            end case;
        end if;
    end process;
end behavioral;
