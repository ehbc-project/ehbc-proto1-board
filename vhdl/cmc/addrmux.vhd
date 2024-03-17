library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addrmux is
    port (
        CLK: in std_logic;
        
        A: in std_logic_vector(26 downto 2);
        RA: out std_logic_vector(11 downto 0) := x"000";
        CA: out std_logic_vector(11 downto 0) := x"000";
        BA: out std_logic_vector(2 downto 0) := "000";

        MUX_SCHEME: in unsigned(2 downto 0);
        BANK_SIZE: in unsigned(2 downto 0)
    );
end addrmux;

-- Address Multiplexing Schemes
-- MUX_SCHEME = 0:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A21  A23  A25
-- RAS  A11  A12  A13  A14  A15  A16  A17  A18  A19  A20  A22  A24
-- MUX_SCHEME = 1:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11  A23  A25
-- RAS  A12  A13  A14  A15  A16  A17  A18  A19  A20  A21  A22  A24
-- MUX_SCHEME = 2:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11  A12  A25
-- RAS  A13  A14  A15  A16  A17  A18  A19  A20  A21  A22  A23  A24
-- MUX_SCHEME = 3: Reserved
-- MUX_SCHEME = 4:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9
-- RAS  A10  A11  A12  A13  A14  A15  A16  A17  A18  A19  A20  A21
-- MUX_SCHEME = 5:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10
-- RAS  A11  A12  A13  A14  A15  A16  A17  A18  A19  A20  A21  A22
-- MUX_SCHEME = 6:
--      MA0  MA1  MA2  MA3  MA4  MA5  MA6  MA7  MA8  MA9 MA10 MA11
-- CAS   A2   A3   A4   A5   A6   A7   A8   A9  A10  A11
-- RAS  A12  A13  A14  A15  A16  A17  A18  A19  A20  A21  A22  A23
-- MUX_SCHEME = 7: Reserved

architecture dataflow of addrmux is
begin
    CA(11 downto 0) <=
        A(25) & A(23) & A(21) & A(10 downto 2)  when MUX_SCHEME = 0 else
        A(25) & A(23) & A(11 downto 2)          when MUX_SCHEME = 1 else
        A(25) & A(12 downto 2)                  when MUX_SCHEME = 2 else 
        "0000" & A(9 downto 2)                  when MUX_SCHEME = 4 else
        "000" & A(10 downto 2)                  when MUX_SCHEME = 5 else
        "00" & A(11 downto 2)                   when MUX_SCHEME = 6 else
        (others => '0');
    
    RA(11 downto 0) <=
        A(24) & A(22) & A(20 downto 11)         when MUX_SCHEME = 0 else
        A(24) & A(22) & A(21 downto 12)         when MUX_SCHEME = 1 else
        A(24 downto 13)                         when MUX_SCHEME = 2 else
        A(21 downto 10)                         when MUX_SCHEME = 4 else
        A(22 downto 11)                         when MUX_SCHEME = 5 else
        A(23 downto 12)                         when MUX_SCHEME = 6 else
        (others => '0');

    BA(2 downto 0) <=
        A(20 downto 18) when BANK_SIZE = 0 else
        A(21 downto 19) when BANK_SIZE = 1 else
        A(22 downto 20) when BANK_SIZE = 2 else
        A(23 downto 21) when BANK_SIZE = 3 else
        A(24 downto 22) when BANK_SIZE = 4 else
        A(25 downto 23) when BANK_SIZE = 5 else
        A(26 downto 24) when BANK_SIZE = 6 else
        (others => '0');
end dataflow;
