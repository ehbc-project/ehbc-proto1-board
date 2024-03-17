library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bootvector is
    generic (
        INITIAL_SP: unsigned(31 downto 0);
        INITIAL_PC: unsigned(31 downto 0)
    );
    port (
        CLK: in std_logic;
        RST: in std_logic;

        AS: in std_logic;
        DS: in std_logic;
        R_nW: in std_logic;
        SIZE: in std_logic_vector(1 downto 0);
        DSACK: out std_logic_vector(1 downto 0) := "00";

        A: in std_logic_vector(31 downto 0);
        D: inout std_logic_vector(7 downto 0) := (others => 'Z');

        BOOT: out std_logic := '1'
    );
end bootvector;

architecture behavioral of bootvector is
    signal BOOT_TMP: std_logic := '1';
begin
    process(CLK, RST) is
    begin
        if RST = '1' then
            BOOT_TMP <= '1';
            BOOT <= '1';
        elsif rising_edge(CLK) then
            if AS = '1' and DS = '1' and R_nW = '1' then
                if BOOT_TMP = '1' then
                    case A is
                        when x"00000000" =>
                            D <= std_logic_vector(INITIAL_SP(31 downto 24));
                        when x"00000001" =>
                            D <= std_logic_vector(INITIAL_SP(23 downto 16));
                        when x"00000002" =>
                            D <= std_logic_vector(INITIAL_SP(15 downto 8));
                        when x"00000003" =>
                            D <= std_logic_vector(INITIAL_SP(7 downto 0));
                        when x"00000004" =>
                            D <= std_logic_vector(INITIAL_PC(31 downto 24));
                        when x"00000005" =>
                            D <= std_logic_vector(INITIAL_PC(23 downto 16));
                        when x"00000006" =>
                            D <= std_logic_vector(INITIAL_PC(15 downto 8));
                        when x"00000007" =>
                            D <= std_logic_vector(INITIAL_PC(7 downto 0));
                            BOOT_TMP <= '0';
                        when others =>
                            D <= (others => 'Z');
                    end case;

                    DSACK <= "01";
                end if;
            else
                if BOOT_TMP = '0' then
                    BOOT <= '0';
                end if;
                D <= (others => 'Z');
                DSACK <= "00";
            end if;
        end if;
    end process;
end behavioral;
