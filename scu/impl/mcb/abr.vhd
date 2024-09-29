library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity abr is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_en: in std_logic;
        i_rd: in std_logic;
        i_wr: in std_logic;
        i_a: in std_logic_vector(2 downto 0);
        o_ack8: out std_logic;

        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        
        o_abr0: out unsigned(7 downto 0);
        o_abr1: out unsigned(7 downto 0);
        o_abr2: out unsigned(7 downto 0);
        o_abr3: out unsigned(7 downto 0);
        o_abr4: out unsigned(7 downto 0);
        o_abr5: out unsigned(7 downto 0);
        o_abr6: out unsigned(7 downto 0);
        o_abr7: out unsigned(7 downto 0)
    );
end abr;

architecture behavioral of abr is
    type reg_t is array(0 to 7) of std_logic_vector(7 downto 0);
    signal data: reg_t := (others => (others => '0'));

    signal xferend: boolean := false;
begin
    o_abr0 <= unsigned(data(0));
    o_abr1 <= unsigned(data(1));
    o_abr2 <= unsigned(data(2));
    o_abr3 <= unsigned(data(3));
    o_abr4 <= unsigned(data(4));
    o_abr5 <= unsigned(data(5));
    o_abr6 <= unsigned(data(6));
    o_abr7 <= unsigned(data(7));

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            data <= (others => (others => '0'));
            xferend <= false;
        elsif rising_edge(i_clk) then
            if i_en = '1' and not xferend then
                if i_rd = '1' then
                    o_d <= data(to_integer(unsigned(i_a)));
                end if;
            
                if i_wr = '1' then
                    data(to_integer(unsigned(i_a))) <= i_d;
                end if;

                if i_rd or i_wr then
                    o_ack8 <= '1';
                else
                    o_d <= (others => '0');
                    o_ack8 <= '0';
                    xferend <= true;
                end if;
            else
                o_d <= (others => '0');
                o_ack8 <= '0';
                xferend <= false;
            end if;
        end if;
    end process;
end behavioral;
