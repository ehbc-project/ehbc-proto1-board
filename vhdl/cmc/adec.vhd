library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adec is
    port (
        CLK: in std_logic;
        RST: in std_logic;

        AS: in std_logic;
        FC: in std_logic_vector(2 downto 0);
        A: in std_logic_vector(31 downto 0);

        BOOT: in std_logic;
        
        FPUCS: out std_logic := '0';

        ROMCS: out std_logic := '0';
        RAMCS: out std_logic := '0';
        REGCS: out std_logic := '0';

        DMAC0CS: out std_logic := '0';
        DMAC1CS: out std_logic := '0';
        MFP0CS: out std_logic := '0';
        MFP1CS: out std_logic := '0';
        FDCCS: out std_logic := '0';
        IDE0CS: out std_logic := '0';
        IDE1CS: out std_logic := '0';
        DUARTCS: out std_logic := '0';
        KBMSCS: out std_logic := '0';
        RTCCS: out std_logic := '0';
        VIDEOCS: out std_logic := '0';
        AUDIOCS: out std_logic := '0';
        ISACS: out std_logic := '0'
    );
end adec;

architecture dataflow of adec is
    signal MMIO: std_logic := '0';
    signal ISA: std_logic := '0';
    signal CPUSP: std_logic := '0';
begin
    MMIO <= '1' when AS = '1' and FC /= "111" and A(31 downto 24) = x"FF" else '0';
    ISA <= '1' when AS = '1' and FC /= "111" and A(31 downto 24) = x"FE" else '0';
    CPUSP <= '1' when AS = '1' and FC = "111";

    FPUCS <= '1' when CPUSP = '1' and A(19 downto 16) = x"2" else '0';

    ROMCS <= '1' when MMIO = '1' and A(23 downto 20) = x"F" else '0';
    REGCS <= '1' when MMIO = '1' and A(23 downto 4) = x"EFFFF" else '0';
    RAMCS <= '1' when AS = '1' and (MMIO or BOOT or ISA) = '0' else '0';

    -- DMAC: MC68440, uses 8 address bits, 16-bit data bus width
    DMAC0CS <= '1' when MMIO = '1' and A(23 downto 8) = x"0000" else '0';
    DMAC1CS <= '1' when MMIO = '1' and A(23 downto 8) = x"0001" else '0';

    -- MFP: MC68901, uses 5 address bits, 8-bit data bus width
    MFP0CS <= '1' when MMIO = '1' and A(23 downto 5) = x"0002" & "000" else '0';
    MFP1CS <= '1' when MMIO = '1' and A(23 downto 5) = x"0002" & "001" else '0';

    -- FDC: PC8477BV, uses 3 address bits, 8-bit data bus width
    FDCCS <= '1' when MMIO = '1' and A(23 downto 3) = x"0003" & "00000" else '0';

    -- IDE: uses 3 address bits, 16-bit data bus width
    IDE0CS <= '1' when MMIO = '1' and A(23 downto 3) = x"0003" & "00001" else '0';
    IDE1CS <= '1' when MMIO = '1' and A(23 downto 3) = x"0003" & "00010" else '0';

    -- DUART: MC68681: uses 4 address bits, 8-bit data bus width
    DUARTCS <= '1' when MMIO = '1' and A(23 downto 4) = x"0004" & "0000" else '0';

    -- KBMS: VT82C42: uses 1 address bits, 8-bit data bus width
    KBMSCS <= '1' when MMIO = '1' and A(23 downto 1) = x"0005" & "0000000" else '0';
    
    -- RTCCS: MC146818: A/D multiplexed (1 address bits), 8-bit data bus width
    RTCCS <= '1' when MMIO = '1' and A(23 downto 1) = x"0005" & "0000001" else '0';
end dataflow;
