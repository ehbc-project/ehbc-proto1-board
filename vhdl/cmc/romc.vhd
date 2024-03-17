library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity romc is
    port (
        CLK: in std_logic;
        ROMCS: in std_logic;
        R_nW: in std_logic;
        DS: in std_logic;
        DSACK: out std_logic_vector(1 downto 0) := "00";
        ROM_LATENCY: in unsigned(2 downto 0)
    );
end romc;

architecture behavioral of romc is
    signal delay_counter: unsigned(2 downto 0) := "000";
    signal delay_counter_valid: boolean := false;
begin
    process(CLK) is
    begin
        if rising_edge(CLK) then
            if ROMCS = '1' and DS = '1' and R_nW = '1' then
                if delay_counter_valid and delay_counter = "000" then
                    DSACK <= "10";
                    delay_counter_valid <= false;
                else
                    delay_counter_valid <= true;
                    delay_counter <= ROM_LATENCY;
                end if;
            else
                DSACK <= "00";
            end if;

            if delay_counter /= 0 then
                delay_counter <= delay_counter - 1;
            end if;
        end if;
    end process;
end behavioral;
