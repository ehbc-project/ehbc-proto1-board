library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity top is
    port (
        i_clk:          in std_logic;
        i_isaclk:       in std_logic;
        i_nrst:         in std_logic;

        -- Chip Select Signals
        o_nen_flash:    out std_logic;
        o_nen_mfp0:     out std_logic;
        o_nen_mfp1:     out std_logic;
        o_nen_dmac0:    out std_logic;
        o_nen_dmac1:    out std_logic;

        -- Processor Interface Signals
        i_nas:          in std_logic;
        i_nds:          in std_logic;
        i_r_nw:         in std_logic;
        i_size:         in std_logic_vector(1 downto 0);
        o_ndsack:       out std_logic_vector(1 downto 0) := (others => 'Z');
        o_nsterm:       out std_logic := 'Z';
        i_fc:           in std_logic_vector(2 downto 0);
        i_a:            in std_logic_vector(31 downto 0);
        io_d:           inout std_logic_vector(7 downto 0) := (others => 'Z');
        i_ncbreq:       in std_logic;
        o_ncback:       out std_logic := '1';
        o_nci:          out std_logic := '1';
        o_nberr:        out std_logic;

        -- DRAM Controller Signals
        o_ma:           out std_logic_vector(11 downto 0);
        o_ncas:         out std_logic_vector(3 downto 0);
        o_nras:         out std_logic_vector(7 downto 0);
        o_nwe:          out std_logic;
        i_nrefresh:     in std_logic;
        o_npagehit:     out std_logic;

        -- ISA Bus Signals
        i_nnows:        in std_logic;
        i_iochrdy:      in std_logic;
        i_iochck:       in std_logic;
        o_ale:          out std_logic;
        o_sbhe:         out std_logic;
        o_nsmemr:       out std_logic;
        o_nsmemw:       out std_logic;
        o_nmemr:        out std_logic;
        o_nmemw:        out std_logic;
        o_nior:         out std_logic;
        o_niow:         out std_logic;
        o_nmemcs16:     out std_logic;
        o_niocs16:      out std_logic;
        o_nbufen:       out std_logic;
        o_bufdir:       out std_logic;

        -- Interrupt Controller Signals
        o_nipl:         out std_logic_vector(2 downto 0);
        i_irq:          in std_logic_vector(19 downto 0);

        -- Processor Clock Configuration Signals
        o_npclk8m:      out std_logic;
        o_pclksel:      out std_logic_vector(2 downto 0);

        -- Power Control Signals
        i_npsw:         in std_logic;
        o_npwroff:      out std_logic
    );
end top;

architecture behavioral of top is
    signal rst: std_logic;

    -- Chip, entity, or register select signals
    signal sel_coproc: std_logic;
    signal sel_iack: std_logic;
    signal sel_dram: std_logic;
    signal sel_flash: std_logic;
    signal sel_isa: std_logic;
    signal sel_ireg: std_logic;
    signal sel_mfp0: std_logic;
    signal sel_mfp1: std_logic;
    signal sel_dmac0: std_logic;
    signal sel_dmac1: std_logic;
    signal sel_ccr: std_logic;
    signal sel_pcr: std_logic;
    signal sel_isar: std_logic;
    signal sel_fcr: std_logic;
    signal sel_abr: std_logic;
    signal sel_dcr: std_logic;
    signal sel_tcr: std_logic;
    signal sel_icr: std_logic;

    -- Internal Bus Signals
    signal rd: std_logic := '0';
    signal wr: std_logic := '0';
    signal ack8: std_logic := '0';
    signal ack16: std_logic := '0';
    signal ack32: std_logic := '0';
    signal berr: std_logic;
    signal di: std_logic_vector(7 downto 0) := (others => '0');
    signal do: std_logic_vector(7 downto 0) := (others => '0');
    signal cbok: std_logic := '0';
    signal ci: std_logic := '0';
    signal burst: std_logic := '0';

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
    signal iocs16: std_logic;
    signal bufen: std_logic;

    -- Interrupt controller signals
    signal irq_internal: std_logic_vector(3 downto 0);
    signal ipl: std_logic_vector(2 downto 0);

    -- Power control signals
    signal psw: std_logic;
    signal pwroff: std_logic;

    -- CCR register data
    signal ccr_data: std_logic_vector(7 downto 0);
    signal cpu_enable_burst: boolean := false;
    signal remap_flash: boolean := true;

    type do_array_t is array(0 to 6) of std_logic_vector(7 downto 0);
    signal do_array: do_array_t;
    signal ack8_array: std_logic_vector(6 downto 0);
    signal ack16_array: std_logic_vector(1 downto 0);
