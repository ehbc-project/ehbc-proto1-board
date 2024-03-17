library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cacc is
    port (
        CLK: in std_logic;
        RST: in std_logic;

        RAMCS: in std_logic;

        DS: in std_logic;
        R_nW: in std_logic;
        SIZE: in std_logic_vector(1 downto 0);

        STERM: out std_logic := 'Z';

        A: in std_logic_vector(31 downto 0);
        
        TD: inout std_logic_vector(15 downto 0) := (others => 'Z');
        CBE: out std_logic_vector(3 downto 0) := "0000";
        TOE: out std_logic := '0';
        CTWE: out std_logic := '0'
    );
end cacc;

architecture behavioral of cacc is
begin
    process(CLK) is
    begin
        if rising_edge(CLK) then

        end if;
    end process;
end behavioral;
