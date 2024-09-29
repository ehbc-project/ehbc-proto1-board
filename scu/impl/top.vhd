library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity top is
    port (
        i_clk: in std_logic;
        i_isaclk: in std_logic;
        i_nrst: in std_logic;

        -- Chip Select Signals
        o_nen_rom: out std_logic;
        o_nen_i8042: out std_logic;
        o_nen_rtc: out std_logic;
        o_nen_ide: out std_logic_vector(1 downto 0);
        o_nen_fdc: out std_logic;
        o_nen_mfp0: out std_logic;
        o_nen_mfp1: out std_logic;
        o_nen_duart: out std_logic;
        o_nen_dmac0: out std_logic;
        o_nen_dmac1: out std_logic;

        -- Processor Interface Signals
        i_nas: in std_logic;
        i_nds: in std_logic;
        i_r_nw: in std_logic;
        i_size: in std_logic_vector(1 downto 0);
        o_ndsack: out std_logic_vector(1 downto 0) := (others => 'Z');
        o_nsterm: out std_logic := 'Z';
        i_fc: in std_logic_vector(2 downto 0);
        i_a: in std_logic_vector(31 downto 0);
        io_d: inout std_logic_vector(7 downto 0) := (others => 'Z');
        i_ncbreq: in std_logic;
        o_ncback: out std_logic := '1';
        o_nci: out std_logic;

        -- DRAM Controller Signals
        o_ma: out std_logic_vector(11 downto 0);
        o_ncas: out std_logic_vector(3 downto 0);
        o_nras: out std_logic_vector(7 downto 0);
        o_nwe: out std_logic;
        i_nrefresh: in std_logic;
        o_npagehit: out std_logic;

        -- ISA Bus Signals
        i_nnows: in std_logic;
        i_iochrdy_isa: in std_logic;
        i_iochck: in std_logic;
        o_ale: out std_logic;
        o_sbhe: out std_logic;
        o_nsmemr: out std_logic;
        o_nsmemw: out std_logic;
        o_nmemr: out std_logic;
        o_nmemw: out std_logic;
        o_nior: out std_logic;
        o_niow: out std_logic;
        o_nmemcs16: out std_logic;
        o_niocs16_isa: out std_logic;
        o_nbufen_isa: out std_logic;
        o_bufdir_isa: out std_logic;

        -- IDE Bus Signals
        o_niocs16_ide: out std_logic;
        i_iochrdy_ide: in std_logic;
        o_ndior: out std_logic;
        o_ndiow: out std_logic;
        o_nbufen_ide: out std_logic;
        o_bufdir_ide: out std_logic;

        -- Interrupt Controller Signals
        o_nipl: out std_logic_vector(2 downto 0);
        i_irq: in std_logic_vector(19 downto 0);
        o_iack: out std_logic_vector(4 downto 0);
        o_niacken: out std_logic;
        o_nberr: out std_logic;

        -- Processor Clock Configuration Signals
        o_npclk8m: out std_logic;
        o_pclksel: out std_logic_vector(2 downto 0);

        -- Power Control Signals
        i_npsw: in std_logic;
        o_npwroff: out std_logic;

        -- Misc Signals
        o_nboot: out std_logic;
        o_nrd: out std_logic;
        o_nwr: out std_logic
    );
end top;

