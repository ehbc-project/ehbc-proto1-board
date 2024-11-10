library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity flash_controller is
    port (
        i_clk:          in std_logic;
        i_rst:          in std_logic;
        i_select:       in std_logic;
        i_sel_fcr:      in std_logic;

        -- Internal Bus Signals
        i_rd:           in std_logic;
        i_wr:           in std_logic;
        i_d:            in std_logic_vector(7 downto 0);
        o_d:            out std_logic_vector(7 downto 0) := (others => '0');
        o_ack8:         out std_logic := '0';
        o_ack16:        out std_logic := '0'
    );
end flash_controller;

architecture behavioral of flash_controller is
    type state_t is (S_IDLE, S_WAIT, S_XFER, S_END);
    signal wait_count: unsigned(2 downto 0) := (others => '0');
    signal state: state_t := S_IDLE;

    signal fcr_data: std_logic_vector(7 downto 0);
    signal flash_enable: boolean;
    signal flash_ws: unsigned(2 downto 0);
begin
    register_fcr: entity work.reg
        generic map (
            reset_value     => x"80"
        )
        port map (
            i_clk           => i_clk,
            i_rst           => i_rst,
            i_select        => i_sel_fcr,

            i_rd            => i_rd,
            i_wr            => i_wr,
            i_di            => i_d,
            o_do            => o_d,
            o_ack8          => o_ack8,

            o_reg           => fcr_data
        );
    flash_enable <= fcr_data(7) = '1';
    flash_ws <= unsigned(fcr_data(2 downto 0));

    process(i_clk, i_rst) is
    begin
        if i_rst = '1' then
            state <= S_IDLE;
            wait_count <= (others => '0');

            o_ack16 <= '0';
        elsif rising_edge(i_clk) then
            case state is
                when S_IDLE =>
                    o_ack16 <= '0';
                    if i_select and (i_rd or i_wr) then
                        wait_count <= flash_ws - 1;
                        state <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if wait_count = 0 then
                        state <= S_XFER;
                    end if;
                when S_XFER =>
                    o_ack16 <= '1';
                    state <= S_END;
                when S_END =>
                    if not (i_rd or i_wr) then
                        o_ack16 <= '0';
                        state <= S_IDLE;
                    end if;
            end case;
            
            if wait_count /= 0 then
                wait_count <= wait_count - 1;
            end if;
        end if;
    end process;
end behavioral;
