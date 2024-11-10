use std.textio.all;
use std.env.finish;

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity testbench is
    port (
        o_clk: out std_logic;
        i_nrst: in std_logic;

        -- Processor Interface Signals
        i_nas: in std_logic;
        i_nds: in std_logic;
        i_r_nw: in std_logic;
        i_size: in std_logic_vector(1 downto 0);
        o_ndsack: out std_logic_vector(1 downto 0) := (others => 'Z');
        o_nsterm: out std_logic := 'Z';
        i_fc: in std_logic_vector(2 downto 0);
        i_a: in std_logic_vector(31 downto 0);
        io_d: inout std_logic_vector(31 downto 0) := (others => 'Z');
        i_ncbreq: in std_logic;
        o_ncback: out std_logic;
        o_nci: out std_logic;

        -- Interrupt Controller Signals
        o_nipl: out std_logic_vector(2 downto 0);
        o_nberr: out std_logic
    );
end testbench;

architecture test of testbench is
    signal clk: std_logic := '0';
    signal isaclk: std_logic := '0';
    signal nen_flash: std_logic;
    signal ma: std_logic_vector(11 downto 0) := (others => '0');
    signal ncas: std_logic_vector(3 downto 0) := (others => '1');
    signal nras: std_logic_vector(7 downto 0) := (others => '1');
    signal nwe: std_logic;
    signal nrefresh: std_logic := '1';
    signal nnows: std_logic := '1';
    signal iochrdy_isa: std_logic := '1';
    signal iochck: std_logic := '0';
    signal iochrdy_ide: std_logic := '1';
    signal irq: std_logic_vector(19 downto 0) := (others => '0');
    signal npclk8m: std_logic;
    signal pclksel: std_logic_vector(2 downto 0);
    signal npsw: std_logic := '1';
begin
    o_clk <= clk;

    isaclk <= not isaclk after 62.5 ns;  -- 8 MHz
    nrefresh <= not nrefresh after 1 ms;

    mx8315: entity work.mx8315
        port map (
            nLOP => npclk8m,
            S    => pclksel,
            CK   => clk
        );

    top: entity work.top
        port map (
            i_clk         => clk,
            i_isaclk      => isaclk,
            i_nrst        => i_nrst,

            o_nen_flash     => nen_flash,
--          o_nen_mfp0    => o_nen_mfp0,
--          o_nen_mfp1    => o_nen_mfp1,
--          o_nen_dmac0   => o_nen_dmac0,
--          o_nen_dmac1   => o_nen_dmac1,

            i_nas         => i_nas,
            i_nds         => i_nds,
            i_r_nw        => i_r_nw,
            i_size        => i_size,
            o_ndsack      => o_ndsack,
            o_nsterm      => o_nsterm,
            i_fc          => i_fc,
            i_a           => i_a,
            io_d          => io_d(31 downto 24),
            i_ncbreq      => i_ncbreq,
            o_ncback      => o_ncback,
            o_nci         => o_nci,
            o_nberr       => o_nberr,

            o_ma          => ma,
            o_ncas        => ncas,
            o_nras        => nras,
            o_nwe         => nwe,
            i_nrefresh    => nrefresh,
--          o_npagehit    => o_npagehit,

            i_nnows       => nnows,
            i_iochrdy     => iochrdy_isa,
            i_iochck      => iochck,
--          o_ale         => o_ale,
--          o_sbhe        => o_sbhe,
--          o_nsmemr      => o_nsmemr,
--          o_nsmemw      => o_nsmemw,
--          o_nmemr       => o_nmemr,
--          o_nmemw       => o_nmemw,
--          o_nior        => o_nior,
--          o_niow        => o_niow,
--          o_nmemcs16    => o_nmemcs16,
--          o_niocs16     => o_niocs16,
--          o_nbufen      => o_nbufen,
--          o_bufdir      => o_bufdir,
            o_nipl        => o_nipl,
            i_irq         => irq,

            o_npclk8m     => npclk8m,
            o_pclksel     => pclksel,
            i_npsw        => npsw
--          o_npwroff     => o_npwroff,

--          o_nboot       => o_nboot,
--          o_nrd         => o_nrd,
--          o_nwr         => o_nwr
        );

    simm0: entity work.dram_module
        port map (
            A => ma,
            DQ => io_d,
            nCAS => ncas,
            nRAS => nras(0) & nras(1) & nras(0) & nras(1),
            nWE => nwe
        );

    simm1: entity work.dram_module
        port map (
            A => ma,
            DQ => io_d,
            nCAS => ncas,
            nRAS => nras(2) & nras(3) & nras(2) & nras(3),
            nWE => nwe
        );

    simm2: entity work.dram_module
        port map (
            A => ma,
            DQ => io_d,
            nCAS => ncas,
            nRAS => nras(4) & nras(5) & nras(4) & nras(5),
            nWE => nwe
        );

    simm3: entity work.dram_module
        port map (
            A => ma,
            DQ => io_d,
            nCAS => ncas,
            nRAS => nras(6) & nras(7) & nras(6) & nras(7),
            nWE => nwe
        );

    flash0: entity work.flash
        port map (
            A => i_a(19 downto 1),
            DQ => io_d(23 downto 16),
            nCE => nen_flash
        );

    flash1: entity work.flash
        port map (
            A => i_a(19 downto 1),
            DQ => io_d(31 downto 24),
            nCE => nen_flash
        );
end test;
