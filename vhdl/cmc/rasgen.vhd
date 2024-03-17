library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rasgen is
    port (
        CLK: in std_logic;
        RST: in std_logic;

        BA: in std_logic_vector(2 downto 0);

        DUAL_BANK: in boolean;

        RASEN: in std_logic;
        ALLEN: in std_logic;
        RAS: out std_logic_vector(7 downto 0)
    );
end rasgen;

architecture behavioral of rasgen is
    signal RASTMP: std_logic_vector(7 downto 0) := (others => '1');
begin
    RAS <=
        RASTMP when RASEN = '1' else
        (others => '1') when ALLEN = '1' else
        (others => '0');

    process(CLK) is
    begin
        if rising_edge(CLK) then
            if RASEN = '1' then
                if DUAL_BANK then
                    case BA is
                        when "000" => RASTMP <= "00000001";
                        when "001" => RASTMP <= "00000010";
                        when "010" => RASTMP <= "00000100";
                        when "011" => RASTMP <= "00001000";
                        when "100" => RASTMP <= "00010000";
                        when "101" => RASTMP <= "00100000";
                        when "110" => RASTMP <= "01000000";
                        when "111" => RASTMP <= "10000000";
                        when others => RASTMP <= (others => '0');
                    end case;
                else
                    case BA is
                        when "000" => RASTMP <= "00000001";
                        when "001" => RASTMP <= "00000100";
                        when "010" => RASTMP <= "00010000";
                        when "011" => RASTMP <= "01000000";
                        when others => RASTMP <= (others => '0');
                    end case;
                end if;
            end if;
        end if;
    end process;
end behavioral;
