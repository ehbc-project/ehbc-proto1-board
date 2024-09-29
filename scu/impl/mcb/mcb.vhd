library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.common.all;

entity mcb is
    port (
        i_rst: in std_logic;
        i_clk: in std_logic;

        i_en_ram: in std_logic;
        i_en_dcr: in std_logic;
        i_en_abr: in std_logic;

        i_size: in std_logic_vector(1 downto 0);
        i_rd: in std_logic;
        i_wr: in std_logic;
        i_a: in std_logic_vector(27 downto 0);
        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');

        o_ack8: out std_logic;
        o_ack32: out std_logic;

        i_burst: in std_logic;

        o_ma: out std_logic_vector(11 downto 0);
        o_ras: out std_logic_vector(7 downto 0);
        o_cas: out std_logic_vector(3 downto 0);
        o_we: out std_logic := '0';

        i_refresh: in std_logic;
        o_pagehit: out std_logic := '0'
    );
end mcb;

architecture behavioral of mcb is
    signal cas_strobe_mode: strobe_mode_t := SEM_NONE;
    signal ras_strobe_mode: strobe_mode_t := SEM_NONE;

    signal ca: std_logic_vector(11 downto 0) := (others => '0');
    signal ra: std_logic_vector(11 downto 0) := (others => '0');

    signal ma_eq_ra: boolean := false;
    signal ras_latch: std_logic := '0';

    type state_t is (
        S_IDLE,
        S_RA, S_WAITRAS, S_RAS,
        S_CA, S_WAITCAS, S_CAS,
        S_END
    );
    signal state: state_t := S_IDLE;

    type refresh_state_t is (RS_IDLE, RS_PEND, RS_CAS, RS_RAS, RS_END);
    signal refresh_state: refresh_state_t := RS_IDLE;

    signal page_hit: boolean := false;
    signal prev_page_valid: boolean := false;
    signal prev_page: std_logic_vector(11 downto 0) := (others => '0');

    signal bank_hit: boolean := false;
    signal bank: std_logic_vector(2 downto 0);
    signal prev_bank: std_logic_vector(2 downto 0);
    signal prev_bank_valid: boolean := false;

    signal delay_counter: integer range 0 to 65535 := 0;

    signal addr_temp: std_logic_vector(25 downto 2) := (others => '0');
    signal burst_addr: unsigned(3 downto 2) := (others => '0');
    signal burst: boolean := false;

    signal dcr_data: std_logic_vector(7 downto 0) := (others => '0');
    signal abr0_data: unsigned(7 downto 0);
    signal abr1_data: unsigned(7 downto 0);
    signal abr2_data: unsigned(7 downto 0);
    signal abr3_data: unsigned(7 downto 0);
    signal abr4_data: unsigned(7 downto 0);
    signal abr5_data: unsigned(7 downto 0);
    signal abr6_data: unsigned(7 downto 0);
    signal abr7_data: unsigned(7 downto 0);
    signal mapping_mode: std_logic_vector(2 downto 0);
    signal ras_cas_delay: std_logic;
    signal write_cas_width: std_logic;
    signal ras_precharge_time: std_logic;

    signal ack8_dcr: std_logic;
    signal ack8_abr: std_logic;
