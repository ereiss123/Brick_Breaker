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

    -- Signal declaration
    signal rst : STD_LOGIC;
    signal rst_l : STD_LOGIC;
    signal R : STD_LOGIC_VECTOR(3 downto 0);
    signal nR : STD_LOGIC_VECTOR(3 downto 0);
    signal G : STD_LOGIC_VECTOR(3 downto 0);
    signal nG : STD_LOGIC_VECTOR(3 downto 0);
    signal B : STD_LOGIC_VECTOR(3 downto 0);
    signal nB : STD_LOGIC_VECTOR(3 downto 0);
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
    signal ball_pos : coorid := (320, 241);
    signal nball_pos : coorid := (320, 241);
    signal paddle_pos : coorid := (304, 474);
    signal npaddle_pos : coorid := (304, 474);
    signal brick_col_idx : INTEGER := 0; -- indicate which column of bricks (0 - 40)
    signal nbrick_col_idx : INTEGER := 0;
    signal brick_row_idx : INTEGER := 0;
    signal nbrick_row_idx : INTEGER := 0;
    signal line_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    signal nline_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    signal full_brick_x : hhalf_brick_corrid := (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160,
    176, 192, 208, 224, 240, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496,
    512, 528, 544, 560, 576, 592, 608, 624, -1); -- top left corner of each brick in a full row. -1 is a dummy value to fill out the array
    signal half_brick_x : hhalf_brick_corrid := (0, 8, 24, 40, 56, 72, 88, 104, 120, 136, 152, 168,
    184, 200, 216, 232, 248, 264, 280, 296, 312, 328, 344, 360, 376, 392, 408, 424, 440, 456, 472, 488, 504,
    520, 536, 552, 568, 584, 600, 616, 632); -- x coordinate top left corner of each brick in a half row
    signal brick_y : vbrick_corrid := (0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120,
    128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232); -- y coordinate of top left corner of each brick
    signal brick_tracker : tracker := (
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
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
        ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
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
    rst => rst_l,
    button => KEY(1),
    button_debounced => next_ball
    );

    -- Future becomes the present
    process (c0_sig, rst_l)
    begin
        if (not rst_l = '1') then
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
            ball_pos <= (0, 0);
            paddle_pos <= (0, 0);
            brick_col_idx <= 0;
            brick_row_idx <= 0;
            line_parity <= '0';
        elsif rising_edge(c0_sig) then
            R <= nR;
            G <= nG;
            B <= nB;
            brick_col_idx <= nbrick_col_idx;
            brick_row_idx <= nbrick_row_idx;
            paddle_pos <= npaddle_pos;
            ball_pos <= nball_pos;
            line_parity <= nline_parity;
        end if;
    end process;

    -- Interface with VGA controller
    process (R, G, B, request_data, current_line, data_pos, brick_row_idx, brick_col_idx,
        ball_pos, paddle_pos, next_ball, brick_tracker, red, white, brown,
        black, white, half_brick_x, full_brick_x) -- bit to stop quartus from complaining
    begin
        -- We need to draw bricks, ball, and paddle 
        if request_data = '1' then
            -- Draw ball
            if current_line >= ball_pos(1) and current_line < (ball_pos(1) + 10) and
                data_pos >= ball_pos(0) and data_pos < (ball_pos(0) + 10) -- ball is 10x10. This keeps it from drawing outside of the ball
                then
                nR <= white(0);
                nG <= white(1);
                nB <= white(2);
                -- Necessary to prevent latches
                nbrick_col_idx <= 0;
                nbrick_row_idx <= 0;
                nline_parity <= '0';
                -- Draw paddle
            elsif current_line >= paddle_pos(1) and current_line < (paddle_pos(1) + 5)and
                data_pos >= paddle_pos(0) and data_pos < (paddle_pos(0) + 40)
                then
                nR <= brown(0);
                nG <= brown(1);
                nB <= brown(2);
                -- Necessary to prevent latches
                nbrick_col_idx <= 0;
                nbrick_row_idx <= 0;
                nline_parity <= '0';
                -- Draw bricks
            elsif current_line >= 0 and current_line < 240 then
                nbrick_row_idx <= to_integer(shift_right(current_line, 3)); -- divide current line by 8
                nline_parity <= to_unsigned(brick_row_idx, 32)(0);
                if line_parity = '1' then -- Odd line (half-brick line)
                    if data_pos < 8 then
                        nbrick_col_idx <= 0; -- Deal with first half brick
                    else
                        nbrick_col_idx <= to_integer(shift_right(data_pos + 8, 4)); -- compensate rest 
                    end if;
                else -- Even (Full brick line)
                    nbrick_col_idx <= to_integer(shift_right(data_pos, 4)); -- divide data_pos by 16
                end if;

                if brick_tracker(brick_row_idx, brick_col_idx) = '1' then
                    if current_line = (brick_y(brick_row_idx) + 7) then -- draw horizontal mortar line
                        nR <= white(0);
                        nG <= white(1);
                        nB <= white(2);
                    elsif line_parity = '1' then -- Odd lines (half-brick)
                        if (data_pos = half_brick_x(brick_col_idx) + 8) and ((brick_col_idx = 0) or (brick_col_idx = 40)) then
                            nR <= white(0); -- draw vertical mortar line for half-brick
                            nG <= white(1);
                            nB <= white(2);
                        elsif data_pos = (half_brick_x(brick_col_idx) + 16) then
                            nR <= white(0); -- draw vertical mortar line for full bricks
                            nG <= white(1);
                            nB <= white(2);
                        else
                            nR <= red(0); -- draw brick part of brick
                            nG <= red(1);
                            nB <= red(2);
                        end if;
                    else -- Even lines (full-brick)
                        if data_pos = (full_brick_x(brick_col_idx) + 16) then
                            nR <= white(0); -- draw vertical mortar line
                            nG <= white(1);
                            nB <= white(2);
                        else
                            nR <= red(0); -- draw brick part of brick
                            nG <= red(1);
                            nB <= red(2);
                        end if;
                    end if;
                else
                    nR <= black(0);
                    nG <= black(1);
                    nB <= black(2);
                end if;
            else
                nR <= black(0);
                nG <= black(1);
                nB <= black(2);
                nbrick_col_idx <= 0;
                nbrick_row_idx <= 0;
                nline_parity <= '0';
            end if;
        else
            nR <= black(0);
            nG <= black(1);
            nB <= black(2);
            nbrick_col_idx <= 0;
            nbrick_row_idx <= 0;
            nline_parity <= '0';
        end if;
    end process;

end architecture rtl;