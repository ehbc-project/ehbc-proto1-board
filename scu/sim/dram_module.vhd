library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity dram_module is
    port (
        A: in std_logic_vector(11 downto 0);
        DQ: inout std_logic_vector(31 downto 0) := (others => 'Z');
        nCAS: in std_logic_vector(3 downto 0);
        nRAS: in std_logic_vector(3 downto 0);
        nWE: in std_logic
    );
end dram_module;

architecture structural of dram_module is
begin
    dram0: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(7 downto 0),
            nCAS => nCAS(0),
            nRAS => nRAS(0),
            nWE  => nWE
        );
    dram1: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(15 downto 8),
            nCAS => nCAS(1),
            nRAS => nRAS(0),
            nWE  => nWE
        );
    dram2: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(23 downto 16),
            nCAS => nCAS(2),
            nRAS => nRAS(2),
            nWE  => nWE
        );
    dram3: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(31 downto 24),
            nCAS => nCAS(3),
            nRAS => nRAS(2),
            nWE  => nWE
        );
    dram4: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(7 downto 0),
            nCAS => nCAS(0),
            nRAS => nRAS(1),
            nWE  => nWE
        );
    dram5: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(15 downto 8),
            nCAS => nCAS(1),
            nRAS => nRAS(1),
            nWE  => nWE
        );
    dram6: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(23 downto 16),
            nCAS => nCAS(2),
            nRAS => nRAS(3),
            nWE  => nWE
        );
    dram7: entity work.dram
        port map (
            A    => A,
            DQ   => DQ(31 downto 24),
            nCAS => nCAS(3),
            nRAS => nRAS(3),
            nWE  => nWE
        );
end structural;
