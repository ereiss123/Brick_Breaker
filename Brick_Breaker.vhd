library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.types.all;

entity Brick_Breaker is
    port (
        -- CLOCK
        ADC_CLK_10       : in std_logic;
        MAX10_CLK1_50    : in std_logic;
        MAX10_CLK2_50    : in std_logic;

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
        SW               : in std_logic_vector(9 downto 0);

        -- VGA
        VGA_B            : out std_logic_vector(3 downto 0);
        VGA_G            : out std_logic_vector(3 downto 0);
        VGA_HS           : out std_logic;
        VGA_R            : out std_logic_vector(3 downto 0);
        VGA_VS           : out std_logic;

        -- Accelerometer
        GSENSOR_CS_N     : out std_logic;
        GSENSOR_INT      : in std_logic_vector(2 downto 1);
        GSENSOR_SCLK     : out std_logic;
        GSENSOR_SDI      : inout std_logic;
        GSENSOR_SDO      : inout std_logic;

        -- Arduino
        ARDUINO_IO       : inout std_logic_vector(15 downto 0);
        ARDUINO_RESET_N  : inout std_logic
    );
end entity Brick_Breaker;

architecture Behavioral of Brick_Breaker is
    -- REG/WIRE declarations can be added here if needed
    component VGA_controller 
        port(

        );
    
        component VGA_PLL
            PORT
            (
                areset		: IN STD_LOGIC  := '0';
                inclk0		: IN STD_LOGIC  := '0';
                c0		: OUT STD_LOGIC ;
                locked		: OUT STD_LOGIC 
            );
            end component;

begin
    -- Structural coding (connections go here if needed)

    VGA_controller_inst VGA_controller(
        -- Connections go here
    );
    PLL_inst : VGA_PLL PORT MAP 
(
    areset	 => areset_sig,
    inclk0	 => MAX10_CLK1_50,
    c0	 => c0_sig,
    locked	 => locked_sig
);
end architecture Behavioral;
