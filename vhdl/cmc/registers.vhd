library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
    port (
        CLK: in std_logic;
        RST: in std_logic;
        
        REGCS: in std_logic;
        DS: in std_logic;
        R_nW: in std_logic;
        DSACK: out std_logic_vector(1 downto 0) := "00";
        A: in std_logic_vector(2 downto 0);
        D: inout std_logic_vector(7 downto 0) := (others => 'Z');

        MUX_SCHEME: out unsigned(2 downto 0) := "000";
        BANK_SIZE: out unsigned(2 downto 0) := "000";
        MODULE_COUNT: out unsigned(1 downto 0) := "00";

        DUAL_BANK: out boolean := false;
        REFRESH_CYCLE: out unsigned(14 downto 0) := (others => '0');

        RAS_CAS_DELAY: out boolean := false;
        CAS_PRE_DELAY: out boolean := false;
        WRITE_CAS_WIDTH: out boolean := false;
        ROM_LATENCY: out unsigned(2 downto 0) := "111"
    );
end registers;

architecture behavioral of registers is
    -- Memory Module Configuration Register
    signal MMCR: unsigned(7 downto 0) := x"00";
    signal MTR0: unsigned(7 downto 0) := x"00";
    signal MTR1: unsigned(7 downto 0) := x"00";
    signal MTR2: unsigned(7 downto 0) := x"38";

    -- MMIO Device Configuration Registers
begin
    MUX_SCHEME      <= MMCR(2 downto 0);
    BANK_SIZE       <= MMCR(5 downto 3);
    MODULE_COUNT    <= MMCR(7 downto 6);

    DUAL_BANK       <= true when MTR0(7) = '1' else false;
    REFRESH_CYCLE   <= MTR0(6 downto 0) & MTR1(7 downto 0);

    RAS_CAS_DELAY   <= true when MTR2(0) = '1' else false;
    CAS_PRE_DELAY   <= true when MTR2(1) = '1' else false;
    WRITE_CAS_WIDTH <= true when MTR2(2) = '1' else false;
    ROM_LATENCY     <= MTR2(5 downto 3);

    process(CLK, RST) is
        variable cycle_end: boolean := false;
    begin
        if RST = '1' then
            MMCR <= x"00";
            MTR0 <= x"00";
            MTR1 <= x"00";
            MTR2 <= x"38";
        elsif rising_edge(CLK) then
            if REGCS = '1' then
                if R_nW = '1' and DS = '1' then     -- Read
                    case to_integer(unsigned(A)) is
                        when 0 => D <= std_logic_vector(MMCR);
                        when 1 => D <= std_logic_vector(MTR0);
                        when 2 => D <= std_logic_vector(MTR1);
                        when 3 => D <= std_logic_vector(MTR2);
                        when others =>
                    end case;
                    DSACK <= "01";
                    cycle_end := true;
                elsif R_nW = '0' then               -- Write
                    DSACK <= "01";
                    if DS = '1' then
                        case to_integer(unsigned(A)) is
                            when 0 => MMCR <= unsigned(D);
                            when 1 => MTR0 <= unsigned(D);
                            when 2 => MTR1 <= unsigned(D);
                            when 3 => MTR2 <= unsigned(D);
                            when others =>
                        end case;
                        cycle_end := true;
                    end if;
                end if;
            end if;

            if cycle_end and DS = '0' then
                D <= (others => 'Z');
                DSACK <= "00";
                cycle_end := false;
            end if;
        end if;
    end process;
end behavioral;
