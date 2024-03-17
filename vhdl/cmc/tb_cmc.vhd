library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_cmc is
end tb_cmc;

architecture test of tb_cmc is
    component cmc is
        port (
            CLK: in std_logic;
            RFSHCLK: in std_logic;
            ISACLK: in std_logic;
            nRST: in std_logic;
    
            -- Chip Select Signals
            nFPUCS: out std_logic;
            nROMCS: out std_logic;
            nDMAC0CS: out std_logic;
            nDMAC1CS: out std_logic;
            nMFP0CS: out std_logic;
            nMFP1CS: out std_logic;
            nFDCCS: out std_logic;
            nIDE0CS: out std_logic;
            nIDE1CS: out std_logic;
            nDUARTCS: out std_logic;
            nKBMSCS: out std_logic;
            nRTCCS: out std_logic;
            nVIDEOCS: out std_logic;
            nAUDIOCS: out std_logic;
    
            -- Processor Interface Signals
            nAS: in std_logic;
            nDS: in std_logic;
            R_nW: in std_logic;
            SIZE: in std_logic_vector(1 downto 0);
            nDSACK: out std_logic_vector(1 downto 0) := "ZZ";
            nSTERM: out std_logic := 'Z';
            FC: in std_logic_vector(2 downto 0);
            A: in std_logic_vector(31 downto 0);
            D: inout std_logic_vector(7 downto 0) := (others => 'Z');
            nCBREQ: in std_logic;
            nCBACK: out std_logic;
            nCI: out std_logic;
            nRD: out std_logic;
            nWR: out std_logic;
    
            -- DRAM Interface Signals
            MA: out std_logic_vector(11 downto 0) := (others => '0');
            nCAS: out std_logic_vector(3 downto 0) := (others => '1');
            nRAS: out std_logic_vector(7 downto 0) := (others => '1');
            nWE: out std_logic;
    
            -- Cache Interface Signals
            TD: inout std_logic_vector(15 downto 0);
            nCBE: out std_logic_vector(3 downto 0);
            nTOE: out std_logic;
            nCTWE: out std_logic;

            -- ISA Interface Signals

    
            -- Misc Signals
            nREFRESH: out std_logic;
            nPAGEHIT: out std_logic;
            nBOOT: out std_logic
        );
    end component;

    signal CLK: std_logic := '0';
    signal ISACLK: std_logic := '0';
    signal RFSHCLK: std_logic := '0';
    signal nRST: std_logic := '1';
    signal nROMCS: std_logic;
    signal nAS: std_logic := '1';
    signal nDS: std_logic := '1';
    signal R_nW: std_logic := '1';
    signal nDSACK: std_logic_vector(1 downto 0);
    signal nSTERM: std_logic;
    signal SIZE: std_logic_vector(1 downto 0) := (others => '0');
    signal FC: std_logic_vector(2 downto 0) := (others => '0');
    signal A: std_logic_vector(31 downto 0) := (others => '0');
    signal D: std_logic_vector(31 downto 0) := (others => 'Z');
    signal nCBREQ: std_logic := '1';
    signal nCBACK: std_logic;
    signal nCI: std_logic;
