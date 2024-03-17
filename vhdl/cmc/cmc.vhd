library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cmc is
    port (
        CLK: in std_logic;
        RFSHCLK: in std_logic;
        ISACLK: in std_logic;
        nRST: in std_logic;

        -- Chip Select Signals
        nFPUCS: out std_logic;
        nROMCS: out std_logic;
        nDMAC0CS: out std_logic;
        nDMAC1CS: out std_logic;
        nMFP0CS: out std_logic;
        nMFP1CS: out std_logic;
        nFDCCS: out std_logic;
        nIDE0CS: out std_logic;
        nIDE1CS: out std_logic;
        nDUARTCS: out std_logic;
        nKBMSCS: out std_logic;
        nRTCCS: out std_logic;
        nVIDEOCS: out std_logic;
        nAUDIOCS: out std_logic;

        -- Processor Interface Signals
        nAS: in std_logic;
        nDS: in std_logic;
        R_nW: in std_logic;
        SIZE: in std_logic_vector(1 downto 0);
        nDSACK: out std_logic_vector(1 downto 0) := "ZZ";
        nSTERM: out std_logic := 'Z';
        FC: in std_logic_vector(2 downto 0);
        A: in std_logic_vector(31 downto 0);
        D: inout std_logic_vector(7 downto 0) := (others => 'Z');
        nCBREQ: in std_logic;
        nCBACK: out std_logic;
        nCI: out std_logic;
        nRD: out std_logic;
        nWR: out std_logic;

        -- DRAM Interface Signals
        MA: out std_logic_vector(11 downto 0) := (others => '0');
        nCAS: out std_logic_vector(3 downto 0) := (others => '1');
        nRAS: out std_logic_vector(7 downto 0) := (others => '1');
        nWE: out std_logic;

        -- Cache Interface Signals
        TD: inout std_logic_vector(15 downto 0);
        nCBE: out std_logic_vector(3 downto 0);
        nTOE: out std_logic;
        nCTWE: out std_logic;

        -- Misc Signals
        nREFRESH: out std_logic;
        nPAGEHIT: out std_logic;
        nBOOT: out std_logic
    );
end cmc;

architecture structural of cmc is
    signal RST: std_logic;
    signal FPUCS: std_logic := '0';
    signal ROMCS: std_logic := '0';
    signal RAMCS: std_logic := '0';
    signal REGCS: std_logic := '0';
    signal DMAC0CS: std_logic := '0';
    signal DMAC1CS: std_logic := '0';
    signal MFP0CS: std_logic := '0';
    signal MFP1CS: std_logic := '0';
    signal FDCCS: std_logic := '0';
    signal IDE0CS: std_logic := '0';
    signal IDE1CS: std_logic := '0';
    signal DUARTCS: std_logic := '0';
    signal KBMSCS: std_logic := '0';
    signal RTCCS: std_logic := '0';
    signal VIDEOCS: std_logic := '0';
    signal AUDIOCS: std_logic := '0';
    signal AS: std_logic;
    signal DS: std_logic;
    signal BV_DSACK: std_logic_vector(1 downto 0) := "00";
    signal REG_DSACK: std_logic_vector(1 downto 0) := "00";
    signal ROM_DSACK: std_logic_vector(1 downto 0) := "00";
    signal DSACK: std_logic_vector(1 downto 0) := "00";
    signal RAM_STERM: std_logic;
    signal CACHE_STERM: std_logic;
    signal CAS: std_logic_vector(3 downto 0);
    signal RAS: std_logic_vector(7 downto 0);
    signal WE: std_logic := '0';
    signal REFRESH: std_logic := '0';
    signal RFSHREQ: std_logic := '0';
    signal PAGEHIT: std_logic := '0';
    signal BOOT: std_logic := '1';
    signal CBE: std_logic_vector(3 downto 0) := "0000";
    signal TOE: std_logic := '0';
    signal CTWE: std_logic := '0';
    signal CBREQ: std_logic;
    signal CBACK: std_logic := '0';
    signal CI: std_logic := '0';

    signal MUX_SCHEME: unsigned(2 downto 0);
    signal BANK_SIZE: unsigned(2 downto 0);
    signal MODULE_COUNT: unsigned(1 downto 0);
    signal DUAL_BANK: boolean;
    signal REFRESH_CYCLE: unsigned(14 downto 0);
    signal RAS_CAS_DELAY: boolean;
    signal CAS_PRE_DELAY: boolean;
    signal WRITE_CAS_WIDTH: boolean;
    signal ROM_LATENCY: unsigned(2 downto 0);