begin
    rst <= not i_nrst;
    
    o_nen_flash <= not sel_flash;
    o_nen_mfp0 <= not sel_mfp0;
    o_nen_mfp1 <= not sel_mfp1;
    o_nen_dmac0 <= not sel_dmac0;
    o_nen_dmac1 <= not sel_dmac1;

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
    o_niocs16 <= not iocs16;
    o_nbufen <= not bufen;

    o_nipl(0) <= '0' when ipl(0) = '1' else 'Z';
    o_nipl(1) <= '0' when ipl(1) = '1' else 'Z';
    o_nipl(2) <= '0' when ipl(2) = '1' else 'Z';

    psw <= not i_npsw;
    o_npwroff <= not pwroff;

    do <=
        do_array(0) or do_array(1) or do_array(2) or do_array(3) or
        do_array(4) or do_array(5) or do_array(6);
    ack8 <= or ack8_array;
    ack16 <= or ack16_array;

    register_ccr: entity work.reg
        generic map (
            reset_value     => x"02"
        )
        port map (
            i_clk       => i_clk,
            i_rst       => rst,
            i_select    => sel_ccr,

            i_rd        => rd,
            i_wr        => wr,
            i_di        => di,
            o_do        => do_array(0),
            o_ack8      => ack8_array(0),

            o_reg       => ccr_data
        );
    o_npclk8m <= ccr_data(7);
    o_pclksel <= ccr_data(6 downto 4);
    remap_flash <= ccr_data(1) = '1';
    cpu_enable_burst <= ccr_data(0) = '1';

    cpu_interface: entity work.cpu_interface
        port map (
            i_clk               => i_clk,
            i_nrst              => i_nrst,

            i_nas               => i_nas,
            i_nds               => i_nds,
            i_r_nw              => i_r_nw,
            o_ndsack            => o_ndsack,
            o_nsterm            => o_nsterm,
            o_nberr             => o_nberr,
            i_fc                => i_fc,
            i_a                 => i_a,
            io_d                => io_d,
            i_ncbreq            => i_ncbreq,
            o_ncback            => o_ncback,

            o_rd                => rd,
            o_wr                => wr,
            i_ack8              => ack8,
            i_ack16             => ack16,
            i_ack32             => ack32,
            i_berr              => berr,
            o_di                => di,
            i_do                => do,
            i_cbok              => cbok,
            i_ci                => ci,
            o_burst             => burst,

            i_cpu_enable_burst  => cpu_enable_burst
        );

    addr_decoder: entity work.addr_decoder
        port map (
            i_nas               => i_nas,
            i_fc                => i_fc,
            i_a                 => i_a,
            o_sel_coproc        => sel_coproc,
            o_sel_iack          => sel_iack,
            o_sel_dram          => sel_dram,
            o_sel_flash         => sel_flash,
            o_sel_isa           => sel_isa,
            o_sel_ireg          => sel_ireg,
            o_sel_mfp0          => sel_mfp0,
            o_sel_mfp1          => sel_mfp1,
            o_sel_dmac0         => sel_dmac0,
            o_sel_dmac1         => sel_dmac1,
            o_sel_ccr           => sel_ccr,
            o_sel_pcr           => sel_pcr,
            o_sel_isar          => sel_isar,
            o_sel_fcr           => sel_fcr,
            o_sel_abr           => sel_abr,
            o_sel_dcr           => sel_dcr,
            o_sel_tcr           => sel_tcr,
            o_sel_icr           => sel_icr,
            i_remap_flash       => remap_flash
        );

    power_controller: entity work.power_controller
        port map (
            i_rst               => rst,
            i_clk               => i_clk,
            i_sel_pcr           => sel_pcr,
            
            i_rd                => rd,
            i_wr                => wr,
            i_d                 => di,
            o_d                 => do_array(1),
            o_ack8              => ack8_array(1),

            i_psw               => psw,
            o_pwroff            => pwroff,
            o_irq               => irq_internal(3)
        );

    isa_controller: entity work.isa_controller
        port map (
            i_rst               => rst,
            i_clk               => i_clk,
            i_isaclk            => i_isaclk,
            i_select            => sel_isa,
            i_sel_isar          => sel_isar,

            i_size              => i_size,
            i_rd                => rd,
            i_wr                => wr,
            i_a                 => i_a(23 downto 16),
            i_d                 => di,
            o_d                 => do_array(2),
            o_berr              => berr,
            o_ack8              => ack8_array(2),
            o_ack16             => ack16_array(0),

            i_nows              => nows,
            i_iochrdy           => i_iochrdy,
            i_iochck            => i_iochck,
            o_ale               => o_ale,
            o_sbhe              => o_sbhe,
            o_smemr             => smemr,
            o_smemw             => smemw,
            o_memr              => memr,
            o_memw              => memw,
            o_ior               => ior,
            o_iow               => iow,
            o_memcs16           => memcs16,
            o_iocs16            => iocs16,

            o_bufen             => bufen,
            o_bufdir            => o_bufdir
        );

    flash_controller: entity work.flash_controller
        port map (
            i_rst               => rst,
            i_clk               => i_clk,
            i_select            => sel_flash,
            i_sel_fcr           => sel_fcr,

            i_rd                => rd,
            i_wr                => wr,
            i_d                 => di,
            o_d                 => do_array(3),
            o_ack8              => ack8_array(3),
            o_ack16             => ack16_array(1)
        );

    dram_controller: entity work.dram_controller
        port map (
            i_rst               => rst,
            i_clk               => i_clk,
            i_select            => sel_dram,
            i_sel_abr           => sel_abr,
            i_sel_dcr           => sel_dcr,

            i_size              => i_size,
            i_rd                => rd,
            i_wr                => wr,
            i_a                 => i_a(27 downto 0),
            i_d                 => di,
            o_d                 => do_array(4),
            o_ack8              => ack8_array(4),
            o_ack32             => ack32,
            o_cbok              => cbok,
            i_burst             => burst,

            i_refresh           => refresh,

            o_ma                => o_ma,
            o_ras               => ras,
            o_cas               => cas,
            o_we                => we,
            o_pagehit           => pagehit
        );

    timer: entity work.timer
        port map (
            i_rst               => rst,
            i_clk               => i_clk,
            i_sel_tcr           => sel_tcr,
            
            i_rd                => rd,
            i_wr                => wr,
            i_a                 => i_a(3 downto 0),
            i_d                 => di,
            o_d                 => do_array(5),
            o_ack8              => ack8_array(5),

            o_irq               => irq_internal(2 downto 0)
        );

    irq_controller: entity work.irq_controller
        port map (
            i_clk               => i_clk,
            i_rst               => rst,
            i_sel_icr           => sel_icr,
            i_sel_iack          => sel_iack,
            
            i_rd                => rd,
            i_wr                => wr,
            i_a                 => i_a(3 downto 0),
            i_d                 => di,
            o_d                 => do_array(6),
            o_ack8              => ack8_array(6),

            i_irq               => irq_internal & i_irq,

            o_ipl               => ipl
        );
end behavioral;
