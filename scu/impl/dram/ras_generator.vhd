library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.common.all;

entity ras_generator is
    port (
        i_rst:          in std_logic;

        i_a:            in std_logic_vector(27 downto 20);
        
        i_abr0:         in std_logic_vector(7 downto 0);
        i_abr1:         in std_logic_vector(7 downto 0);
        i_abr2:         in std_logic_vector(7 downto 0);
        i_abr3:         in std_logic_vector(7 downto 0);
        i_abr4:         in std_logic_vector(7 downto 0);
        i_abr5:         in std_logic_vector(7 downto 0);
        i_abr6:         in std_logic_vector(7 downto 0);
        i_abr7:         in std_logic_vector(7 downto 0);

        i_ras_latch:    in std_logic;
        i_strobe_mode:  in strobe_mode_t;

        o_ras: out std_logic_vector(7 downto 0) := (others => '0');
        o_bank: out std_logic_vector(2 downto 0) := (others => '0')
    );
end ras_generator;

architecture dataflow of ras_generator is
    signal ras: std_logic_vector(7 downto 0) := (others => '0');
    signal ras_latched: std_logic_vector(7 downto 0) := (others => '0');

    signal temp0: boolean;
    signal temp1: boolean;
    signal temp2: boolean;
    signal temp3: boolean;
    signal temp4: boolean;
    signal temp5: boolean;
    signal temp6: boolean;
    signal temp7: boolean;
begin
    o_ras <=
        ras_latched when i_strobe_mode = SEM_SEL else
        (others => '1') when i_strobe_mode = SEM_ALL else
        (others => '0');
    process(i_ras_latch, i_rst)
    begin
        if i_rst = '1' then
        elsif rising_edge(i_ras_latch) then
            ras_latched <= ras;
        end if;
    end process;

    temp7 <= unsigned(i_a) < unsigned(i_abr7);
    ras(7) <= '1' when temp7 and not temp6 else '0';
    temp6 <= unsigned(i_a) < unsigned(i_abr6);
    ras(6) <= '1' when temp6 and not temp5 else '0';
    temp5 <= unsigned(i_a) < unsigned(i_abr5);
    ras(5) <= '1' when temp5 and not temp4 else '0';
    temp4 <= unsigned(i_a) < unsigned(i_abr4);
    ras(4) <= '1' when temp4 and not temp3 else '0';
    temp3 <= unsigned(i_a) < unsigned(i_abr3);
    ras(3) <= '1' when temp3 and not temp2 else '0';
    temp2 <= unsigned(i_a) < unsigned(i_abr2);
    ras(2) <= '1' when temp2 and not temp1 else '0';
    temp1 <= unsigned(i_a) < unsigned(i_abr1);
    ras(1) <= '1' when temp1 and not temp0 else '0';
    temp0 <= unsigned(i_a) < unsigned(i_abr0);
    ras(0) <= '1' when temp0 else '0';

    o_bank <=
        "000" when ras(0) else
        "001" when ras(1) else
        "010" when ras(2) else
        "011" when ras(3) else
        "100" when ras(4) else
        "101" when ras(5) else
        "110" when ras(6) else
        "111" when ras(7);
end dataflow;