begin
    addr_temp(25 downto 4) <= i_a(25 downto 4);
    addr_temp(3 downto 2) <= std_logic_vector(burst_addr) when i_burst else i_a(3 downto 2);
    page_hit <= prev_page_valid and prev_page = ra;
    bank_hit <= prev_bank_valid and prev_bank = bank;

    o_ma <= ra when ma_eq_ra else ca;

    mapping_mode <= dcr_data(6 downto 4);
    ras_cas_delay <= dcr_data(3);
    write_cas_width <= dcr_data(1);
    ras_precharge_time <= dcr_data(0);

    o_ack8 <= ack8_dcr or ack8_abr;

    dcr: entity work.reg
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_dcr,
            i_rd   => i_rd,
            i_wr   => i_wr,
            o_ack8 => ack8_dcr,
            i_d    => i_d,
            o_d    => o_d,
            o_reg  => dcr_data
        );

    abr: entity work.abr
        port map (
            i_clk  => i_clk,
            i_rst  => i_rst,
            i_en   => i_en_abr,
            i_rd   => i_rd,
            i_wr   => i_wr,
            i_a    => i_a(2 downto 0),
            o_ack8 => ack8_abr,
            i_d    => i_d,
            o_d    => o_d,
            o_abr0 => abr0_data,
            o_abr1 => abr1_data,
            o_abr2 => abr2_data,
            o_abr3 => abr3_data,
            o_abr4 => abr4_data,
            o_abr5 => abr5_data,
            o_abr6 => abr6_data,
            o_abr7 => abr7_data
        );

    addr_mux: entity work.addr_mux
        port map (
            i_a => addr_temp,
            o_ca => ca,
            o_ra => ra,
            i_mapping_mode => mapping_mode
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
        if i_rst = '1' then
            state <= S_IDLE;
            refresh_state <= RS_IDLE;
            prev_page_valid <= false;
            prev_bank_valid <= false;
            prev_page <= (others => '0');
            cas_strobe_mode <= SEM_NONE;
            ras_strobe_mode <= SEM_NONE;
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    o_ack32 <= '0';
                    cas_strobe_mode <= SEM_NONE;
                    o_we <= '0';

                    -- start access cycle
                    if (refresh_state = RS_IDLE or refresh_state = RS_END) and (i_en_ram and (i_rd or i_wr)) = '1' then
                        if i_burst = '1' and not burst then
                            -- begin burst cycle
                            burst_addr <= unsigned(i_a(3 downto 2));
                            burst <= true;
                        end if;

                        if page_hit then
                            -- page hit; skip row address
                            o_pagehit <= '1';
                            state <= S_CA;
                        else
                            ma_eq_ra <= true;
                            o_pagehit <= '0';
                            state <= S_RA;
                        end if;
                    else
                        o_pagehit <= '0';
                    end if;
                when S_RA =>
                    -- setup row address
                    if bank_hit then
                        ras_strobe_mode <= SEM_NONE;
                    end if;
                    prev_page_valid <= true;
                    prev_page <= ra;
                    prev_bank <= bank;
                    prev_bank_valid <= true;

                    if ras_precharge_time then
                        ras_strobe_mode <= SEM_SEL;
                        state <= S_RAS;
                        ras_latch <= '1';
                    else
                        -- wait if ras precharge delay is required
                        state <= S_WAITRAS;
                    end if;
                when S_WAITRAS =>
                    ras_strobe_mode <= SEM_SEL;
                    ras_latch <= '1';
                    state <= S_RAS;
                when S_RAS =>
                    -- set ras
                    state <= S_CA;
                when S_CA =>
                    ras_latch <= '0';
                    ma_eq_ra <= false;
                    o_we <= i_wr;
                    cas_strobe_mode <= SEM_SEL when i_wr else SEM_ALL;

                    -- wait if ras-to-cas delay is required
                    state <= S_CAS when ras_cas_delay else S_WAITCAS;
                when S_WAITCAS =>
                    state <= S_CAS;
                when S_CAS =>
                    -- set cas
                    o_ack32 <= '1';
                    if (not i_rd and not i_wr) then
                        o_ack32 <= '0';
                        cas_strobe_mode <= SEM_NONE;
                        o_we <= '0';
                        state <= S_END;
                    end if;
                    if i_burst then
                        state <= S_END;
                    end if;
                when S_END =>
                    -- acknowledge cycle
                    if i_wr and write_cas_width then
                        cas_strobe_mode <= SEM_NONE;
                    end if;
                    if i_burst then
                        o_ack32 <= '0';
                        o_we <= '0';
                        cas_strobe_mode <= SEM_NONE;
                        burst_addr <= burst_addr + 1;
                    elsif burst then
                        -- end burst cycle
                        burst <= false;
                    end if;
                    state <= S_IDLE;
            end case;

            case refresh_state is
                when RS_IDLE =>
                    if i_refresh = '1' then
                        refresh_state <= RS_PEND;
                    end if;
                when RS_PEND =>
                    if state = S_IDLE then
                        ras_strobe_mode <= SEM_NONE;
                        cas_strobe_mode <= SEM_NONE;
                        refresh_state <= RS_CAS;
                    end if;
                when RS_CAS =>
                    cas_strobe_mode <= SEM_ALL;
                    ras_strobe_mode <= SEM_ALL;
                    delay_counter <= 7000;
                    refresh_state <= RS_RAS;
                    ras_latch <= '1';
                when RS_RAS =>
                    ras_latch <= '0';
                    if delay_counter = 0 then
                        -- invalidate page and bank buffer
                        prev_page_valid <= false;
                        prev_bank_valid <= false;
                        cas_strobe_mode <= SEM_NONE;
                        refresh_state <= RS_END;
                    end if;
                when RS_END =>
                    ras_strobe_mode <= SEM_NONE;
                    if i_refresh = '0' then
                        refresh_state <= RS_IDLE;
                    end if;
            end case;

            if delay_counter /= 0 then
                delay_counter <= delay_counter - 1;
            end if;
        end if;
    end process;
end behavioral;
