library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

entity memc is
    port (
        CLK: in std_logic;
        RST: in std_logic;
        RAMCS: in std_logic;
        DS: in std_logic;
        R_nW: in std_logic;
        SIZE: in std_logic_vector(1 downto 0);
        STERM: out std_logic := 'Z';
        A: in std_logic_vector(26 downto 0);
        CBREQ: in std_logic;
        CBACK: out std_logic := '0';
        
        MA: out std_logic_vector(11 downto 0) := (others => '0');
        RAS: out std_logic_vector(7 downto 0);
        CAS: out std_logic_vector(3 downto 0);
        WE: out std_logic := '0';

        REFRESH: out std_logic := '0';
        RFSHREQ: in std_logic := '0';
        REFRACK: out std_logic := '0';
        PAGEHIT: out std_logic := '0';

        MUX_SCHEME: in unsigned(2 downto 0);
        BANK_SIZE: in unsigned(2 downto 0);
        MODULE_COUNT: in unsigned(1 downto 0);
        DUAL_BANK: in boolean;
        RAS_CAS_DELAY: in boolean;
        CAS_PRE_DELAY: in boolean;
        WRITE_CAS_WIDTH: in boolean
    );
end memc;

architecture behavioral of memc is
    signal MAEN: std_logic := '0';
    signal C_nR: std_logic := '1';
    signal CASEN: std_logic := '0';
    signal RASEN: std_logic := '0';
    signal RASALL: std_logic := '0';
    signal CASALL: std_logic := '0';

    signal CA: std_logic_vector(11 downto 0);
    signal RA: std_logic_vector(11 downto 0);
    signal BA: std_logic_vector(2 downto 0);

    type state_type is (
        S_IDLE,
        S_CHGPAGE, S_RA, S_RAS,
        S_CA, S_CAS,
        S_ACK, S_XFEREND, 
        S_RCAS, S_RRAS, S_RRASEND, S_RCASEND
    );
    signal state: state_type := S_IDLE;

    signal page_hit: boolean := false;
    signal prev_page_valid: boolean := false;
    signal prev_page: std_logic_vector(11 downto 0) := (others => '0');

    signal delay_valid: boolean := false;
    signal delay_counter: integer range 0 to 3 := 0;

    signal refresh_pending: boolean := false;
    signal refresh_cycle: boolean := false;

    signal burst: boolean := false;
    signal burst_end: boolean := false;

    signal addr_temp: std_logic_vector(26 downto 2) := (others => '0');
    signal burst_addr: std_logic_vector(26 downto 2) := (others => '0');
begin
    addr_temp <= burst_addr when burst else A(26 downto 2);

    ADDRMUX: entity work.addrmux(dataflow)
        port map (
            CLK => CLK,
            A => addr_temp,
            CA => CA,
            RA => RA,
            BA => BA,
            MUX_SCHEME => MUX_SCHEME,
            BANK_SIZE => BANK_SIZE
        );

    RASGEN: entity work.rasgen(behavioral)
        port map (
            CLK => CLK,
            RST => RST,
            BA => BA,
            DUAL_BANK => DUAL_BANK,
            RASEN => RASEN,
            ALLEN => RASALL,
            RAS => RAS
        );

    CASGEN: entity work.casgen(dataflow)
        port map (
            SIZE => SIZE,
            A => A(1 downto 0),
            R_nW => R_nW,
            CASEN => CASEN,
            ALLEN => CASALL,
            CAS => CAS
        );

    page_hit <= prev_page_valid and prev_page = RA;

    process (CLK) is
    begin
        if rising_edge(CLK) then
            case state is
                when S_IDLE =>
                    if refresh_pending then
                        RASEN <= '0';
                        CASEN <= '0';
                        REFRESH <= '1';
                        refresh_cycle <= true;
                        refresh_pending <= false;
                        prev_page_valid <= false;
                        state <= S_RCAS;
                    elsif RAMCS = '1' then
                        if page_hit then
                            PAGEHIT <= '1';
                            state <= S_CA;
                        elsif prev_page_valid then
                            state <= S_CHGPAGE;
                        else
                            state <= S_RA;
                        end if;

                        if CBREQ = '1' and not burst then
                            CBACK <= '1';
                            burst_addr <= A(26 downto 2);
                            burst <= true;
                        elsif CBREQ = '0' then
                            CBACK <= '0';
                            burst_end <= true;
                        end if;
                    end if;
                when S_CHGPAGE =>
                    RASEN <= '0';
                    state <= S_RA;
                when S_RA =>
                    MA <= RA;
                    prev_page_valid <= true;
                    prev_page <= RA;
                    state <= S_RAS;
                when S_RAS =>
                    RASEN <= '1';
                    state <= S_CA;
                when S_CA =>
                    MA <= CA;
                    WE <= not R_nW;
                    state <= S_CAS;
                when S_CAS =>
                    CASEN <= '1';
                    state <= S_ACK;
                when S_ACK =>
                    STERM <= '1';
                    if burst then
                        burst_addr <= std_logic_vector(unsigned(burst_addr) + 4);
                    end if;
                    if burst_end then
                        burst <= false;
                        burst_end <= false;
                    end if;
                    state <= S_XFEREND;
                when S_XFEREND =>
                    MA <= x"000";
                    STERM <= '0';
                    CASEN <= '0';
                    PAGEHIT <= '0';
                    WE <= '0';
                    state <= S_IDLE;
                when S_RCAS =>
                    CASALL <= '1';
                    state <= S_RRAS;
                when S_RRAS =>
                    if delay_valid and delay_counter = 0 then
                        delay_valid <= false;
                        state <= S_RCASEND;
                    else
                        RASALL <= '1';
                        delay_valid <= true;
                        delay_counter <= 3;
                    end if;
                when S_RCASEND =>
                    CASALL <= '0';
                    refresh_pending <= false;
                    state <= S_RRASEND;
                when S_RRASEND =>
                    RASALL <= '0';
                    REFRESH <= '0';
                    state <= S_IDLE;
            end case;

            if delay_counter /= 0 then
                delay_counter <= delay_counter - 1;
            end if;

            if RFSHREQ = '1' and not refresh_cycle then
                refresh_pending <= true;
            elsif RFSHREQ = '0' then
                refresh_cycle <= false;
            end if;
        end if;
    end process;
end behavioral;
