library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addr_mux is
    port (
        i_a: in std_logic_vector(25 downto 2);

        o_ra: out std_logic_vector(11 downto 0) := x"000";
        o_ca: out std_logic_vector(11 downto 0) := x"000";

        i_mapping_mode: in std_logic_vector(2 downto 0)
    );
end addr_mux;

-- Address Mapping Modes
-- mapping_mode  = 0:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A21  A23  A25
-- RAS  A13  A12  A14  A15  A16  A17  A18  A19  A11  A20  A22  A24
-- mapping_mode  = 1:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11  A23  A25
-- RAS  A13  A12  A14  A15  A16  A17  A18  A19  A20  A21  A22  A24
-- mapping_mode  = 2:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11  A12  A25
-- RAS  A13  A22  A14  A15  A16  A17  A18  A19  A20  A21  A23  A24
-- mapping_mode  = 3: Reserved
-- mapping_mode  = 4:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9 *A10 *A11 *A23 *A25
-- RAS  A13  A12  A14  A15  A16  A17  A18  A19  A20  A21  A10  A11
-- mapping_mode  = 5:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10 *A11 *A23 *A25
-- RAS  A13  A12  A14  A15  A16  A17  A18  A19  A20  A21  A12  A11
-- mapping_mode  = 6:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11 *A23 *A25
-- RAS  A13  A12  A14  A15  A16  A17  A18  A19  A20  A21  A22  A23
-- mapping_mode  = 7: Reserved
-- *: should not be used, but mapped for optimizing chip design

architecture dataflow of addr_mux is
begin
    o_ca(8 downto 0) <= i_a(10 downto 2);
    o_ca(9) <= i_a(21) when i_mapping_mode = "000" else i_a(11);
    o_ca(10) <= i_a(12) when i_mapping_mode = "010" else i_a(23);
    o_ca(11) <= i_a(25);

    o_ra(0) <= i_a(13);
    o_ra(1) <= i_a(22) when i_mapping_mode = "010" else i_a(12);
    o_ra(7 downto 2) <= i_a(19 downto 14);
    o_ra(8) <= i_a(11) when i_mapping_mode = "000" else i_a(20);
    o_ra(9) <= i_a(20) when i_mapping_mode = "000" else i_a(21);
    o_ra(10) <=
        i_a(23) when i_mapping_mode = "010" else
        i_a(10) when i_mapping_mode = "100" else
        i_a(12) when i_mapping_mode = "101" else
        i_a(22);
    o_ra(11) <=
        i_a(24) when i_mapping_mode(2) = '0' else
        i_a(23) when i_mapping_mode(1 downto 0) = "00" else
        i_a(11);
end dataflow;
