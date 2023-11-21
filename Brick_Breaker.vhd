library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library work;
use work.types.all;

entity Brick_Breaker is
    port
    (
        -- CLOCK
        -- ADC_CLK_10       : in std_logic;
        MAX10_CLK1_50 : in STD_LOGIC;
        -- MAX10_CLK2_50    : in std_logic;

        -- SDRAM
        DRAM_ADDR  : out STD_LOGIC_VECTOR(12 downto 0);
        DRAM_BA    : out STD_LOGIC_VECTOR(1 downto 0);
        DRAM_CAS_N : out STD_LOGIC;
        DRAM_CKE   : out STD_LOGIC;
        DRAM_CLK   : out STD_LOGIC;
        DRAM_CS_N  : out STD_LOGIC;
        DRAM_DQ    : inout STD_LOGIC_VECTOR(15 downto 0);
        DRAM_LDQM  : out STD_LOGIC;
        DRAM_RAS_N : out STD_LOGIC;
        DRAM_UDQM  : out STD_LOGIC;
        DRAM_WE_N  : out STD_LOGIC;

        -- SEG7
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out STD_LOGIC_VECTOR(7 downto 0);

        -- KEY
        KEY : in STD_LOGIC_VECTOR(1 downto 0);

        -- LED
        LEDR : out STD_LOGIC_VECTOR(9 downto 0);

        -- SW
        -- SW               : in std_logic_vector(9 downto 0);

        -- VGA
        VGA_B  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS : out STD_LOGIC;
        VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_VS : out STD_LOGIC;

        -- Accelerometer
        GSENSOR_CS_N : out STD_LOGIC;
        -- GSENSOR_INT      : in std_logic_vector(2 downto 1);
        GSENSOR_SCLK : out STD_LOGIC;
        GSENSOR_SDI  : inout STD_LOGIC;
        GSENSOR_SDO  : inout STD_LOGIC;

        -- Arduino
        ARDUINO_IO      : inout STD_LOGIC_VECTOR(15 downto 0);
        ARDUINO_RESET_N : inout STD_LOGIC
    );
end entity Brick_Breaker;

architecture Behavioral of Brick_Breaker is
    -- Component declaration
    component VGA_controller
        port
        (
            -- FPGA side
            clk          : in STD_LOGIC;
            rst_l        : in STD_LOGIC;
            R            : in STD_LOGIC_VECTOR(3 downto 0);
            G            : in STD_LOGIC_VECTOR(3 downto 0);
            B            : in STD_LOGIC_VECTOR(3 downto 0);
            request_data : out STD_LOGIC;
            current_line : out unsigned(9 downto 0);
            data_pos     : out unsigned(9 downto 0);

            -- Monitor side
            VGA_B  : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_HS : out STD_LOGIC;
            VGA_VS : out STD_LOGIC
        );
    end component;

    component VGA_PLL
        port
        (
            areset : in STD_LOGIC := '0';
            inclk0 : in STD_LOGIC := '0';
            c0     : out STD_LOGIC;
            locked : out STD_LOGIC
        );
    end component;

    component debouncer
        port
        (
            clk              : in STD_LOGIC;
            rst              : in STD_LOGIC;
            button           : in STD_LOGIC;
            button_debounced : out STD_LOGIC
        );
    end component;

    -- Signal declaration
    signal rst : STD_LOGIC;
    signal rst_l : STD_LOGIC;
    signal R : STD_LOGIC_VECTOR(3 downto 0);
    signal G : STD_LOGIC_VECTOR(3 downto 0);
    signal B : STD_LOGIC_VECTOR(3 downto 0);
    signal request_data : STD_LOGIC;
    signal current_line : unsigned(9 downto 0);
    signal data_pos : unsigned(9 downto 0);
    signal c0_sig : STD_LOGIC;
    signal locked_sig : STD_LOGIC;

    signal next_ball : STD_LOGIC;

    -- Colors                  R    G    B
    signal white : color := (x"F", x"F", x"F");
    signal black : color := (x"0", x"0", x"0");
    signal red : color := (x"C", x"F", x"3");
    signal yellow : color := (x"B", x"5", x"9");
begin
    rst_l <= KEY(0);
    rst <= not KEY(0) when KEY(0) = '0' else
        '0';

    VGA_controller_inst : VGA_controller
    port map
    (
        -- Connections go here
        clk          => c0_sig,
        rst_l        => rst_l,
        R            => R,
        G            => G,
        B            => B,
        request_data => request_data,
        current_line => current_line,
        data_pos     => data_pos,
        VGA_B        => VGA_B,
        VGA_G        => VGA_G,
        VGA_R        => VGA_R,
        VGA_HS       => VGA_HS,
        VGA_VS       => VGA_VS
    );
    PLL_inst : VGA_PLL
    port
    map(
    areset => rst,
    inclk0 => MAX10_CLK1_50,
    c0 => c0_sig,
    locked => locked_sig
    );

    db_inst : debouncer
    port
    map(
    clk => c0_sig,
    rst => rst,
    button => KEY(1),
    button_debounced => next_ball
    );

    process (c0_sig, rst_l)
    begin
        if (not rst_l = '1') then
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