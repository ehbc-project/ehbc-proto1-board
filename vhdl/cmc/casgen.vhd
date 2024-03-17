library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity casgen is
    port (
        SIZE: in std_logic_vector(1 downto 0);
        A: in std_logic_vector(1 downto 0);
        R_nW: in std_logic;

        CASEN: in std_logic;
        ALLEN: in std_logic;
        CAS: out std_logic_vector(3 downto 0)
    );
end casgen;

architecture dataflow of casgen is
begin
    -- BYTE 0
    CAS(0) <= '1' when ALLEN = '1' else
        CASEN and 
        (R_nW or
        (A(0) and A(1)) or
        (A(0) and SIZE(0) and SIZE(1)) or
        (not SIZE(0) and not SIZE(1)) or
        (A(1) and SIZE(1)));
    
    -- BYTE 1
    CAS(1) <= '1' when ALLEN = '1' else
        CASEN and
        (R_nW or
        (not A(0) and A(1)) or
        (not A(1) and not SIZE(0) and not SIZE(1)) or
        (not A(1) and SIZE(0) and SIZE(1)) or
        (not A(1) and A(0) and not SIZE(0)));
        
    -- BYTE 2
    CAS(2) <= '1' when ALLEN = '1' else
        CASEN and
        (R_nW or
        (A(0) and not A(1)) or
        (not A(1) and not SIZE(0)) or
        (not A(1) and SIZE(1)));

    -- BYTE 3
    CAS(3) <= '1' when ALLEN = '1' else
        CASEN and
        (R_nW or
        (not A(0) and not A(1)));
end dataflow;
