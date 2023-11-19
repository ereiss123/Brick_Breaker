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

    component debouncer
        port(
            clk : in std_logic;
            rst : in std_logic;
            button : in std_logic;
            button_debounced : out std_logic
        );
    end component;

    -- Signal declaration
    signal rst : std_logic;
    signal rst_l : std_logic;
    signal R : std_logic_vector(3 downto 0);
    signal nR : std_logic_vector(3 downto 0);
    signal G : std_logic_vector(3 downto 0);
    signal nG : std_logic_vector(3 downto 0);
    signal B : std_logic_vector(3 downto 0);
    signal nB : std_logic_vector(3 downto 0);
    signal request_data : std_logic;
    signal current_line : unsigned(9 downto 0);
    signal data_pos : unsigned(9 downto 0);
    signal c0_sig : std_logic;
    signal locked_sig : std_logic;

    signal next_ball : std_logic;

    -- Colors                        R    G    B
    signal white    : color    := (x"F",x"F",x"F");
    signal black    : color    := (x"0",x"0",x"0");
    signal red      : color    := (x"C",x"F",x"3");
    signal yellow   : color    := (x"B",x"5",x"9");
    signal brown    : color    := (x"6",x"b",x"4");

    -- Trackers
    signal ball_pos : coorid := (320,241);
    signal paddle_pos : coorid := (304,474);
    signal brick_y_idx : integer := 0; -- indicate which row of bricks (0 - 29)
    signal brick_x_idx : integer := 0; -- indicate which column of bricks (0 - 40)
    signal x_print_idx : integer := 0;
    signal nx_print_idx : integer := 0;
    signal y_print_idx : integer := 0;
    signal ny_print_idx : integer := 0;
    signal half_brick_x_idx : integer := 0; -- indicate which column of bricks (0 - 40)
    signal full_brick_x_idx : integer := 0; -- indicate which column of bricks (0 - 40)
    signal full_brick_x : hhalf_brick_corrid := (0,16,32,48,64,80,96,112,128,144,160,
    176,192,208,224,240,256,272,288,304,320,336,352,368,384,400,416,432,448,464,480,496,
    512,528,544,560,576,592,608,624,-1);
    signal half_brick_x : hhalf_brick_corrid := (0,8,24,40,56,72,88,104,120,136,152,168,
    184,200,216,232,248,264,280,296,312,328,344,360,376,392,408,424,440,456,472,488,504,
    520,536,552,568,584,600,616,632);
    signal brick_y : vbrick_corrid := (0,8,16,24,32,40,48,56,64,72,80,88,96,104,112,120,
    128,136,144,152,160,168,176,184,192,200,208,216,224,232);
    signal brick_tracker :tracker := (
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1')
        );


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

    db_inst : debouncer
    port map(
        clk => c0_sig,
        rst => rst_l,
        button => KEY(1),
        button_debounced => next_ball
    );

    -- Future becomes the present
    process(c0_sig,rst_l) 
    begin
        if(not rst_l = '1') then
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
            ball_pos <= (0,0);
            paddle_pos <= (0,0);
            x_print_idx <= 0;
            y_print_idx <= 0;
        elsif rising_edge(c0_sig) then
            R <= nR;
            G <= nG;
            B <= nB;
            x_print_idx <= nx_print_idx;
            y_print_idx <= ny_print_idx;
        end if;
    end process;

    -- Interface with VGA controller
    process(R,G,B,request_data,current_line,data_pos)
    begin
        -- We need to draw bricks, ball, and paddle 
        if request_data = '1' then
            -- Draw ball
            if current_line >= ball_pos(1) and current_line < (ball_pos(1)+10) and 
            data_pos >= ball_pos(0) and data_pos < (ball_pos(0)+10)
            then
                nR <= white(0);
                nG <= white(1);
                nB <= white(2);
            -- Draw paddle
            elsif current_line >= paddle_pos(1) and current_line < (paddle_pos(1)+5)and
            data_pos >= paddle_pos(0) and data_pos < (paddle_pos(0)+40) 
            then
                nR <= brown(0);
                nG <= brown(1);
                nB <= brown(2);
            -- Draw bricks
            elsif current_line >= 0 and current_line < 240 then
                -- calculate brick_y_idx
                brick_y_idx <= to_integer(shift_right(current_line, 3)); -- divide current line by 8 
                brick_x_idx <= to_integer(shift_right(data_pos, 4)); -- divide data_pos by 16, need to figure out half bricks
                if brick_tracker(brick_y_idx,brick_x_idx) = '1' then
                    ny_print_idx <= y_print_idx + 1;
                    if current_line =( brick_y(y_print_idx)+7) then -- draw horizontal mortar line
                        nx_print_idx <= 0;
                        nR <= yellow(0);
                        nG <= yellow(1);
                        nB <= yellow(2);
                    elsif current_line & "0000000001" <= 1 then -- Odd lines (half-brick)
                        if (data_pos = half_brick_x(x_print_idx)+7) and ((x_print_idx = 0) or (x_print_idx = 40)) then
                            nR <= yellow(0); -- draw vertical mortar line
                            nG <= yellow(1);
                            nB <= yellow(2);
                        elsif data_pos = (half_brick_x(x_print_idx)+15) then
                            nR <= yellow(0); -- draw vertical mortar line
                            nG <= yellow(1);
                            nB <= yellow(2);
                        else
                            nR <= red(0); -- draw brick part of brick
                            nG <= red(1);
                            nB <= red(2);
                        end if;
                        nx_print_idx <= x_print_idx + 1;
                    else -- Even lines (full-brick)
                        if data_pos = (full_brick_x(x_print_idx)+15) then -- draw brick part of brick
                            nR <= yellow(0); -- draw vertical mortar line
                            nG <= yellow(1);
                            nB <= yellow(2);
                        else
                            nR <= red(0); -- draw brick part of brick
                            nG <= red(1);
                            nB <= red(2);
                        end if;
                        nx_print_idx <= x_print_idx + 1;
                    end if;
                else
                    nR <= black(0);
                    nG <= black(1);
                    nB <= black(2);
                    nx_print_idx <= x_print_idx;
                    ny_print_idx <= y_print_idx;
                end if;
            else 
                nR <= black(0);
                nG <= black(1);
                nB <= black(2);
                nx_print_idx <= x_print_idx;
                ny_print_idx <= y_print_idx;
                brick_y_idx <= 0;
                brick_x_idx <= 0;
            end if;
        else
            nR <= black(0);
            nG <= black(1);
            nB <= black(2);
            nx_print_idx <= x_print_idx;
            ny_print_idx <= y_print_idx;
            brick_y_idx <= 0;
            brick_x_idx <= 0;
        end if;
    end process;

end architecture Behavioral;
