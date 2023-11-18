library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Brick_Breaker_TB is
end entity;

architecture test of  Brick_Breaker_TB is
    component Brick_Breaker
        port(
            -- CLOCK
            -- ADC_CLK_10       : in std_logic;
            MAX10_CLK1_50    : in std_logic;
            -- MAX10_CLK2_50    : in std_logic;

            -- SDRAM
            DRAM_ADDR        : out std_logic_vector(12 downto 0);
            DRAM_BA          : out std_logic_vector(1 downto 0);
            DRAM_CAS_N       : out std_logic;
            DRAM_CKE         : out std_logic;
            DRAM_CLK         : out std_logic;
            DRAM_CS_N        : out std_logic;
            DRAM_DQ          : inout std_logic_vector(15 downto 0);
            DRAM_LDQM        : out std_logic;
            DRAM_RAS_N       : out std_logic;
            DRAM_UDQM        : out std_logic;
            DRAM_WE_N        : out std_logic;

            -- SEG7
            HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);

            -- KEY
            KEY              : in std_logic_vector(1 downto 0);

            -- LED
            LEDR             : out std_logic_vector(9 downto 0);

            -- SW
            -- SW               : in std_logic_vector(9 downto 0);

            -- VGA
            VGA_B            : out std_logic_vector(3 downto 0);
            VGA_G            : out std_logic_vector(3 downto 0);
            VGA_HS           : out std_logic;
            VGA_R            : out std_logic_vector(3 downto 0);
            VGA_VS           : out std_logic;

            -- Accelerometer
            GSENSOR_CS_N     : out std_logic;
            -- GSENSOR_INT      : in std_logic_vector(2 downto 1);
            GSENSOR_SCLK     : out std_logic;
            GSENSOR_SDI      : inout std_logic;
            GSENSOR_SDO      : inout std_logic;

            -- Arduino
            ARDUINO_IO       : inout std_logic_vector(15 downto 0);
            ARDUINO_RESET_N  : inout std_logic
        );
    end component;

    signal MAX10_CLK1_50 : std_logic := '0';
    signal KEY           : std_logic_vector(1 downto 0) := (others => '0');
    signal VGA_R         : std_logic_vector(3 downto 0) := (others => '0');
    signal VGA_G         : std_logic_vector(3 downto 0) := (others => '0');
    signal VGA_B         : std_logic_vector(3 downto 0) := (others => '0');
    signal VGA_HS        : std_logic := '0';
    signal VGA_VS        : std_logic := '0';
begin

    Brick_Breaker_inst : Brick_Breaker
    port map(
        -- ADC_CLK_10       => open,
        MAX10_CLK1_50    => MAX10_CLK1_50,
        -- MAX10_CLK2_50    => open,

        DRAM_ADDR        => open,
        DRAM_BA          => open,
        DRAM_CAS_N       => open,
        DRAM_CKE         => open,
        DRAM_CLK         => open,
        DRAM_CS_N        => open,
        DRAM_DQ          => open,
        DRAM_LDQM        => open,
        DRAM_RAS_N       => open,
        DRAM_UDQM        => open,
        DRAM_WE_N        => open,

        HEX0             => open,
        HEX1             => open,
        HEX2             => open,
        HEX3             => open,
        HEX4             => open,
        HEX5             => open,

        KEY              => KEY,

        LEDR             => open,

        -- SW               => open,

        VGA_B            => VGA_B,
        VGA_G            => VGA_G,
        VGA_HS           => VGA_HS,
        VGA_R            => VGA_R,
        VGA_VS           => VGA_VS,

        GSENSOR_CS_N     => open,
        -- GSENSOR_INT      => open,
        GSENSOR_SCLK     => open,
        GSENSOR_SDI      => open,
        GSENSOR_SDO      => open,

        ARDUINO_IO       => open,
        ARDUINO_RESET_N  => open
    );

    
    MAX10_CLK1_50 <= not MAX10_CLK1_50 after 10 ns;

    stimuli : process
    begin
        KEY <= "00";
        wait for 100 ns;
        KEY <= "11";
        wait;
    end process;
end architecture test;