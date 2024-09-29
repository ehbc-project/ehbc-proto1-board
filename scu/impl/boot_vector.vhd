library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity boot_vector is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_rd: in std_logic;

        i_a: in std_logic_vector(2 downto 0);
        o_d: out std_logic_vector(7 downto 0);

        o_ack8: out std_logic := '0';
        i_boot: in std_logic
    );
end boot_vector;

architecture behavioral of boot_vector is
begin
    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
        elsif rising_edge(i_clk) then
            if i_rd = '1' then
                if i_boot then
                    case i_a is
                        when "000" =>
                            o_d <= INITVEC_SP(31 downto 24);
                        when "001" =>
                            o_d <= INITVEC_SP(23 downto 16);
                        when "010" =>
                            o_d <= INITVEC_SP(15 downto 8);
                        when "011" =>
                            o_d <= INITVEC_SP(7 downto 0);
                        when "100" =>
                            o_d <= INITVEC_PC(31 downto 24);
                        when "101" =>
                            o_d <= INITVEC_PC(23 downto 16);
                        when "110" =>
                            o_d <= INITVEC_PC(15 downto 8);
                        when "111" =>
                            o_d <= INITVEC_PC(7 downto 0);
                        when others =>
                    end case;
                    o_ack8 <= '1';
                end if;
            else
                o_ack8 <= '0';
            end if;
        end if;
    end process;
end behavioral;
