
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psuedorandom_gen is
    generic
    (
        seed : unsigned(15 downto 0) := X"B480"
    );
    port
    (

        --	//////////// CLOCK //////////
        MAX10_CLK1_50 : in STD_LOGIC;

        --	//////////// KEY //////////
        -- KEY : in STD_LOGIC_VECTOR(1 downto 0)
        rst_l      : in STD_LOGIC;
        gen_button : in STD_LOGIC;
        rand       : out unsigned(7 downto 0)

    );

end entity psuedorandom_gen;

architecture rtl of psuedorandom_gen is

    -- signal rst_l : STD_LOGIC := '0'; -- active low reset
    -- signal gen_button : STD_LOGIC := '0'; -- generate random number

    -- Create a look up table for the 7-segment display
    -- type LUT is array(15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);

    -- -- 7-segment display look up table. Not to flip bits. 7 segment display is active low.
    -- signal seven_seg : LUT := (not(X"71"), not(X"79"), not(X"5E"), not(X"58"), not(X"7C"), not(X"77"), X"90", X"80", X"F8", X"82", X"92", X"99", X"B0", X"A4", X"F9", X"C0");

    signal LFSR : unsigned(15 downto 0) := (others => '0'); -- 16-bit LFSR
    -- signal rand : unsigned(7 downto 0) := (others => '0'); -- random number

begin
    -- assign_buttons : process (KEY)
    -- begin
    --     rst_l <= KEY(0);
    --     gen_button <= KEY(1);
    -- end process;

    -- primitive polynomial x^15+x^13+x^12+x^10+1
    create_rand : process (MAX10_CLK1_50, KEY)
    begin
        if rst_l = '0' then
            LFSR <= seed;
            rand <= seed(7 downto 0);
        else
            if rising_edge(MAX10_CLK1_50) then
                LFSR(0) <= LFSR(15) xor LFSR(13) xor LFSR(12) xor LFSR(10);
                LFSR(1) <= LFSR(0);
                LFSR(2) <= LFSR(1);
                LFSR(3) <= LFSR(2);
                LFSR(4) <= LFSR(3);
                LFSR(5) <= LFSR(4);
                LFSR(6) <= LFSR(5);
                LFSR(7) <= LFSR(6);
                LFSR(8) <= LFSR(7);
                LFSR(9) <= LFSR(8);
                LFSR(10) <= LFSR(9);
                LFSR(11) <= LFSR(10);
                LFSR(12) <= LFSR(11);
                LFSR(13) <= LFSR(12);
                LFSR(14) <= LFSR(13);
                LFSR(15) <= LFSR(14);
                if gen_button = '0' then
                    rand <= LFSR(7 downto 0);
                end if;
            end if;
        end if;
    end process;

end architecture rtl;