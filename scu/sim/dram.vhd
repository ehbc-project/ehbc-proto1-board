library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity dram is
    port (
        A: in std_logic_vector(11 downto 0);
        DQ: inout std_logic_vector(7 downto 0) := (others => 'Z');
        nCAS: in std_logic;
        nRAS: in std_logic;
        nWE: in std_logic
    );
end dram;

architecture behavioral of dram is
    signal RA: std_logic_vector(11 downto 0);
    signal CA: std_logic_vector(11 downto 0);
begin
    process
    begin
        wait until nRAS = '0';
        if nCAS = '0' then
            wait for 12000 ns;
        else
            RA <= A;
        end if;
        wait until nRAS = '1';
    end process;

    process
    begin
        wait until nCAS = '0';
        CA <= A;

        wait for 15 ns;
        if nWE = '1' then
            DQ <= CA(7 downto 0);
        end if;

        wait until nCAS = '1';
        wait for 15 ns;
        if nWE = '1' then
            DQ <= (others => 'Z');
        end if;
    end process;
end behavioral;
