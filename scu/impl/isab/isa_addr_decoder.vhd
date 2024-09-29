library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity isa_addr_decoder is
    port (
        i_a: in std_logic_vector(23 downto 16);

        o_io: out std_logic := '0';
        o_mem: out std_logic := '0';
        o_smem: out std_logic := '0'
    );
end isa_addr_decoder;

architecture dataflow of isa_addr_decoder is
begin
    o_io <= '1' when i_a(23 downto 16) = x"00" else '0';
    o_mem <= '1' when i_a(23 downto 20) = x"0" else '0';
    o_smem <= '1' when i_a(23 downto 20) /= x"0" else '0';
end dataflow;
