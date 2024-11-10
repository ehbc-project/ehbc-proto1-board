library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity timer is
    port (
        i_rst:          in std_logic;
        i_clk:          in std_logic;
        i_sel_tcr:      in std_logic;

        -- Internal Bus Signals
        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_a:            in std_logic_vector(3 downto 0);
        i_d:            in std_logic_vector(7 downto 0);
        o_d:            out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';

        -- Internal Signals
        o_irq:          out std_logic_vector(2 downto 0)
    );
end timer;

architecture behavioral of timer is
    signal sel_tcra: std_logic;
    signal sel_tcrb: std_logic;
    signal sel_tcrc: std_logic;

    type do_array_t is array(0 to 2) of std_logic_vector(7 downto 0);
    signal do_array: do_array_t;
    signal ack8_array: std_logic_vector(2 downto 0) := (others => '0');
begin
    o_d <= do_array(0) or do_array(1) or do_array(2);
    o_ack8 <= or ack8_array;

    sel_tcra <= '1' when i_sel_tcr = '1' and i_a(3 downto 2) = "00" else '0';
    timer_channela: entity work.timer_channel
        port map (
            i_rst       => i_rst,
            i_clk       => i_clk,
            i_sel_tcr   => sel_tcra,
            i_rd        => i_rd,
            i_wr        => i_wr,
            i_a         => i_a(1 downto 0),
            i_d         => i_d,
            o_d         => do_array(0),
            o_ack8      => ack8_array(0),
            o_irq       => o_irq(0)
        );
    sel_tcrb <= '1' when i_sel_tcr = '1' and i_a(3 downto 2) = "01" else '0';
    timer_channelb: entity work.timer_channel
        port map (
            i_rst       => i_rst,
            i_clk       => i_clk,
            i_sel_tcr   => sel_tcrb,
            i_rd        => i_rd,
            i_wr        => i_wr,
            i_a         => i_a(1 downto 0),
            i_d         => i_d,
            o_d        => do_array(1),
            o_ack8      => ack8_array(1),
            o_irq       => o_irq(1)
        );
    sel_tcrc <= '1' when i_sel_tcr = '1' and i_a(3 downto 2) = "10" else '0';
    timer_channelc: entity work.timer_channel
        port map (
            i_rst       => i_rst,
            i_clk       => i_clk,
            i_sel_tcr   => sel_tcrc,
            i_rd        => i_rd,
            i_wr        => i_wr,
            i_a         => i_a(1 downto 0),
            i_d         => i_d,
            o_d         => do_array(2),
            o_ack8      => ack8_array(2),
            o_irq       => o_irq(2)
        );
end behavioral;
