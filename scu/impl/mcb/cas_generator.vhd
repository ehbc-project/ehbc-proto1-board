library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.common.all;

entity cas_generator is
    port (
        i_size: in std_logic_vector(1 downto 0);
        i_a: in std_logic_vector(1 downto 0);

        i_strobe_mode: in strobe_mode_t;
        o_cas: out std_logic_vector(3 downto 0) := (others => '0')
    );
end cas_generator;

architecture dataflow of cas_generator is
    signal cas: std_logic_vector(3 downto 0) := (others => '0');
begin
    -- BYTE 0
    cas(0) <=
        (i_a(0) and i_a(1)) or
        (i_a(0) and i_size(0) and i_size(1)) or
        (not i_size(0) and not i_size(1)) or
        (i_a(1) and i_size(1));
    
    -- BYTE 1
    cas(1) <=
        (not i_a(0) and i_a(1)) or
        (not i_a(1) and not i_size(0) and not i_size(1)) or
        (not i_a(1) and i_size(0) and i_size(1)) or
        (not i_a(1) and i_a(0) and not i_size(0));
        
    -- BYTE 2
    cas(2) <=
        (i_a(0) and not i_a(1)) or
        (not i_a(1) and not i_size(0)) or
        (not i_a(1) and i_size(1));

    -- BYTE 3
    cas(3) <=
        (not i_a(0) and not i_a(1));

    o_cas <=
        cas when i_strobe_mode = SEM_SEL else
        (others => '1') when i_strobe_mode = SEM_ALL else
        (others => '0');
end dataflow;