architecture behavioral of top is
    signal i_rst: std_logic;
    signal berr: std_logic;

    -- Chip select / function enable signals
    signal en_ccr: std_logic;
    signal en_dcr: std_logic;
    signal en_fcr: std_logic;
    signal en_pcr: std_logic;
    signal en_abr: std_logic;
    signal en_ider: std_logic;
    signal en_isar: std_logic;
    signal en_picr: std_logic;

    signal en_ram: std_logic;
    signal en_flash: std_logic;
    signal en_isa: std_logic;

    signal en_ide: std_logic_vector(1 downto 0);
    signal en_i8042: std_logic;
    signal en_fdc: std_logic;
    signal en_rtc: std_logic;

    signal en_mfp0: std_logic;
    signal en_mfp1: std_logic;
    signal en_duart: std_logic;
    signal en_dmac0: std_logic;
    signal en_dmac1: std_logic;

    -- CPU interface signals for internal usage
    signal rd: std_logic := '0';
    signal wr: std_logic := '0';
    signal size: std_logic_vector(1 downto 0) := (others => '0');
    signal ack8: std_logic := '0';
    signal ack16: std_logic := '0';
    signal ack32: std_logic := '0';
    signal cben: std_logic := '1';
    signal cbok: std_logic := '0';
    signal ci: std_logic := '0';
    signal burst: std_logic := '0';
    signal fc: std_logic_vector(2 downto 0) := (others => '0');
    signal a: std_logic_vector(31 downto 0) := (others => '0');
    signal di: std_logic_vector(7 downto 0) := (others => '0');
    signal do: std_logic_vector(7 downto 0) := (others => '0');

    -- DRAM interface signals
    signal ras: std_logic_vector(7 downto 0);
    signal cas: std_logic_vector(3 downto 0);
    signal we: std_logic;
    signal refresh: std_logic;
    signal pagehit: std_logic;

    -- ISA bus interface signals
    signal nows: std_logic;
    signal smemr: std_logic;
    signal smemw: std_logic;
    signal memr: std_logic;
    signal memw: std_logic;
    signal ior: std_logic;
    signal iow: std_logic;
    signal memcs16: std_logic;
    signal iocs16_isa: std_logic;
    signal bufen_isa: std_logic;

    -- Interrupt controller signals
    signal nmi: std_logic;

    -- IDE bus interface signals
    signal iocs16_ide: std_logic;
    signal dior: std_logic;
    signal diow: std_logic;
    signal bufen_ide: std_logic;

    -- Power control signals
    signal psw: std_logic;
    signal pwroff: std_logic;

    -- Misc signals
    signal boot: std_logic;

    -- CCR register data
    signal ccr_data: std_logic_vector(7 downto 0);

    -- Individual ack/do signals
    signal ack8_boot_vector: std_logic;
    signal ack8_isab: std_logic;
    signal ack8_ideb: std_logic;
    signal ack8_fmcb: std_logic;
    signal ack8_mcb: std_logic;
    signal ack8_pwb: std_logic;
    signal ack8_ccr: std_logic;
    signal ack16_isab: std_logic;
    signal ack16_ideb: std_logic;
    signal ack16_fmcb: std_logic;
    signal do_boot_vector: std_logic_vector(7 downto 0);
    signal do_isab: std_logic_vector(7 downto 0);
    signal do_ideb: std_logic_vector(7 downto 0);
    signal do_fmcb: std_logic_vector(7 downto 0);
    signal do_mcb: std_logic_vector(7 downto 0);
    signal do_ccr: std_logic_vector(7 downto 0);
    signal do_pwb: std_logic_vector(7 downto 0);
