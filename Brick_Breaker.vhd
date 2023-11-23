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

architecture rtl of Brick_Breaker is
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

    component psuedorandom_gen is
        -- generic
        --     (seed : unsigned(15 downto 0));
        port
        (
            MAX10_CLK1_50 : in STD_LOGIC;
            rst_l         : in STD_LOGIC;
            gen_button    : in STD_LOGIC;
            rand          : out unsigned(8 downto 0)
        );
    end component;

    -- Create a look up table for the 7-segment display
    type LUT is array(15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);

    -- 7-segment display look up table. Not to flip bits. 7 segment display is active low.
    signal seven_seg : LUT := (not(X"71"), not(X"79"), not(X"5E"), not(X"58"), not(X"7C"), not(X"77"), X"90", X"80", X"F8", X"82", X"92", X"99", X"B0", X"A4", X"F9", X"C0");

    -- Signal declaration
    signal rst : STD_LOGIC;
    signal rst_l : STD_LOGIC;
    signal R : STD_LOGIC_VECTOR(3 downto 0);

    -- signal R : STD_LOGIC_VECTOR(3 downto 0);
    signal G : STD_LOGIC_VECTOR(3 downto 0);
    -- signal G : STD_LOGIC_VECTOR(3 downto 0);
    signal B : STD_LOGIC_VECTOR(3 downto 0);
    -- signal B : STD_LOGIC_VECTOR(3 downto 0);
    signal request_data : STD_LOGIC;
    signal current_line : unsigned(9 downto 0);
    signal data_pos : unsigned(9 downto 0); --horizontal counter
    signal c0_sig : STD_LOGIC;
    signal locked_sig : STD_LOGIC;
    signal next_ball : STD_LOGIC;
    -- Colors                        R    G    B
    signal white : color := (x"F", x"F", x"F");
    signal black : color := (x"0", x"0", x"0");
    signal red : color := (x"F", x"0", x"0");
    signal brown : color := (x"7", x"4", x"3");

    -- Trackers
    signal rand : unsigned(8 downto 0);
    signal ball_counter : INTEGER := 5;
    signal nball_counter : INTEGER;
    signal ball_pos : coorid := (320, 241);
    signal nball_pos : coorid := (320, 241);
    signal paddle_pos : coorid := (304, 474);
    signal npaddle_pos : coorid := (304, 474);
    signal brick_col_idx : INTEGER := 0; -- indicate which column of bricks (0 - 40)
    -- signal brick_col_idx : INTEGER := 0;
    signal brick_row_idx : INTEGER := 0;
    -- signal brick_row_idx : INTEGER := 0;
    signal line_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    -- signal line_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    -- signal full_brick_x : hhalf_brick_corrid := (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160,
    -- 176, 192, 208, 224, 240, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496,
    -- 512, 528, 544, 560, 576, 592, 608, 624, -1); -- top left corner of each brick in a full row. -1 is a dummy value to fill out the array
    -- signal half_brick_x : hhalf_brick_corrid := (0, 8, 24, 40, 56, 72, 88, 104, 120, 136, 152, 168,
    -- 184, 200, 216, 232, 248, 264, 280, 296, 312, 328, 344, 360, 376, 392, 408, 424, 440, 456, 472, 488, 504,
    -- 520, 536, 552, 568, 584, 600, 616, 632); -- x coordinate top left corner of each brick in a half row
    
    signal full_brick_x : hhalf_brick_corrid := (1,17,33,49,65,81,97,113,129,145,161,177,193,209,225,241,257,273,289,305,321,337,353,369,385,401,417,433,449,465,481,497,513,529,545,561,577,593,609,625,-1);

    signal half_brick_x : hhalf_brick_corrid := (1,9,25,41,57,73,89,105,121,137,153,169,185,201,217,233,249,265,281,297,313,329,345,361,377,393,409,425,441,457,473,489,505,521,537,553,569,585,601,617,633);

    signal brick_y : vbrick_corrid := (0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120,
    128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232); -- y coordinate of top left corner of each brick
    



    signal brick_tracker : tracker := (
    ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1')
    ); -- 32x40 array of bricks. Active bits indicate brick is still there
