library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity flash is
    port (
        A: in std_logic_vector(18 downto 0);
        DQ: out std_logic_vector(7 downto 0) := (others => 'Z');
        nCE: in std_logic
    );
end flash;

architecture behavioral of flash is
begin
    process
    begin
        loop
            wait until nCE = '0';
            while nCE = '0' loop
                wait for 70 ns;
                DQ <= A(7 downto 0);
                wait on A, nCE;
            end loop;
            wait for 25 ns;
            DQ <= (others => 'Z');
        end loop;
    end process;
end behavioral;
