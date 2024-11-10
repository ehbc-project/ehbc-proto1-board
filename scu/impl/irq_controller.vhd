library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity irq_controller is
    port (
        i_clk:          in std_logic;
        i_rst:          in std_logic;
        i_sel_icr:      in std_logic;
        i_sel_iack:     in std_logic;

        -- Internal Bus Signals
        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_a:            in std_logic_vector(3 downto 0);
        i_d:            in std_logic_vector(7 downto 0);
        o_d:            out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';

        -- Internal Signals
        i_irq:          in std_logic_vector(23 downto 0);

        -- Processor Signals
        o_ipl:          out std_logic_vector(2 downto 0)
    );
end irq_controller;

architecture behavioral of irq_controller is
    type state_t is (S_IDLE, S_XFER, S_END);
    signal state: state_t := S_IDLE;

    type icr_data_t is array(0 to 11) of std_logic_vector(7 downto 0);
    signal icr_data: icr_data_t := (others => (others => '0'));

    type current_irq_array_t is array(1 to 7) of unsigned(4 downto 0);
    signal current_irq: current_irq_array_t := (others => (others => '0'));

    signal irq_inverted: std_logic_vector(23 downto 0);

    type do_array_t is array(0 to 12) of std_logic_vector(7 downto 0);
    signal do_array: do_array_t;
    signal ack8_array: std_logic_vector(12 downto 0);

    signal sel_icr0: std_logic;
    signal sel_icr1: std_logic;
    signal sel_icr2: std_logic;
    signal sel_icr3: std_logic;
    signal sel_icr4: std_logic;
    signal sel_icr5: std_logic;
    signal sel_icr6: std_logic;
    signal sel_icr7: std_logic;
    signal sel_icr8: std_logic;
    signal sel_icr9: std_logic;
    signal sel_icr10: std_logic;
    signal sel_icr11: std_logic;
begin
    o_d <=
        do_array(0) or do_array(1) or do_array(2) or do_array(3) or
        do_array(4) or do_array(5) or do_array(6) or do_array(7) or 
        do_array(8) or do_array(9) or do_array(10) or do_array(11) or 
        do_array(12);
    o_ack8 <= or ack8_array;

    sel_icr0 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0000" else '0';
    register_icr0: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr0,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(0),
            o_ack8      => ack8_array(0),

            o_reg       => icr_data(0)
        );
    sel_icr1 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0001" else '0';
    register_icr1: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr1,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(1),
            o_ack8      => ack8_array(1),

            o_reg       => icr_data(1)
        );
    sel_icr2 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0010" else '0';
    register_icr2: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr2,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(2),
            o_ack8      => ack8_array(2),

            o_reg       => icr_data(2)
        );
    sel_icr3 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0011" else '0';
    register_icr3: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr3,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(3),
            o_ack8      => ack8_array(3),

            o_reg       => icr_data(3)
        );
    sel_icr4 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0100" else '0';
    register_icr4: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr4,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(4),
            o_ack8      => ack8_array(4),

            o_reg       => icr_data(4)
        );
    sel_icr5 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0101" else '0';
    register_icr5: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr5,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(5),
            o_ack8      => ack8_array(5),

            o_reg       => icr_data(5)
        );
    sel_icr6 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0110" else '0';
    register_icr6: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr6,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(6),
            o_ack8      => ack8_array(6),

            o_reg       => icr_data(6)
        );
    sel_icr7 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "0111" else '0';
    register_icr7: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr7,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(7),
            o_ack8      => ack8_array(7),

            o_reg       => icr_data(7)
        );
    sel_icr8 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "1000" else '0';
    register_icr8: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr8,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(8),
            o_ack8      => ack8_array(8),

            o_reg       => icr_data(8)
        );
    sel_icr9 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "1001" else '0';
    register_icr9: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr9,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(9),
            o_ack8      => ack8_array(9),

            o_reg       => icr_data(9)
        );
    sel_icr10 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "1010" else '0';
    register_icr10: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr10,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(10),
            o_ack8      => ack8_array(10),

            o_reg       => icr_data(10)
        );
    sel_icr11 <= '1' when i_sel_icr = '1' and i_a(3 downto 0) = "1011" else '0';
    register_icr11: entity work.reg
        port map (
            i_clk       => i_clk,
            i_rst       => i_rst,
            i_select    => sel_icr11,

            i_rd        => i_rd,
            i_wr        => i_wr,
            i_di        => i_d,
            o_do        => do_array(11),
            o_ack8      => ack8_array(11),

            o_reg       => icr_data(11)
        );

    process(i_clk, i_rst) is
        variable current_ipl: unsigned(2 downto 0);
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            do_array(12) <= (others => '0');
            ack8_array(12) <= '0';
            current_irq <= (others => (others => '0'));
            irq_inverted <= (others => '0');
        elsif rising_edge(i_clk) then
            current_ipl := "000";
            for i in 0 to 11 loop
                irq_inverted(i * 2) <= i_irq(i * 2) when icr_data(i)(3) = '0' else not i_irq(i * 2);
                if irq_inverted(i * 2) and (or icr_data(i)(2 downto 0)) then
                    current_irq(to_integer(unsigned(icr_data(i)(2 downto 0)))) <= to_unsigned(i * 2, 5);

                    if current_ipl < unsigned(icr_data(i)(2 downto 0)) then
                        current_ipl := unsigned(icr_data(i)(2 downto 0));
                    end if;
                end if;

                irq_inverted(i * 2 + 1) <= i_irq(i * 2 + 1) when icr_data(i)(7) = '0' else not i_irq(i * 2 + 1);
                if irq_inverted(i * 2 + 1) and (or icr_data(i)(6 downto 4)) then
                    current_irq(to_integer(unsigned(icr_data(i)(6 downto 4)))) <= to_unsigned(i * 2 + 1, 5);

                    if current_ipl < unsigned(icr_data(i)(6 downto 4)) then
                        current_ipl := unsigned(icr_data(i)(6 downto 4));
                    end if;
                end if;
            end loop;
            o_ipl <= std_logic_vector(current_ipl);

            case state is
                when S_IDLE =>
                    do_array(12) <= (others => '0');
                    ack8_array(12) <= '0';
                    if i_sel_iack and i_rd then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    do_array(12) <= std_logic_vector("000" & current_irq(to_integer(unsigned(i_a(3 downto 1)))) + 64);
                    ack8_array(12) <= '1';
                    state <= S_END;
                when S_END =>
                    if not (i_rd or i_wr) then
                        ack8_array(12) <= '0';
                        state <= S_IDLE;
                    end if;
            end case;
        end if;
    end process;
end behavioral;