begin -- RTL

    rst_l <= KEY(0);
    rst <= not KEY(0) when KEY(0) = '0' else '0';

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
    map
    (
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

    psuedorandom_gen_inst : psuedorandom_gen
    port
    map
    (
    MAX10_CLK1_50 => c0_sig,
    rst_l => rst_l,
    gen_button => next_ball,
    rand => rand
    );

HEX0 <= seven_seg(ball_counter);
    -- Future becomes the present
    process (c0_sig, rst_l)
    begin
        if (not rst_l = '1') then
            -- R <= (others => '0');
            -- G <= (others => '0');
            -- B <= (others => '0');
            -- ball_pos <= (-1, -1);
            paddle_pos <= (0, 0);
            -- brick_col_idx <= 0;
            -- brick_row_idx <= 0;
            -- line_parity <= '0';
            -- ball_counter <= 5;
            -- nball_counter <= 5;
        elsif rising_edge(c0_sig) then
            -- R <= R;
            -- G <= G;
            -- B <= B;
            -- HEX0 <= seven_seg(ball_counter);
            -- brick_col_idx <= brick_col_idx;
            -- brick_row_idx <= brick_row_idx;
            paddle_pos <= npaddle_pos;
            -- ball_pos <= nball_pos;
            -- line_parity <= line_parity;
            -- ball_counter <= nball_counter;
        end if;
    end process;

    -- Interface with VGA controller
    process (c0_sig,rst_l) 
    begin
        if rst_l = '0' then
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
            brick_col_idx <= 0;
            brick_row_idx <= 0;
            line_parity <= '0';
        elsif rising_edge(c0_sig) then     
            -- We need to draw bricks, ball, and paddle 
            if request_data = '1' then
                -- Draw ball
                if current_line >= ball_pos(1) and current_line < (ball_pos(1) + 10) and
                data_pos >= ball_pos(0) and data_pos < (ball_pos(0) + 10) -- ball is 10x10. This keeps it from drawing outside of the ball
                then
                    R <= white(0);
                    G <= white(1);
                    B <= white(2);
                    -- Draw paddle
                elsif current_line >= paddle_pos(1) and current_line < (paddle_pos(1) + 5)and
                    data_pos >= paddle_pos(0) and data_pos < (paddle_pos(0) + 40)
                    then
                    R <= brown(0);
                    G <= brown(1);
                    B <= brown(2);
                    -- Draw bricks
                elsif current_line >= 0 and current_line < 240 then
                    brick_row_idx <= to_integer(shift_right(current_line, 3)); -- divide current line by 8
                    line_parity <= to_unsigned(brick_row_idx, 32)(0); -- get parity of current line
                    if line_parity = '1' then -- Odd line (half-brick line)
                        if data_pos < 8 then
                            brick_col_idx <= 0; -- Deal with first half brick
                        else
                            brick_col_idx <= to_integer(shift_right(data_pos + 8, 4)); -- compensate rest 
                        end if;
                    else -- Even (Full brick line)
                        brick_col_idx <= to_integer(shift_right(data_pos, 4)); -- divide data_pos by 16
                    end if;

                    if brick_tracker(brick_row_idx, brick_col_idx) = '1' then -- if brick is still there
                        if current_line = (brick_y(brick_row_idx) + 7) then -- draw horizontal mortar line when +7 from top of brick column
                            R <= white(0);
                            G <= white(1);
                            B <= white(2);
                        elsif line_parity = '1' then -- Odd lines (half-brick)
                            if (data_pos = half_brick_x(brick_col_idx) + 7) and ((brick_col_idx = 0) or (brick_col_idx = 40)) then
                                R <= white(0); -- draw vertical mortar line for half-brick
                                G <= white(1);
                                B <= white(2);
                            elsif data_pos = (half_brick_x(brick_col_idx) + 15) then
                                R <= white(0); -- draw vertical mortar line for full bricks
                                G <= white(1);
                                B <= white(2);
                            else
                                R <= red(0); -- draw brick part of brick
                                G <= red(1);
                                B <= red(2);
                            end if;
                        else -- Even lines (full-brick)
                            if data_pos = (full_brick_x(brick_col_idx) + 15) then
                                R <= white(0); -- draw vertical mortar line
                                G <= white(1);
                                B <= white(2);
                            else
                                R <= red(0); -- draw brick part of brick
                                G <= red(1);
                                B <= red(2);
                            end if;
                        end if;
                    else
                        R <= black(0);
                        G <= black(1);
                        B <= black(2);
                    end if;
                else
                    R <= black(0);
                    G <= black(1);
                    B <= black(2);
                end if;
            end if;
        end if;
    end process;

    -- ball movement state machine
    process (c0_sig, rst_l)
    begin
        if rst_l = '0' then
            ball_counter <= 5;
            ball_pos <= (700, 700);
        elsif rising_edge(c0_sig) then
            if next_ball = '1' then
                if ball_counter > 0 then
                    ball_pos <= (to_integer(rand), 241);
                    ball_counter <= ball_counter - 1;
                end if;
            end if;
        end if;
    end process;
    --     psuedorandom_gen_inst : psuedorandom_gen
    -- port
    -- map
    -- (
    -- MAX10_CLK1_50 => c0_sig,
    -- rst_l => rst_l,
    -- gen_button => next_ball,
    -- rand => rand
    -- );
end architecture rtl;