library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity cpu_interface is
    port (
        i_clk:              in std_logic;
        i_nrst:             in std_logic;

        -- Processor Interface Signals
        i_nas:              in std_logic;
        i_nds:              in std_logic;
        i_r_nw:             in std_logic;
        o_ndsack:           out std_logic_vector(1 downto 0) := (others => 'Z');
        o_nsterm:           out std_logic := 'Z';
        o_nberr:            out std_logic := 'Z';
        i_fc:               in std_logic_vector(2 downto 0);
        i_a:                in std_logic_vector(31 downto 0);
        io_d:               inout std_logic_vector(7 downto 0) := (others => 'Z');
        i_ncbreq:           in std_logic;
        o_ncback:           out std_logic := 'Z';

        -- Internal Bus Signals
        o_rd:               out std_logic := '0';
        o_wr:               out std_logic := '0';
        i_ack8:             in std_logic;
        i_ack16:            in std_logic;
        i_ack32:            in std_logic;
        i_berr:             in std_logic;
        o_di:               out std_logic_vector(7 downto 0) := (others => '0');
        i_do:               in std_logic_vector(7 downto 0);
        i_cbok:             in std_logic;
        i_ci:               in std_logic;
        o_burst:            out std_logic := '0';

        -- Register Values
        i_cpu_enable_burst: in boolean
    );
end cpu_interface;

architecture behavioral of cpu_interface is
    signal rd: std_logic := '0';
    signal wr: std_logic := '0';
begin
    o_rd <= rd;
    o_wr <= wr;

    rd <= not i_nds and i_r_nw;
    wr <= not i_nds and not i_r_nw;

    o_di <= io_d;

    o_ndsack <= DSACK_8 when i_ack8 = '1' else DSACK_16 when i_ack16 = '1' else DSACK_IDLE;
    o_nsterm <= '0' when i_ack32 = '1' else 'Z';
    o_nberr <= '0' when i_berr = '1' else 'Z';
    o_ncback <= '0' when o_burst else 'Z';

    process(i_clk, i_nrst) is
    begin
        if i_nrst = '0' then
            o_nberr <= 'Z';
            io_d <= (others => 'Z');
            o_ncback <= 'Z';

            o_burst <= '0';
        elsif rising_edge(i_clk) then
            if i_nas = '0' and i_nds = '0' and rd = '1' then
                io_d <= i_do;
            else
                io_d <= (others => 'Z');
            end if;

            o_burst <= '1' when i_cpu_enable_burst and i_cbok = '1' and i_ncbreq = '0' else '0';
        end if;
    end process;
end behavioral;
