library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.common.all;

entity dram_controller is
    port (
        i_rst:              in std_logic;
        i_clk:              in std_logic;
        i_select:           in std_logic;
        i_sel_abr:          in std_logic;
        i_sel_dcr:          in std_logic;

        -- Internal Bus Signals
        i_size:             in std_logic_vector(1 downto 0);
        i_rd:               in std_logic;
        i_wr:               in std_logic;
        i_a:                in std_logic_vector(27 downto 0);
        i_d:                in std_logic_vector(7 downto 0);
        o_d:                out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:             out std_logic := '0';
        o_ack32:            out std_logic;
        o_cbok:             out std_logic;
        i_burst:            in std_logic;

        -- Internal Signals
        i_refresh:          in std_logic;

        -- DRAM Interface Signals
        o_ma:               out std_logic_vector(11 downto 0);
        o_ras:              out std_logic_vector(7 downto 0);
        o_cas:              out std_logic_vector(3 downto 0);
        o_we:               out std_logic := '0';

        o_pagehit:          out std_logic := '0'
    );
end dram_controller;

architecture behavioral of dram_controller is
    signal cas_strobe_mode: strobe_mode_t := SEM_NONE;
    signal ras_strobe_mode: strobe_mode_t := SEM_NONE;

    signal ca: std_logic_vector(11 downto 0) := (others => '0');
    signal ra: std_logic_vector(11 downto 0) := (others => '0');
    signal bank: std_logic_vector(2 downto 0) := (others => '0');

    signal ma_eq_ra: boolean := false;
    signal ras_latch: std_logic := '0';

    type state_t is (
        S_IDLE,
        S_RA, S_WAITRAS, S_RAS,
        S_CA, S_WAITCAS, S_CAS,
        S_END,
        S_RFCAS, S_RFRAS, S_RFEND
    );
    signal state: state_t := S_IDLE;

    signal page_hit: boolean := false;
    signal prev_page_valid: boolean := false;
    signal prev_page: std_logic_vector(11 downto 0) := (others => '0');

    signal bank_hit: boolean := false;
    signal prev_bank: std_logic_vector(2 downto 0);
    signal prev_bank_valid: boolean := false;

    signal addr_temp: std_logic_vector(25 downto 2) := (others => '0');
    signal burst_count: unsigned(1 downto 0) := (others => '0');

    type do_array_t is array(0 to 8) of std_logic_vector(7 downto 0);
    signal do_array: do_array_t;
    signal ack8_array: std_logic_vector(8 downto 0);

    signal abr0_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr1_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr2_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr3_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr4_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr5_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr6_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr7_data: std_logic_vector(7 downto 0) := (others => '0');

    signal dcr_data: std_logic_vector(7 downto 0) := (others => '0');
    signal dram_enable: boolean;
    signal dram_mux_type: std_logic_vector(2 downto 0);
    signal dram_trcd: boolean;
    signal dram_twr: boolean;
    signal dram_tras: boolean;

    signal sel_abr0: std_logic;
    signal sel_abr1: std_logic;
    signal sel_abr2: std_logic;
    signal sel_abr3: std_logic;
    signal sel_abr4: std_logic;
    signal sel_abr5: std_logic;
    signal sel_abr6: std_logic;
    signal sel_abr7: std_logic;
