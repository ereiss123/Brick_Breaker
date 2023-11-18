library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library work;
use work.types.all;

entity Brick_Breaker is
    port (
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
end entity Brick_Breaker;

architecture Behavioral of Brick_Breaker is
    -- Component declaration
    component VGA_controller 
        port(
            -- FPGA side
            clk : in std_logic;
            rst_l : in std_logic; 
            R : in std_logic_vector(3 downto 0);
            G : in std_logic_vector(3 downto 0);
            B : in std_logic_vector(3 downto 0);
            request_data : out std_logic;
            current_line : out unsigned(9 downto 0);
            data_pos : out unsigned(9 downto 0);

            -- Monitor side
            VGA_B : out std_logic_vector(3 downto 0);
            VGA_G : out std_logic_vector(3 downto 0);
            VGA_R : out std_logic_vector(3 downto 0);
            VGA_HS : out std_logic;
            VGA_VS : out std_logic
        );
        end component;
    
    component VGA_PLL
        PORT
        (
            areset		: IN STD_LOGIC  := '0';
            inclk0		: IN STD_LOGIC  := '0';
            c0		: OUT STD_LOGIC ;
            locked		: OUT STD_LOGIC 
        );
    end component;

    -- Signal declaration
    signal rst : std_logic;
    signal rst_l : std_logic;
    signal R : std_logic_vector(3 downto 0);
    signal G : std_logic_vector(3 downto 0);
    signal B : std_logic_vector(3 downto 0);
    signal request_data : std_logic;
    signal current_line : unsigned(9 downto 0);
    signal data_pos : unsigned(9 downto 0);
    signal c0_sig : std_logic;
    signal locked_sig : std_logic;

    -- Colors
    signal white : color := (x"F",x"F",x"F");
    signal black : color := (x"0",x"0",x"0");
    signal red : color := (x"C",x"F",x"3");
    signal yellow : color := (x"B",x"5",x"9");


begin
    rst_l <= KEY(0);
    rst <= not KEY(0) when KEY(0) = '0' else '0';
    
    VGA_controller_inst : VGA_controller 
    port map(
        -- Connections go here
        clk => c0_sig,
        rst_l => rst_l,
        R => R,
        G => G,
        B => B,
        request_data => request_data,
        current_line => current_line,
        data_pos => data_pos,
        VGA_B => VGA_B,
        VGA_G => VGA_G,
        VGA_R => VGA_R,
        VGA_HS => VGA_HS,
        VGA_VS => VGA_VS
    );
    PLL_inst : VGA_PLL 
    port map(
        areset	 => rst,
        inclk0	 => MAX10_CLK1_50,
        c0	 => c0_sig,
        locked	 => locked_sig
    );

    process(c0_sig,rst_l) 
    begin
        if(not rst_l = '1') then
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
        elsif rising_edge(c0_sig) then
            if request_data = '1' then
                R <= red(0);
                G <= red(1);
                B <= red(2);

            end if;
        end if;
    end process;
end architecture Behavioral;
