library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity mx8315 is
    port (
        nLOP: in std_logic;
        S: in std_logic_vector(2 downto 0);
        XCK: out std_logic;
        PCK: out std_logic;
        CK: out std_logic
    );
end mx8315;

architecture behavioral of mx8315 is
    signal internal_XCK: std_logic := '0';
    signal internal_PCK: std_logic := '0';
    signal internal_8M: std_logic := '0';
    signal internal_33M: std_logic := '0';
    signal internal_80M: std_logic := '0';
    signal internal_66M: std_logic := '0';
    signal internal_50M: std_logic := '0';
    signal internal_40M: std_logic := '0';
    signal internal_60M: std_logic := '0';
    signal internal_25M: std_logic := '0';
    signal internal_20M: std_logic := '0';
begin
    internal_8M <= not internal_8M after 62.5 ns;
    internal_33M <= not internal_33M after 15 ns;
    internal_80M <= not internal_80M after 6.25 ns;
    internal_66M <= not internal_66M after 7.5 ns;
    internal_50M <= not internal_50M after 10 ns;
    internal_40M <= not internal_40M after 12.5 ns;
    internal_60M <= not internal_60M after 8.33 ns;
    internal_25M <= not internal_25M after 20 ns;
    internal_20M <= not internal_20M after 25 ns;

    internal_PCK <= not internal_PCK after 20.83 ns;
    internal_XCK <= not internal_XCK after 69.84 ns;

    CK <= internal_8M when nLOP = '0' else
        internal_33M when S = "000" else
        internal_80M when S = "001" else
        internal_66M when S = "010" else
        internal_50M when S = "011" else
        internal_40M when S = "100" else
        internal_60M when S = "101" else
        internal_25M when S = "110" else
        internal_20M;
    PCK <= internal_PCK;
    XCK <= internal_XCK;
end behavioral;