begin
    CLK <= not CLK after 20 ns;
    ISACLK <= not ISACLK after 125 ns;
    RFSHCLK <= not RFSHCLK after 69.8412 ns;

    I_CMC: cmc
        port map (
            CLK => CLK,
            ISACLK => ISACLK,
            RFSHCLK => RFSHCLK,
            nRST => nRST,
            nROMCS => nROMCS,
            nAS => nAS,
            nDS => nDS,
            R_nW => R_nW,
            SIZE => SIZE,
            nDSACK => nDSACK,
            nSTERM => nSTERM,
            FC => FC,
            A => A,
            D => D(31 downto 24),
            nCBREQ => nCBREQ,
            nCBACK => nCBACK,
            nCI => nCI
        );
    
    process
        file OUTFILE: text is out "io_data.txt";
        variable OUTLINE: line;

        type fc_type is (
            FC_USERDATA, FC_USERPROG,
            FC_SUPERDATA, FC_SUPERPROG,
            FC_CPUSPACE
        );

        -- ADDRESS SHOULD BE ALIGNED TO ACCESS SIZE
        procedure memory_read (
            FCODE: in fc_type;
            ADDR: in unsigned(31 downto 0);
            XFERSIZE: in integer range 1 to 4;
            CACHED: in boolean := false
        ) is
            variable BYTES_LEFT: integer range 0 to 4 := XFERSIZE;
            variable BYTES_READ: integer range 0 to 4 := 0;
            variable LWORDS_READ_CACHE: integer range 0 to 4 := 0;

            variable DATA: std_logic_vector(31 downto 0) := (others => 'Z');
        begin
            while BYTES_LEFT /= 0 loop
                wait until CLK = '1';  -- Beginning of S0
                D <= (others => 'Z');
                A <= std_logic_vector(ADDR + BYTES_READ);
                case FCODE is
                    when FC_USERDATA => FC <= "001";
                    when FC_USERPROG => FC <= "010";
                    when FC_SUPERDATA => FC <= "101";
                    when FC_SUPERPROG => FC <= "110";
                    when FC_CPUSPACE => FC <= "111";
                end case;
                R_nW <= '1';
                case BYTES_LEFT is
                    when 0 => 
                    when 1 => SIZE <= "01";
                    when 2 => SIZE <= "10";
                    when 3 => SIZE <= "11";
                    when 4 => SIZE <= "00";
                end case;
                
                wait until CLK = '0';  -- Beginning of S1
                nAS <= '0';
                nDS <= '0';
                if CACHED and BYTES_READ = 0 then
                    nCBREQ <= '0';
                end if;

                wait until CLK = '1';  -- Beginning of S2
    
                wait until CLK = '0';  -- Beginning of S3 (async)
                if nSTERM = 'Z' then
                    -- Asynchronous read cycle
                    while nDSACK = "ZZ" and nSTERM = 'Z' loop
                        wait until CLK = '1';
                        wait until CLK = '0';
                    end loop;
                end if;

                if nSTERM = '0' then
                    -- Beginning of S3 (sync)
                    if nCBACK = '0' and nCI = '1' then
                        -- Cache burst filling
                        while nCBACK = '0' and nCI = '1' and LWORDS_READ_CACHE < 3 loop
                            -- Beginning of S3 or S5 or S7 or S9
                            DATA := D;
                            
                            write(OUTLINE, string'("RDC"), LEFT, 4);
                            write(OUTLINE, FC, LEFT, 4);
                            hwrite(OUTLINE, std_logic_vector(ADDR + LWORDS_READ_CACHE * 4), LEFT, 12);
                            hwrite(OUTLINE, DATA, LEFT, 12);
                            writeline(OUTFILE, OUTLINE);
                            LWORDS_READ_CACHE := LWORDS_READ_CACHE + 1;

                            -- Force one wait state
                            wait until CLK = '1';
                            wait until CLK = '0';

                            while nSTERM = 'Z' loop
                                wait until CLK = '1';
                                wait until CLK = '0';
                            end loop;

                            -- Negate nCBREQ at S7
                            if LWORDS_READ_CACHE = 2 then
                                nCBREQ <= '1';
                            end if;
                        end loop;
                        BYTES_LEFT := 0;
                    else
                        DATA := D;
                        BYTES_LEFT := BYTES_LEFT - 4;
                        BYTES_READ := BYTES_READ + 4;
                    end if;
                    nAS <= '1';
                    nDS <= '1';
                else
                    -- Asynchronous read cycle
                    wait until CLK = '1';  -- Beginning of S4 / S2 (sync)
                    case nDSACK is
                        when "Z0" =>  -- 8-bit port
                            case BYTES_READ is
                                when 0 =>
                                    DATA(31 downto 24) := D(31 downto 24);
                                when 1 =>
                                    DATA(23 downto 16) := D(31 downto 24);
                                when 2 =>
                                    DATA(15 downto 8) := D(31 downto 24);
                                when 3 =>
                                    DATA(7 downto 0) := D(31 downto 24);
                                when others =>
                            end case;
                            BYTES_LEFT := BYTES_LEFT - 1;
                            BYTES_READ := BYTES_READ + 1;
                        when "0Z" =>  -- 16-bit port
                            case BYTES_READ is
                                when 0 =>
                                    DATA(15 downto 0) := D(31 downto 16);
                                when 2 =>
                                    DATA(31 downto 16) := D(31 downto 16);
                                when others =>
                            end case;
                            BYTES_LEFT := BYTES_LEFT - 2;
                            BYTES_READ := BYTES_READ + 2;
                        when "00" =>  -- 32-bit port
                            DATA := D;
                            BYTES_LEFT := BYTES_LEFT - 4;
                            BYTES_READ := BYTES_READ + 4;
                        when others =>
                            report "Unknown nDSACK signal" severity error;
                    end case;
                    
                    wait until CLK = '0';  -- Beginning of S5
                    nCBREQ <= '1';
                    nAS <= '1';
                    nDS <= '1';
                end if;
            end loop;

            write(OUTLINE, string'("RD"), LEFT, 4);
            write(OUTLINE, FC, LEFT, 4);
            hwrite(OUTLINE, std_logic_vector(ADDR), LEFT, 12);
            hwrite(OUTLINE, DATA, LEFT, 12);
            writeline(OUTFILE, OUTLINE);
        end procedure;

        procedure memory_write (
            FCODE: in fc_type;
            ADDR: in unsigned(31 downto 0);
            XFERSIZE: in integer range 1 to 4;
            DATA: in unsigned(31 downto 0)
        ) is
            variable BYTES_LEFT: integer range 0 to 4 := XFERSIZE;
            variable BYTES_WRITTEN: integer range 0 to 4 := 0;
        begin
            while BYTES_LEFT /= 0 loop
                wait until CLK = '1';  -- Beginning of S0
                D <= (others => 'Z');
                A <= std_logic_vector(ADDR + BYTES_WRITTEN);
                case FCODE is
                    when FC_USERDATA => FC <= "001";
                    when FC_USERPROG => FC <= "010";
                    when FC_SUPERDATA => FC <= "101";
                    when FC_SUPERPROG => FC <= "110";
                    when FC_CPUSPACE => FC <= "111";
                end case;
                R_nW <= '0';
                case BYTES_LEFT is
                    when 0 => 
                    when 1 => SIZE <= "01";
                    when 2 => SIZE <= "10";
                    when 3 => SIZE <= "11";
                    when 4 => SIZE <= "00";
                end case;

                wait until CLK = '0';  -- Beginning of S1
                nAS <= '0';

                wait until CLK = '1';  -- Beginning of S2
                case XFERSIZE is
                    when 1 =>
                        D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                        D(23 downto 16) <= std_logic_vector(DATA(7 downto 0));
                        D(15 downto 8) <= std_logic_vector(DATA(7 downto 0));
                        D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                    when 2 =>
                        if BYTES_WRITTEN mod 2 = 0 then
                            D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                            D(23 downto 16) <= std_logic_vector(DATA(15 downto 8));
                            D(15 downto 8) <= std_logic_vector(DATA(7 downto 0));
                            D(7 downto 0) <= std_logic_vector(DATA(15 downto 8));
                        else
                            D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                            D(23 downto 16) <= std_logic_vector(DATA(7 downto 0));
                            D(15 downto 8) <= std_logic_vector(DATA(15 downto 8));
                            D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                        end if;
                    when 3 =>
                        case BYTES_WRITTEN is
                            when 0 =>
                                D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                                D(23 downto 16) <= std_logic_vector(DATA(15 downto 8));
                                D(15 downto 8) <= std_logic_vector(DATA(23 downto 16));
                                D(7 downto 0) <= (others => '0');
                            when 1 =>
                                D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                                D(23 downto 16) <= std_logic_vector(DATA(7 downto 0));
                                D(15 downto 8) <= std_logic_vector(DATA(15 downto 8));
                                D(7 downto 0) <= std_logic_vector(DATA(23 downto 16));
                            when 2 =>
                                D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                                D(23 downto 16) <= std_logic_vector(DATA(15 downto 8));
                                D(15 downto 8) <= std_logic_vector(DATA(7 downto 0));
                                D(7 downto 0) <= std_logic_vector(DATA(15 downto 8));
                            when 3 =>
                                D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                                D(23 downto 16) <= std_logic_vector(DATA(7 downto 0));
                                D(15 downto 8) <= (others => '0');
                                D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                            when others =>
                                D <= (others => '0');
                        end case;
                    when 4 =>
                        case BYTES_WRITTEN is
                            when 0 =>
                                D <= std_logic_vector(DATA);
                            when 1 =>
                                D(31 downto 24) <= std_logic_vector(DATA(23 downto 16));
                                D(23 downto 16) <= std_logic_vector(DATA(15 downto 8));
                                D(15 downto 8) <= std_logic_vector(DATA(7 downto 0));
                                D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                            when 2 =>
                                D(31 downto 24) <= std_logic_vector(DATA(15 downto 8));
                                D(23 downto 16) <= std_logic_vector(DATA(7 downto 0));
                                D(15 downto 8) <= std_logic_vector(DATA(15 downto 8));
                                D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                            when 3 =>
                                D(31 downto 24) <= std_logic_vector(DATA(7 downto 0));
                                D(23 downto 16) <= (others => '0');
                                D(15 downto 8) <= std_logic_vector(DATA(7 downto 0));
                                D(7 downto 0) <= std_logic_vector(DATA(7 downto 0));
                            when others =>
                                D <= (others => '0');
                        end case;
                end case;

                if nSTERM = '0' then  -- No wait states
                    BYTES_LEFT := BYTES_LEFT - 4;
                    BYTES_WRITTEN := BYTES_WRITTEN + 4;
                    nAS <= '1';
                else
                    wait until CLK = '0';  -- Beginning of S3
                    nDS <= '0';

                    while nDSACK = "ZZ" and nSTERM = 'Z' loop
                        wait until CLK = '1';
                        wait until CLK = '0';
                    end loop;
    
                    if nSTERM = '0' then
                        BYTES_LEFT := BYTES_LEFT - 4;
                        BYTES_WRITTEN := BYTES_WRITTEN + 4;
                        nAS <= '1';
                        nDS <= '1';
                    else
                        case nDSACK is
                            when "Z0" =>  -- 8-bit port
                                BYTES_LEFT := BYTES_LEFT - 1;
                                BYTES_WRITTEN := BYTES_WRITTEN + 1;
                            when "0Z" =>  -- 16-bit port
                                BYTES_LEFT := BYTES_LEFT - 2;
                                BYTES_WRITTEN := BYTES_WRITTEN + 2;
                            when "00" =>  -- 32-bit port
                                BYTES_LEFT := BYTES_LEFT - 4;
                                BYTES_WRITTEN := BYTES_WRITTEN + 4;
                            when others =>
                                report "Unknown nDSACK signal" severity error;
                        end case;
                    end if;

                    wait until CLK = '1';  -- Beginning of S4
    
                    wait until CLK = '0';  -- Beginning of S5
                    nAS <= '1';
                    nDS <= '1';
                end if;
            end loop;

            write(OUTLINE, string'("WR"), LEFT, 4);
            write(OUTLINE, FC, LEFT, 4);
            hwrite(OUTLINE, std_logic_vector(ADDR), LEFT, 12);
            hwrite(OUTLINE, std_logic_vector(DATA), LEFT, 12);
            writeline(OUTFILE, OUTLINE);
        end procedure;
    begin
        write(OUTLINE, string'("OP  FC  ADDR        DATA"));
        writeline(OUTFILE, OUTLINE);

        loop
            -- Reset
            nRST <= '0';
            wait for 80 ns;
            nRST <= '1';

            -- Read boot vector
            memory_read(FC_SUPERPROG, x"00000000", 4);
            memory_read(FC_SUPERPROG, x"00000004", 4);
    
            -- Read some ROM data
            memory_read(FC_SUPERPROG, x"FFF00000", 4, true);
            memory_read(FC_SUPERPROG, x"FFF00004", 4);
            memory_read(FC_SUPERPROG, x"FFF00008", 4);
            memory_read(FC_SUPERPROG, x"FFF0000C", 4);
            memory_read(FC_SUPERPROG, x"FFF00010", 4, true);
            memory_read(FC_SUPERPROG, x"FFF00014", 4);
            memory_read(FC_SUPERPROG, x"FFF00018", 4);
            memory_read(FC_SUPERPROG, x"FFF0001C", 4);
    
            -- MUX_SCHEME = 1, BANK_SIZE = 1MiB, MODULE_COUNT = 4
            -- DUAL_BANK = true, REFRESH_CYCLE = 64T
            -- ROM_LATENCY = 1T
            memory_write(FC_SUPERDATA, x"FFEFFFF0", 4, x"D1804008");
    
            -- Read some more ROM data
            memory_read(FC_SUPERPROG, x"FFF00020", 4);
            memory_read(FC_SUPERPROG, x"FFF00024", 4);
            memory_read(FC_SUPERPROG, x"FFF00028", 4);
            memory_read(FC_SUPERPROG, x"FFF0002C", 4);
            memory_read(FC_SUPERPROG, x"FFF00030", 4);
            memory_read(FC_SUPERPROG, x"FFF00034", 4);
            memory_read(FC_SUPERPROG, x"FFF00038", 4);
            memory_read(FC_SUPERPROG, x"FFF0003C", 4);

            -- Page should not be changed
            memory_read (FC_SUPERDATA, x"00000000", 4);
            memory_read (FC_SUPERDATA, x"00000004", 4);
            memory_read (FC_SUPERDATA, x"00000FF8", 4);
            memory_read (FC_SUPERDATA, x"00000FFC", 4);
            memory_write(FC_SUPERDATA, x"00000FF8", 4, x"AA55AA55");
            memory_write(FC_SUPERDATA, x"00000FFC", 4, x"AA55AA55");

            -- Page should be changed, but bank should not be changed
            memory_read (FC_SUPERDATA, x"00031000", 4);
            memory_read (FC_SUPERDATA, x"00032004", 4);
            memory_read (FC_SUPERDATA, x"00033FF8", 4);
            memory_read (FC_SUPERDATA, x"00034FFC", 4);
            memory_write(FC_SUPERDATA, x"00035FF8", 4, x"AA55AA55");
            memory_write(FC_SUPERDATA, x"00036FFC", 4, x"AA55AA55");

            -- Bank should be changed
            memory_read(FC_SUPERDATA, x"0000E5F0", 4);
            memory_read(FC_SUPERDATA, x"0010E5F0", 4);
            memory_read(FC_SUPERDATA, x"0020E5F0", 4);
            memory_read(FC_SUPERDATA, x"0030E5F0", 4);
            memory_read(FC_SUPERDATA, x"0040E5F0", 4);
            memory_read(FC_SUPERDATA, x"0050E5F0", 4);
            memory_read(FC_SUPERDATA, x"0060E5F0", 4);
            memory_read(FC_SUPERDATA, x"0070E5F0", 4);

            -- DRAM burst reads
            memory_read(FC_SUPERDATA, x"0000FF00", 4, true);
            memory_read(FC_SUPERDATA, x"0000FF10", 4, true);
            memory_read(FC_SUPERDATA, x"0000FF20", 4, true);
            memory_read(FC_SUPERDATA, x"0000FF30", 4, true);

            -- Random reads and writes
            memory_read (FC_SUPERPROG, x"FFF0A020", 4);
            memory_read (FC_SUPERPROG, x"FFF0A038", 4);
            memory_read (FC_SUPERDATA, x"00531DBE", 4);
            memory_read (FC_SUPERDATA, x"0031B207", 4);
            memory_write(FC_SUPERDATA, x"002A1034", 4, x"0123ABCD");
            memory_read (FC_SUPERPROG, x"FFF0A02C", 4);
            memory_read (FC_SUPERPROG, x"FFF0A030", 4);
            memory_read (FC_SUPERPROG, x"FFF0A034", 4);
            memory_write(FC_SUPERDATA, x"00444ED9", 4, x"0123ABCD");
            memory_write(FC_SUPERDATA, x"0074D7E9", 4, x"0123ABCD");
            memory_read (FC_SUPERPROG, x"FFF0A03C", 4);
            memory_read (FC_SUPERPROG, x"FFF0A024", 4);
            memory_read (FC_SUPERDATA, x"006D61AE", 4);
            memory_read (FC_SUPERDATA, x"001D05A8", 4);
            memory_read (FC_SUPERPROG, x"FFF0A028", 4);
            memory_write(FC_SUPERDATA, x"000F1B09", 4, x"0123ABCD");
        end loop;
        wait;
    end process;
end test;
