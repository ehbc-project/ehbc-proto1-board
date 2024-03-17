library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rfshcntr is
    port (
        CLK: in std_logic;
        RFSHCLK: in std_logic;
        RST: in std_logic;

        REFRESH_CYCLE: in unsigned(14 downto 0);

        RFSHREQ: out std_logic := '0'
    );
end rfshcntr;

architecture behavioral of rfshcntr is
    signal refresh_counter: unsigned(14 downto 0) := (others => '0');
begin
    process(RST, CLK, RFSHCLK) is
    begin
        if RST = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(RFSHCLK) then
            if refresh_counter /= 0 then
                RFSHREQ <= '0';
                refresh_counter <= refresh_counter - 1;
            elsif REFRESH_CYCLE /= 0 then
                RFSHREQ <= '1';
                refresh_counter <= REFRESH_CYCLE;
            end if;
        end if;
    end process;
end behavioral;
