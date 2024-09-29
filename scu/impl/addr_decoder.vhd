library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity addr_decoder is
    port (
        i_fc: in std_logic_vector(2 downto 0);
        i_a: in std_logic_vector(31 downto 0);
        i_as: in std_logic;

        i_boot: in std_logic;
        
        o_cbok: out std_logic;
        o_ci: out std_logic;

        o_en_ccr: out std_logic;
        o_en_dcr: out std_logic;
        o_en_fcr: out std_logic;
        o_en_pcr: out std_logic;
        o_en_abr: out std_logic;
        o_en_ider: out std_logic;
        o_en_isar: out std_logic;
        o_en_picr: out std_logic;

        o_en_ram: out std_logic;
        o_en_flash: out std_logic;
        o_en_isa: out std_logic;

        o_en_ide: out std_logic_vector(1 downto 0);
        o_en_i8042: out std_logic;
        o_en_fdc: out std_logic;
        o_en_rtc: out std_logic;

        o_en_mfp0: out std_logic;
        o_en_mfp1: out std_logic;
        o_en_duart: out std_logic;
        o_en_dmac0: out std_logic;
        o_en_dmac1: out std_logic
    );
end addr_decoder;

architecture dataflow of addr_decoder is
    signal asp_valid: boolean;
    signal isa_region: boolean;
    signal mmio_region: boolean;
    signal register_sel: boolean;
    signal ioport: boolean;

    signal en_ram: std_logic;
    signal en_i8042: std_logic;
    signal en_rtc: std_logic;
    signal en_ide: std_logic_vector(1 downto 0);
    signal en_fdc: std_logic;
begin
    asp_valid <= i_fc /= FC_CPUSPACE and i_as = '1';

    o_ci <= '1' when asp_valid and i_a(31 downto 26) = x"F" & "11" else '0';

    en_ram <= '1' when asp_valid and i_a(31 downto 26) /= x"F" & "11" and i_boot = '0' else '0';
    o_en_ram <= en_ram;
    o_cbok <= en_ram;

    o_en_flash <= '1' when asp_valid and i_a(31 downto 24) = x"FD" else '0';

    isa_region <= asp_valid and i_a(31 downto 24) = x"FE";

    ioport  <= isa_region and i_a(23 downto 10) = x"000" & "00";
    en_i8042 <= '1' when ioport and i_a(11 downto 4) = x"06" else '0';
    o_en_i8042 <= en_i8042;
    en_rtc <= '1' when ioport and i_a(11 downto 4) = x"07" else '0';
    o_en_rtc <= en_rtc;
    en_ide(0) <= '1' when ioport and i_a(11 downto 4) = x"1F" else '0';
    en_ide(1) <= '1' when ioport and i_a(11 downto 0) = x"3F6" else '0';
    o_en_ide <= en_ide;
    en_fdc <= '1' when ioport and i_a(11 downto 4) = x"3F" and i_a(3 downto 0) /= x"6" else '0';
    o_en_fdc <= en_fdc;
    o_en_isa <= '1' when (en_i8042 or en_rtc or en_ide(0) or en_ide(1) or en_fdc) = '0' and isa_region else '0';

    mmio_region <= asp_valid and i_a(31 downto 24) = x"FF";
    register_sel <= mmio_region and i_a(23 downto 8) = x"0000";
    o_en_mfp0  <= '1' when mmio_region and i_a(23 downto 4) = x"00010" else '0';
    o_en_mfp1 <= '1' when mmio_region and i_a(23 downto 4) = x"00011" else '0';
    o_en_duart <= '1' when mmio_region and i_a(23 downto 8) = x"0002" else '0';
    o_en_dmac0 <= '1' when mmio_region and i_a(23 downto 8) = x"0003" else '0';
    o_en_dmac1 <= '1' when mmio_region and i_a(23 downto 8) = x"0004" else '0';

    o_en_ccr <= '1' when register_sel and i_a(7 downto 0) = x"00" else '0';
    o_en_dcr <= '1' when register_sel and i_a(7 downto 0) = x"01" else '0';
    o_en_fcr <= '1' when register_sel and i_a(7 downto 0) = x"02" else '0';
    o_en_pcr <= '1' when register_sel and i_a(7 downto 0) = x"03" else '0';
    o_en_ider <= '1' when register_sel and i_a(7 downto 1) = "0000010" else '0';
    o_en_isar <= '1' when register_sel and i_a(7 downto 0) = x"06" else '0';
    o_en_abr <= '1' when register_sel and i_a(7 downto 3) = "00001" else '0';
    o_en_picr <= '0';
end dataflow;