begin
    o_nen_rom <= not en_flash;
    o_nen_i8042 <= not en_i8042;
    o_nen_rtc <= not en_rtc;
    o_nen_ide <= not en_ide;
    o_nen_fdc <= not en_fdc;
    o_nen_mfp0 <= not en_mfp0;
    o_nen_mfp1 <= not en_mfp1;
    o_nen_duart <= not en_duart;
    o_nen_dmac0 <= not en_dmac0;
    o_nen_dmac1 <= not en_dmac1;

    i_rst <= not i_nrst;
    o_nberr <= not berr;
    o_nboot <= not boot;
    o_nci <= not ci;

    o_nras <= not ras;
    o_ncas <= not cas;
    o_nwe <= not we;
    refresh <= not i_nrefresh;
    o_npagehit <= not pagehit;

    nows <= not i_nnows;
    o_nsmemr <= not smemr;
    o_nsmemw <= not smemw;
    o_nmemr <= not memr;
    o_nmemw <= not memw;
    o_nior <= not ior;
    o_niow <= not iow;
    o_nmemcs16 <= not memcs16;
    o_niocs16_isa <= not iocs16_isa;
    o_nbufen_isa <= not bufen_isa;

    o_niocs16_ide <= not iocs16_ide;
    o_ndior <= not dior;
    o_ndiow <= not diow;
    o_nbufen_ide <= not bufen_ide;

    psw <= not i_npsw;
    o_npwroff <= not pwroff;

    o_npclk8m <= ccr_data(7);
    o_pclksel <= ccr_data(6 downto 4);
    boot <= not ccr_data(1);
    cben <= ccr_data(0);

    ack8 <= ack8_boot_vector or ack8_isab or ack8_ideb or ack8_fmcb or ack8_mcb or ack8_ccr or ack8_pwb;
    ack16 <= ack16_isab or ack16_ideb or ack16_fmcb;
    do <= do_boot_vector or do_isab or do_ideb or do_fmcb or do_mcb or do_ccr or do_pwb;

    rd <= not i_nas and i_r_nw;
    wr <= not i_nas and not i_r_nw;

    process(i_clk, i_nrst)
    begin
        if i_nrst = '0' then
        elsif rising_edge(i_clk) then
            if i_nas = '0' then
                a <= i_a;
                size <= i_size;
                fc <= i_fc;
            end if;

            if i_nds = '0' then
                if rd = '1' then  -- read
                    io_d <= do;
                elsif wr = '1' then  -- write
                    di <= io_d;
                end if;

                burst <= cben and cbok and not i_ncbreq;
            end if;

            if ack8 = '1' then
                o_ndsack <= DSACK_8;
            elsif ack16 = '1' then
                o_ndsack <= DSACK_16;
            elsif ack32 = '1' then
                o_nsterm <= '0';
            else
                o_ndsack <= DSACK_IDLE;
                o_nsterm <= 'Z';
            end if;

            o_ncback <= not (cben and cbok and not i_ncbreq);
        end if;
    end process;

    pwb: entity work.pwb
        port map (
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_en_pcr => en_pcr,
            i_rd     => rd,
            i_wr     => wr,
            i_d      => di,
            o_d      => do_pwb,
            o_ack8   => ack8_pwb,
            i_psw    => psw,
            o_pwroff => pwroff,
            o_nmi    => nmi
        );

    ccr: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => en_ccr,
            i_rd   => rd,
            i_wr   => wr,
            o_ack8 => ack8_ccr,
            i_d    => di,
            o_d    => do_ccr,
            o_reg  => ccr_data
        );

    boot_vector: entity work.boot_vector
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_rd   => rd,
            i_a    => a(2 downto 0),
            o_d    => do_boot_vector,
            o_ack8 => ack8_boot_vector,
            i_boot => boot
        );

    addr_decoder: entity work.addr_decoder
        port map (
            i_fc       => fc,
            i_a        => i_a,
            i_as       => not i_nas,
            i_boot     => boot,
            o_cbok     => cbok,
            o_ci       => ci,
            o_en_ccr   => en_ccr,
            o_en_dcr   => en_dcr,
            o_en_fcr   => en_fcr,
            o_en_pcr   => en_pcr,
            o_en_abr   => en_abr,
            o_en_ider  => en_ider,
            o_en_isar  => en_isar,
            o_en_picr  => en_picr,
            o_en_ram   => en_ram,
            o_en_flash => en_flash,
            o_en_isa   => en_isa,
            o_en_ide   => en_ide,
            o_en_i8042 => en_i8042,
            o_en_fdc   => en_fdc,
            o_en_rtc   => en_rtc,
            o_en_mfp0  => en_mfp0,
            o_en_mfp1  => en_mfp1,
            o_en_duart => en_duart,
            o_en_dmac0 => en_dmac0,
            o_en_dmac1 => en_dmac1
        );

    isab: entity work.isab
        port map (
            i_rst        => i_rst,
            i_clk        => i_clk,
            i_isaclk     => i_isaclk,
            i_en_isa     => en_isa,
            i_en_isar    => en_isar,
            i_size       => size,
            i_rd         => rd,
            i_wr         => wr,
            i_a          => a(23 downto 16),
            i_d          => di,
            o_d          => do_isab,
            o_berr       => berr,
            o_ack8       => ack8_isab,
            o_ack16      => ack16_isab,
            i_nows       => nows,
            i_iochrdy    => i_iochrdy_isa,
            i_iochck     => i_iochck,
            o_ale        => o_ale,
            o_sbhe       => o_sbhe,
            o_smemr      => smemr,
            o_smemw      => smemw,
            o_memr       => memr,
            o_memw       => memw,
            o_ior        => ior,
            o_iow        => iow,
            o_memcs16    => memcs16,
            o_iocs16     => iocs16_isa,
            o_bufen      => bufen_isa,
            o_bufdir     => o_bufdir_isa
        );

    ideb: entity work.ideb
        port map (
            i_rst     => i_rst,
            i_clk     => i_clk,
            i_en_ide  => en_ide,
            i_en_ider => en_ider,
            i_size    => size,
            i_rd      => rd,
            i_wr      => wr,
            i_a0      => a(0),
            i_d       => di,
            o_d       => do_ideb,
            o_ack8    => ack8_ideb,
            o_ack16   => ack16_ideb,
            o_iocs16  => iocs16_ide,
            o_dior    => dior,
            o_diow    => diow,
            i_iochrdy => i_iochrdy_ide,
            o_bufen   => bufen_ide,
            o_bufdir  => o_bufdir_ide
        );

    fmcb: entity work.fmcb
        port map (
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_en_flash => en_flash,
            i_en_fcr   => en_fcr,
            i_rd       => rd,
            i_wr       => wr,
            i_d        => di,
            o_d        => do_fmcb,
            o_ack8     => ack8_fmcb,
            o_ack16    => ack16_fmcb
        );

    mcb: entity work.mcb
        port map (
            i_rst     => i_rst,
            i_clk     => i_clk,
            i_en_ram  => en_ram,
            i_en_abr  => en_abr,
            i_en_dcr  => en_dcr,
            i_size    => size,
            i_rd      => rd,
            i_wr      => wr,
            i_a       => a(27 downto 0),
            i_d       => di,
            o_d       => do_mcb,
            o_ack8    => ack8_mcb,
            o_ack32   => ack32,
            i_burst   => burst,
            o_ma      => o_ma,
            o_ras     => ras,
            o_cas     => cas,
            o_we      => we,
            i_refresh => refresh,
            o_pagehit => pagehit
        );
end behavioral;
