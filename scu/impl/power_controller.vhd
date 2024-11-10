library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity power_controller is
    port (
        i_clk:          in std_logic;
        i_rst:          in std_logic;
        i_sel_pcr:      in std_logic;

        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_d:            in std_logic_vector(7 downto 0);
        o_d:            out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';

        i_psw:          in std_logic;
        o_pwroff:       out std_logic := '0';
        o_irq:          out std_logic := '0'
    );
end power_controller;

architecture behavioral of power_controller is
    signal pcr_data: std_logic_vector(5 downto 1) := (others => '0');
    signal psw_raise_nmi: std_logic;

    signal xferend: boolean := false;
begin
    psw_raise_nmi <= pcr_data(1);

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            pcr_data <= (others => '0');
            xferend <= false;
            o_pwroff <= '0';
            o_irq <= '0';
        elsif rising_edge(i_clk) then
            if i_sel_pcr = '1' and not xferend then
                if i_rd = '1' then
                    o_d(7 downto 6) <= (others => '0');
                    o_d(5 downto 1) <= pcr_data(5 downto 1);
                    o_d(0) <= i_psw;
                end if;
            
                if i_wr = '1' then
                    o_pwroff <= i_d(7);
                    if i_d(5) and not i_psw then
                        o_irq <= '0';
                    end if;
                    pcr_data <= i_d(5 downto 1);
                end if;

                if i_rd or i_wr then
                    o_ack8 <= '1';
                else
                    o_d <= (others => '0');
                    o_ack8 <= '0';
                    xferend <= true;
                end if;
            else
                o_d <= (others => '0');
                o_ack8 <= '0';
                xferend <= false;
            end if;

            if i_psw = '1' then
                if psw_raise_nmi then
                    o_pwroff <= '1';
                else
                    o_irq <= '1';
                end if;
            end if;
        end if;
    end process;
end behavioral;