begin
    o_d <=
        do_array(0) or do_array(1) or do_array(2) or do_array(3) or
        do_array(4) or do_array(5) or do_array(6) or do_array(7) or do_array(8);
    o_ack8 <= or ack8_array;

    sel_abr0 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "000" else '0';
    register_abr0: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr0,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(0),
            o_ack8      => ack8_array(0),

            o_reg       => abr0_data
        );
    sel_abr1 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "001" else '0';
    register_abr1: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr1,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(1),
            o_ack8      => ack8_array(1),

            o_reg       => abr1_data
        );
    sel_abr2 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "010" else '0';
    register_abr2: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr2,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(2),
            o_ack8      => ack8_array(2),

            o_reg       => abr2_data
        );
    sel_abr3 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "011" else '0';
    register_abr3: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr3,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(3),
            o_ack8      => ack8_array(3),

            o_reg       => abr3_data
        );
    sel_abr4 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "100" else '0';
    register_abr4: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr4,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(4),
            o_ack8      => ack8_array(4),

            o_reg       => abr4_data
        );
    sel_abr5 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "101" else '0';
    register_abr5: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr5,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(5),
            o_ack8      => ack8_array(5),

            o_reg       => abr5_data
        );
    sel_abr6 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "110" else '0';
    register_abr6: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr6,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(6),
            o_ack8      => ack8_array(6),

            o_reg       => abr6_data
        );
    sel_abr7 <= '1' when i_sel_abr = '1' and i_a(2 downto 0) = "111" else '0';
    register_abr7: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_abr7,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(7),
            o_ack8      => ack8_array(7),

            o_reg       => abr7_data
        );
    register_dcr: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => i_sel_dcr,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(8),
            o_ack8      => ack8_array(8),

            o_reg       => dcr_data
        );
    dram_enable <= dcr_data(7) = '1';
    dram_mux_type <= dcr_data(6 downto 4);
    dram_trcd <= dcr_data(3) = '1';
    dram_twr <= dcr_data(1) = '1';
    dram_tras <= dcr_data(0) = '1';

    addr_temp(25 downto 4) <= i_a(25 downto 4);
    addr_temp(3 downto 2) <= std_logic_vector(unsigned(i_a(3 downto 2)) + burst_count);
    page_hit <= prev_page_valid and prev_page = ra;
    bank_hit <= prev_bank_valid and prev_bank = bank;

    o_ma <= ra when ma_eq_ra else ca;

    addr_mux: entity work.addr_mux
        port map (
            i_a             => addr_temp,
            o_ca            => ca,
            o_ra            => ra,
            i_mapping_mode  => dram_mux_type
        );

    ras_generator: entity work.ras_generator
        port map (
            i_rst         => i_rst,
            i_a           => i_a(27 downto 20),
            i_abr0        => abr0_data,
            i_abr1        => abr1_data,
            i_abr2        => abr2_data,
            i_abr3        => abr3_data,
            i_abr4        => abr4_data,
            i_abr5        => abr5_data,
            i_abr6        => abr6_data,
            i_abr7        => abr7_data,
            i_ras_latch   => ras_latch,
            i_strobe_mode => ras_strobe_mode,
            o_ras         => o_ras,
            o_bank        => bank
        );

    cas_generator: entity work.cas_generator
        port map (
            i_size        => i_size,
            i_a           => i_a(1 downto 0),
            i_strobe_mode => cas_strobe_mode,
            o_cas         => o_cas
        );

    process (i_clk, i_rst) is
    begin
        if i_rst = '1' or not dram_enable then
            cas_strobe_mode <= SEM_NONE;
            ras_strobe_mode <= SEM_NONE;
            ma_eq_ra <= false;
            ras_latch <= '0';
            state <= S_IDLE;
            prev_page <= (others => '0');
            prev_page_valid <= false;
            prev_bank <= (others => '0');
            prev_bank_valid <= false;
            burst_count <= (others => '0');

            o_ack32 <= '0';
            o_cbok <= '0';

            o_we <= '0';
            o_pagehit <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    cas_strobe_mode <= SEM_NONE;
                    burst_count <= (others => '0');
                    o_we <= '0';
                    o_ack32 <= '0';
                    o_cbok <= '0';

                    if i_refresh = '1' then
                        state <= S_RFCAS;
                    elsif i_select and (i_rd or i_wr) then
                        -- start access cycle
                        o_cbok <= '1';

                        o_pagehit <= '1' when page_hit else '0';
                        if page_hit then
                            -- page hit; skip row address
                            state <= S_CA;
                        else
                            state <= S_RA;
                        end if;
                    end if;
                when S_RA =>
                    -- setup row address
                    if bank_hit then
                        ras_strobe_mode <= SEM_NONE;
                    end if;
                    ma_eq_ra <= true;

                    prev_page <= ra;
                    prev_page_valid <= true;
                    prev_bank <= bank;
                    prev_bank_valid <= true;

                    if dram_tras then
                        state <= S_RAS;
                    else
                        -- wait a cycle if ras precharge delay is required
                        state <= S_WAITRAS;
                    end if;
                when S_WAITRAS =>
                    state <= S_RAS;
                when S_RAS =>
                    -- set ras
                    ras_strobe_mode <= SEM_SEL;
                    ras_latch <= '1';
                    state <= S_CA;
                when S_CA =>
                    -- setup column address
                    o_ack32 <= '0';
                    ras_latch <= '0';
                    ma_eq_ra <= false;
                    o_we <= i_wr;

                    -- wait a cycle if ras-to-cas delay is required
                    state <= S_CAS when dram_trcd else S_WAITCAS;
                when S_WAITCAS =>
                    state <= S_CAS;
                when S_CAS =>
                    -- set cas and acknowledge
                    cas_strobe_mode <= SEM_SEL when i_wr else SEM_ALL;
                    o_ack32 <= '1';

                    -- wait until cycle end
                    if not (i_rd or i_wr) then
                        cas_strobe_mode <= SEM_NONE;
                        o_we <= '0';
                        state <= S_END;
                    end if;

                    -- do burst cycle
                    if i_burst then
                        if burst_count /= 3 then
                            burst_count <= burst_count + 1;
                            state <= S_CA;
                        else
                            o_cbok <= '0';
                            state <= S_END;
                        end if;
                    end if;
                when S_END =>
                    -- acknowledge cycle
                    o_ack32 <= '0';
                    o_we <= '0';
                    cas_strobe_mode <= SEM_NONE;
                    state <= S_IDLE;
                when S_RFCAS =>
                    cas_strobe_mode <= SEM_ALL;
                    ras_latch <= '1';
                    state <= S_RFRAS;
                when S_RFRAS =>
                    ras_strobe_mode <= SEM_ALL;
                    ras_latch <= '0';
                    if i_refresh = '0' then
                        state <= S_RFEND;
                    end if;
                when S_RFEND =>
                    cas_strobe_mode <= SEM_NONE;
                    ras_strobe_mode <= SEM_NONE;
                    state <= S_IDLE;
            end case;
        end if;
    end process;
end behavioral;