begin
    RST <= not nRST;
    nFPUCS <= not FPUCS;
    nROMCS <= not ROMCS;
    nDMAC0CS <= not DMAC0CS;
    nDMAC1CS <= not DMAC1CS;
    nMFP0CS <= not MFP0CS;
    nMFP1CS <= not MFP1CS;
    nFDCCS <= not FDCCS;
    nIDE0CS <= not IDE0CS;
    nIDE1CS <= not IDE1CS;
    nDUARTCS <= not DUARTCS;
    nKBMSCS <= not KBMSCS;
    nRTCCS <= not RTCCS;
    nVIDEOCS <= not VIDEOCS;
    nAUDIOCS <= not AUDIOCS;
    AS <= not nAS;
    DS <= not nDS;
    DSACK <= BV_DSACK or REG_DSACK or ROM_DSACK;
    nDSACK(0) <= '0' when DSACK(0) = '1' else 'Z';
    nDSACK(1) <= '0' when DSACK(1) = '1' else 'Z';
    nSTERM <= '0' when (RAM_STERM or CACHE_STERM) = '1' else 'Z';
    nCAS <= not CAS;
    nRAS <= not RAS;
    nWE <= not WE;
    nREFRESH <= not REFRESH;
    nPAGEHIT <= not PAGEHIT;
    nBOOT <= not BOOT;
    nCBE <= not CBE;
    nTOE <= not TOE;
    nCTWE <= not CTWE;
    CBREQ <= not nCBREQ;
    nCBACK <= not CBACK;
    nCI <= not CI;
    nRD <= nDS or not R_nW;
    nWR <= nDS or R_nW;

    BOOTVECTOR: entity work.bootvector(behavioral)
        generic map (
            INITIAL_SP => x"00000000",
            INITIAL_PC => x"FFF00000"
        )
        port map (
            CLK => CLK,
            RST => RST,
            AS => AS,
            DS => DS,
            R_nW => R_nW,
            SIZE => SIZE,
            DSACK => BV_DSACK,
            A => A,
            D => D,
            BOOT => BOOT
        );

    ADEC: entity work.adec(dataflow)
        port map (
            CLK => CLK,
            RST => RST,
            AS => AS,
            FC => FC,
            A => A,
            BOOT => BOOT,
            FPUCS => FPUCS,
            ROMCS => ROMCS,
            RAMCS => RAMCS,
            REGCS => REGCS,
            DMAC0CS => DMAC0CS,
            DMAC1CS => DMAC1CS,
            MFP0CS => MFP0CS,
            MFP1CS => MFP1CS,
            FDCCS => FDCCS,
            IDE0CS => IDE0CS,
            IDE1CS => IDE1CS,
            DUARTCS => DUARTCS,
            KBMSCS => KBMSCS,
            RTCCS => RTCCS,
            VIDEOCS => VIDEOCS,
            AUDIOCS => AUDIOCS
        );

    REGISTERS: entity work.registers(behavioral)
        port map (
            CLK => CLK,
            RST => RST,
            REGCS => REGCS,
            DS => DS,
            R_nW => R_nW,
            DSACK => REG_DSACK,
            A => A(2 downto 0),
            D => D,
            MUX_SCHEME => MUX_SCHEME,
            BANK_SIZE => BANK_SIZE,
            MODULE_COUNT => MODULE_COUNT,
            DUAL_BANK => DUAL_BANK,
            REFRESH_CYCLE => REFRESH_CYCLE,
            RAS_CAS_DELAY => RAS_CAS_DELAY,
            CAS_PRE_DELAY => CAS_PRE_DELAY,
            WRITE_CAS_WIDTH => WRITE_CAS_WIDTH,
            ROM_LATENCY => ROM_LATENCY
        );

    CACC: entity work.cacc(behavioral)
        port map (
            CLK => CLK,
            RST => RST,
            RAMCS => RAMCS,
            DS => DS,
            R_nW => R_nW,
            SIZE => SIZE,
            STERM => CACHE_STERM,
            A => A,
            TD => TD,
            CBE => CBE,
            TOE => TOE,
            CTWE => CTWE
        );

    ROMC: entity work.romc(behavioral)
        port map (
            CLK => CLK,
            ROMCS => ROMCS,
            DS => DS,
            R_nW => R_nW,
            DSACK => ROM_DSACK,
            ROM_LATENCY => ROM_LATENCY
        );

    MEMC: entity work.memc(behavioral)
        port map (
            CLK => CLK,
            RST => RST,
            RAMCS => RAMCS,
            DS => DS,
            R_nW => R_nW,
            SIZE => SIZE,
            STERM => RAM_STERM,
            A => A(26 downto 0),
            CBREQ => CBREQ,
            CBACK => CBACK,
            MA => MA,
            RAS => RAS,
            CAS => CAS,
            WE => WE,
            REFRESH => REFRESH,
            RFSHREQ => RFSHREQ,
            PAGEHIT => PAGEHIT,
            MUX_SCHEME => MUX_SCHEME,
            BANK_SIZE => BANK_SIZE,
            MODULE_COUNT => MODULE_COUNT,
            DUAL_BANK => DUAL_BANK,
            RAS_CAS_DELAY => RAS_CAS_DELAY,
            CAS_PRE_DELAY => CAS_PRE_DELAY,
            WRITE_CAS_WIDTH => WRITE_CAS_WIDTH
        );

    RFSHCNTR: entity work.rfshcntr(behavioral)
        port map (
            CLK => CLK,
            RFSHCLK => RFSHCLK,
            RST => RST,
            REFRESH_CYCLE => REFRESH_CYCLE,
            RFSHREQ => RFSHREQ
        );
end structural;
