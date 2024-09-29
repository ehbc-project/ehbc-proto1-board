library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity reg is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_en: in std_logic;
        i_rd: in std_logic;
        i_wr: in std_logic;
        o_ack8: out std_logic;

        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        
        o_reg: out std_logic_vector(7 downto 0)
    );
end reg;

architecture behavioral of reg is
    signal data: std_logic_vector(7 downto 0) := (others => '0');

    signal xferend: boolean := false;
begin
    o_reg <= data;

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            data <= (others => '0');
            xferend <= false;
        elsif rising_edge(i_clk) then
            if i_en = '1' and not xferend then
                if i_rd = '1' then
                    o_d <= data;
                end if;
            
                if i_wr = '1' then
                    data <= i_d;
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
