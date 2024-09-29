library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity hptb is
    port (
        i_clk: in std_logic;
        i_rst: in std_logic;

        i_en_hptr: in std_logic;
        i_en_fcr: in std_logic;

        i_rd: in std_logic;
        i_wr: in std_logic;
        i_d: in std_logic_vector(7 downto 0);
        o_d: out std_logic_vector(7 downto 0) := (others => '0');
        
        o_ack8: out std_logic := '0';
        o_ack16: out std_logic := '0'
    );
end hptb;

architecture behavioral of hptb is
    signal hptcr0_data: std_logic_vector(7 downto 0) := (others => '0');
    signal hptcr1_data: std_logic_vector(7 downto 0) := (others => '0');
    signal hpt0dr_data: std_logic_vector(7 downto 0) := (others => '0');
    signal hpt1dr_data: std_logic_vector(7 downto 0) := (others => '0');
    signal hpt2dr_data: std_logic_vector(7 downto 0) := (others => '0');
begin
    hpt_channel0: entity work.hpt_channel
        port map (
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_enable => hptcr0_data(5),
            i_pause  => hptcr1_data(5),
            o_tick   => o_tick,
            i_data   => unsigned(hpt0dr_data)
        );
    hpt_channel1: entity work.hpt_channel
        port map (
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_enable => hptcr0_data(3),
            i_pause  => hptcr1_data(3),
            o_tick   => o_tick,
            i_data   => unsigned(hpt1dr_data)
        );
    hpt_channel2: entity work.hpt_channel
        port map (
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_enable => hptcr0_data(1),
            i_pause  => hptcr1_data(1),
            o_tick   => o_tick,
            i_data   => unsigned(hpt2dr_data)
        );
end behavioral;
