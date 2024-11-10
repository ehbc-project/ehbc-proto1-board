library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity timer_channel is
    port (
        i_rst:          in std_logic;
        i_clk:          in std_logic;
        i_sel_tcr:      in std_logic;

        -- Internal Bus Signals
        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_a:            in std_logic_vector(1 downto 0);
        i_d:            in std_logic_vector(7 downto 0);
        o_d:            out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';
        
        -- Internal Signals
        o_irq:          out std_logic
    );
end timer_channel;

architecture behavioral of timer_channel is
    type state_t is (S_IDLE, S_XFER, S_END);
    signal state: state_t := S_IDLE;

    signal tcr_data: std_logic_vector(23 downto 0) := (others => '0');
    signal timer_data: unsigned(23 downto 0) := (others => '0');

    signal tcr_mode: std_logic_vector(7 downto 0) := (others => '0');
    signal timer_enable_channel: boolean;
    signal timer_enable_irq: boolean;
    signal timer_mode: unsigned(1 downto 0);
begin
    timer_enable_channel <= tcr_mode(7) = '1';
    timer_enable_irq <= tcr_mode(6) = '1';
    timer_mode <= unsigned(tcr_mode(1 downto 0));

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            tcr_data <= (others => '0');
            tcr_mode <= (others => '0');

            o_d <= (others => '0');
            o_ack8 <= '0';
            o_irq <= '0';
        elsif rising_edge(i_clk) then
            if timer_enable_channel then
                if not (or timer_data) then
                    if timer_enable_irq then
                        o_irq <= '1';
                    end if;

                    case timer_mode is
                        when "00" =>
                            timer_data <= unsigned(tcr_data);
                        when "01" =>
                            tcr_mode(7) <= '0';
                        when "10" =>
                        when "11" =>
                        when others =>
                    end case;
                else
                    timer_data <= timer_data - 1;
                end if;
            end if;

            case state is
                when S_IDLE =>
                    o_d <= (others => '0');
                    o_ack8 <= '0';
                    if i_sel_tcr and (i_rd or i_wr) then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    case i_a is
                        when "00" =>
                            o_irq <= '0';
                            timer_data <= unsigned(tcr_data);
                            if i_rd then
                                o_d <= tcr_mode;
                            end if;
                            if i_wr then
                                tcr_mode <= i_d;
                            end if;
                        when "01" =>
                            if i_rd then
                                o_d <= std_logic_vector(timer_data(23 downto 16));
                            end if;
                            if i_wr then
                                tcr_data(23 downto 16) <= i_d;
                            end if;
                        when "10" =>
                            if i_rd then
                                o_d <= std_logic_vector(timer_data(15 downto 8));
                            end if;
                            if i_wr then
                                tcr_data(15 downto 8) <= i_d;
                            end if;
                        when "11" =>
                            if i_rd then
                                o_d <= std_logic_vector(timer_data(7 downto 0));
                            end if;
                            if i_wr then
                                tcr_data(7 downto 0) <= i_d;
                            end if;
                        when others =>
                    end case;
                    o_ack8 <= '1';
                    state <= S_END;
                when S_END =>
                    if not (i_rd or i_wr) then
                        o_d <= (others => '0');
                        o_ack8 <= '0';
                        state <= S_IDLE;
                    end if;
            end case;
        end if;
    end process;
end behavioral;
