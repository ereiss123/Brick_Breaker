
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
        rand       : out unsigned(8 downto 0)

    );

end entity psuedorandom_gen;

architecture rtl of psuedorandom_gen is

    signal LFSR : unsigned(15 downto 0) := (others => '0'); -- 16-bit LFSR
    -- signal rand : unsigned(7 downto 0) := (others => '0'); -- random number

begin
    -- primitive polynomial x^15+x^13+x^12+x^10+1
    create_rand : process (MAX10_CLK1_50, rst_l)
    begin
        if rst_l = '0' then
            LFSR <= seed;
            rand <= seed(8 downto 0);
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
                    rand <= LFSR(8 downto 0);
                end if;
            end if;
        end if;
    end process;

end architecture rtl;