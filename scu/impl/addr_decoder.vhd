library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity addr_decoder is
    port (
        -- Internal Bus Signals
        i_nas:              in std_logic;
        i_fc:               in std_logic_vector(2 downto 0);
        i_a:                in std_logic_vector(31 downto 0);

        -- Selector Signals
        o_sel_coproc:       out std_logic := '0';
        o_sel_iack:         out std_logic := '0';

        o_sel_dram:         out std_logic := '0';
        o_sel_flash:        out std_logic := '0';
        o_sel_isa:          out std_logic := '0';
        o_sel_ireg:         out std_logic := '0';
        o_sel_mfp0:         out std_logic := '0';
        o_sel_mfp1:         out std_logic := '0';
        o_sel_dmac0:        out std_logic := '0';
        o_sel_dmac1:        out std_logic := '0';

        o_sel_ccr:          out std_logic := '0';
        o_sel_pcr:          out std_logic := '0';
        o_sel_isar:         out std_logic := '0';
        o_sel_fcr:          out std_logic := '0';
        o_sel_abr:          out std_logic := '0';
        o_sel_dcr:          out std_logic := '0';
        o_sel_tcr:          out std_logic := '0';
        o_sel_icr:          out std_logic := '0';

        -- Register Values
        i_remap_flash:    in boolean
    );
end addr_decoder;

architecture dataflow of addr_decoder is
    signal asp_noncpuspace: boolean;
    signal asp_supervisor: boolean;
    signal asp_cpuspace: boolean;

    signal mmio_region: boolean;

    signal register_select: boolean;

    signal remapped_flash_select: boolean;
begin
    asp_cpuspace <= i_nas = '0' and i_fc = FC_CPUSPACE;

    o_sel_coproc <= '1' when asp_cpuspace and i_a(19 downto 16) = "0010" else '0';
    o_sel_iack <= '1' when asp_cpuspace and i_a(19 downto 16) = "1111" else '0';

    asp_noncpuspace <= i_nas = '0' and i_fc /= FC_CPUSPACE;
    asp_supervisor <= i_nas = '0' and (i_fc = FC_SUPERDATA or i_fc = FC_SUPERPROG);

    remapped_flash_select <= i_remap_flash and asp_noncpuspace and i_a(31 downto 24) = x"00";

    o_sel_dram <= '1' when not remapped_flash_select and asp_noncpuspace and i_a(31 downto 26) /= "111111" else '0';
    o_sel_flash <= '1' when remapped_flash_select or (asp_supervisor and i_a(31 downto 24) = x"FD") else '0';
    o_sel_isa <= '1' when asp_supervisor and i_a(31 downto 24) = x"FE" else '0';

    mmio_region <= asp_supervisor and i_a(31 downto 24) = x"FF";
    register_select <= mmio_region and i_a(23 downto 8) = x"0000";
    o_sel_ccr <= '1' when register_select and i_a(7 downto 0) = x"00" else '0';
    o_sel_pcr <= '1' when register_select and i_a(7 downto 0) = x"01" else '0';
    o_sel_isar <= '1' when register_select and i_a(7 downto 0) = x"02" else '0';
    o_sel_fcr <= '1' when register_select and i_a(7 downto 0) = x"03" else '0';
    o_sel_abr <= '1' when register_select and i_a(7 downto 3) = "00001" else '0';
    o_sel_dcr <= '1' when register_select and i_a(7 downto 0) = x"07" else '0';
    o_sel_tcr <= '1' when register_select and i_a(7 downto 4) = x"1" else '0';
    o_sel_icr <= '1' when register_select and i_a(7 downto 4) = x"2" else '0';

    o_sel_mfp0  <= '1' when mmio_region and i_a(23 downto 4) = x"00010" else '0';
    o_sel_mfp1 <= '1' when mmio_region and i_a(23 downto 4) = x"00011" else '0';
    o_sel_dmac0 <= '1' when mmio_region and i_a(23 downto 8) = x"0002" else '0';
    o_sel_dmac1 <= '1' when mmio_region and i_a(23 downto 8) = x"0003" else '0';
end dataflow;
