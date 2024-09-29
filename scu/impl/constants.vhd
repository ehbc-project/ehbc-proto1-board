library ieee;
use ieee.std_logic_1164.all;

package constants is
    -- M68k Constants
    constant FC_USERDATA: std_logic_vector(2 downto 0) := "001";
    constant FC_USERPROG: std_logic_vector(2 downto 0) := "010";
    constant FC_SUPERDATA: std_logic_vector(2 downto 0) := "101";
    constant FC_SUPERPROG: std_logic_vector(2 downto 0) := "110";
    constant FC_CPUSPACE: std_logic_vector(2 downto 0) := "111";

    constant INITVEC_SP: std_logic_vector(31 downto 0) := x"00000000";
    constant INITVEC_PC: std_logic_vector(31 downto 0) := x"FD000000";

    constant SIZE_8: std_logic_vector(1 downto 0) := "01";
    constant SIZE_16: std_logic_vector(1 downto 0) := "10";
    constant SIZE_24: std_logic_vector(1 downto 0) := "11";
    constant SIZE_32: std_logic_vector(1 downto 0) := "00";

    constant DSACK_IDLE: std_logic_vector(1 downto 0) := "ZZ";
    constant DSACK_8: std_logic_vector(1 downto 0) := "Z0";
    constant DSACK_16: std_logic_vector(1 downto 0) := "0Z";
    constant DSACK_32: std_logic_vector(1 downto 0) := "00";
end constants;

package body constants is
end constants;
