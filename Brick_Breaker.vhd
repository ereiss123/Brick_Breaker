library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library work;
use work.types.all;

entity Brick_Breaker is
    port
    (
        -- CLOCK
        MAX10_CLK1_50 : in STD_LOGIC;
        -- SEG7
        HEX0, HEX1, HEX2 : out STD_LOGIC_VECTOR(7 downto 0);
        -- HEX3, HEX4, HEX5
        -- KEY
        KEY : in STD_LOGIC_VECTOR(1 downto 0);
        -- LED
        LEDR : out STD_LOGIC_VECTOR(9 downto 0);
        -- VGA
        VGA_B  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS : out STD_LOGIC;
        VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_VS : out STD_LOGIC;

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
            c1     : out STD_LOGIC;
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
        port
        (
            MAX10_CLK1_50 : in STD_LOGIC;
            rst_l         : in STD_LOGIC;
            gen_button    : in STD_LOGIC;
            rand          : out unsigned(8 downto 0)
        );
    end component;

    component my_adc is
        port
        (
            clock_clk              : in STD_LOGIC                    := 'X';             -- clk
            reset_sink_reset_n     : in STD_LOGIC                    := 'X';             -- reset_n
            adc_pll_clock_clk      : in STD_LOGIC                    := 'X';             -- clk
            adc_pll_locked_export  : in STD_LOGIC                    := 'X';             -- export
            command_valid          : in STD_LOGIC                    := 'X';             -- valid
            command_channel        : in STD_LOGIC_VECTOR(4 downto 0) := (others => 'X'); -- channel
            command_startofpacket  : in STD_LOGIC                    := 'X';             -- startofpacket
            command_endofpacket    : in STD_LOGIC                    := 'X';             -- endofpacket
            command_ready          : out STD_LOGIC;                                      -- ready
            response_valid         : out STD_LOGIC;                                      -- valid
            response_channel       : out STD_LOGIC_VECTOR(4 downto 0);                   -- channel
            response_data          : out STD_LOGIC_VECTOR(11 downto 0);                  -- data
            response_startofpacket : out STD_LOGIC;                                      -- startofpacket
            response_endofpacket   : out STD_LOGIC                                       -- endofpacket
        );
    end component my_adc;
    component buzz is
        port
        (
            clk    : in STD_LOGIC;
            rst    : in STD_LOGIC;
            buzzer : out STD_LOGIC;
            go     : in STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    -- Create a look up table for the 7-segment display
    type LUT is array(15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);

    -- 7-segment display look up table. Not to flip bits. 7 segment display is active low.
    signal seven_seg : LUT := (not(X"71"), not(X"79"), not(X"5E"), not(X"58"), not(X"7C"), not(X"77"),
    X"90", X"80", X"F8", X"82", X"92", X"99", X"B0", X"A4", X"F9", X"C0");

    -- Signal declaration
    signal rst : STD_LOGIC;
    signal rst_l : STD_LOGIC;
    signal state : INTEGER := 5; -- state machine for ball movement
    signal R : STD_LOGIC_VECTOR(3 downto 0);
    signal G : STD_LOGIC_VECTOR(3 downto 0);
    signal B : STD_LOGIC_VECTOR(3 downto 0);
    signal request_data : STD_LOGIC;
    signal current_line : unsigned(9 downto 0);
    signal data_pos : unsigned(9 downto 0); --horizontal counter
    signal c0_sig : STD_LOGIC; -- vga clock
    signal c1_sig : STD_LOGIC; -- adc clock
    signal locked_sig : STD_LOGIC; -- pll lock signal
    signal next_ball : STD_LOGIC;
    signal adc_data : STD_LOGIC_VECTOR(11 downto 0);
    signal response_valid : STD_LOGIC; -- adc response valid
    signal response_data : STD_LOGIC_VECTOR(11 downto 0); -- adc response data
    signal adc_count : INTEGER := 0; -- adc counter
    signal adc_state : INTEGER := 0;
    signal go : STD_LOGIC_VECTOR(2 downto 0) := "000"; -- tells buzzer what sound to make

    -- Colors                  R     G     B
    signal white : color := (x"F", x"F", x"F");
    signal black : color := (x"0", x"0", x"0");
    signal red : color := (x"F", x"0", x"0");
    signal brown : color := (x"7", x"4", x"3");

    -- Trackers
    signal ball_timer : INTEGER := 0;
    signal ball_active : STD_LOGIC := '0';
    signal x_accel : INTEGER := 0;
    signal y_accel : INTEGER := 0;
    signal ball_mid : coorid := (0, 0);
    signal ball_left : coorid := (0, 0);
    signal ball_right : coorid := (0, 0);
    signal ball_top : coorid := (0, 0);
    signal ball_bottom : coorid := (0, 0);
    signal ball_row_TB : INTEGER := 0;
    signal ball_col_TB : INTEGER := 0;
    signal ball_row_RL : INTEGER := 0;
    signal ball_col_RL : INTEGER := 0;
    signal ball_parity_TB : STD_LOGIC := '0';
    signal ball_parity_RL : STD_LOGIC := '0';

    signal paddle_x : INTEGER range 0 to 640 := 304;
    signal rand : unsigned(8 downto 0);
    signal ball_counter : INTEGER := 5;
    signal ball_pos : coorid := (320, 241);
    signal ball_parity_top : STD_LOGIC := '0';
    signal ball_parity_bottom : STD_LOGIC := '0';
    signal paddle_pos : coorid := (304, 474);
    signal brick_col_idx : INTEGER := 0; -- indicate which column of bricks (0 - 40)
    signal brick_row_idx : INTEGER := 0;
    signal line_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    -- signal line_parity : STD_LOGIC := '0'; -- indicate whether current line is odd or even
    signal full_brick_x : hhalf_brick_corrid := (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160,
    176, 192, 208, 224, 240, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496,
    512, 528, 544, 560, 576, 592, 608, 624, -1); -- top left corner of each brick in a full row. -1 is a dummy value to fill out the array
    signal half_brick_x : hhalf_brick_corrid := (0, 8, 24, 40, 56, 72, 88, 104, 120, 136, 152, 168,
    184, 200, 216, 232, 248, 264, 280, 296, 312, 328, 344, 360, 376, 392, 408, 424, 440, 456, 472, 488, 504,
    520, 536, 552, 568, 584, 600, 616, 632); -- x coordinate top left corner of each brick in a half row

    -- signal full_brick_x : hhalf_brick_corrid := (1, 17, 33, 49, 65, 81, 97, 113, 129, 145, 161, 177, 193, 209, 225, 241, 257, 273, 289, 305, 321, 337, 353, 369, 385, 401, 417, 433, 449, 465, 481, 497, 513, 529, 545, 561, 577, 593, 609, 625, -1);

    -- signal half_brick_x : hhalf_brick_corrid := (1, 9, 25, 41, 57, 73, 89, 105, 121, 137, 153, 169, 185, 201, 217, 233, 249, 265, 281, 297, 313, 329, 345, 361, 377, 393, 409, 425, 441, 457, 473, 489, 505, 521, 537, 553, 569, 585, 601, 617, 633);

    signal brick_y : vbrick_corrid := (0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120,
    128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232); -- y coordinate of top left corner of each brick
    signal brick_tracker : tracker := (others => (others => '1')); -- 32x40 array of bricks. Active bits indicate brick is still there
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
    c1 => c1_sig,
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

    u0 : my_adc port
    map
    (
    clock_clk => c1_sig, --     this is the clock signal
    reset_sink_reset_n => rst_l, --     this is the reset signal
    adc_pll_clock_clk => c1_sig, --     Singal is good. This is the clock running the adc
    adc_pll_locked_export => locked_sig, --     this signal is high when the pll is locked
    command_valid => '1', --     command.valid
    command_channel => "00001", --     .channel
    command_startofpacket => '1', --     .startofpacket
    command_endofpacket => '1', --     .endofpacket
    command_ready => open, --     .ready
    response_valid => response_valid, --     response.valid
    response_channel => open, --     .channel
    response_data => response_data, --     .data
    response_startofpacket => open, --     .startofpacket
    response_endofpacket => open --     .endofpacket
    );

    buzzer_inst : buzz port
    map
    (
    clk => MAX10_CLK1_50,
    rst => rst,
    buzzer => ARDUINO_IO(0),
    go => go -- 000 = no sound, 001 = paddle hit, 010 = brick hit, 011 = wall hit, 100 = game over
    );

    -- assign hex values to 7-segment display
    HEX0 <= seven_seg(ball_counter); -- balls left
    HEX1 <= (others => '1');
    HEX2 <= (others => '1');
    -- HEX3 <= seven_seg(to_integer(unsigned(adc_data(3 downto 0)))); -- adc data
    -- HEX4 <= seven_seg(to_integer(unsigned(adc_data(7 downto 4)))); -- adc data
    -- HEX5 <= seven_seg(to_integer(unsigned(adc_data(11 downto 8)))); -- adc data

    -- Interface with VGA controller
    VGA_proc : process (c0_sig, rst_l)
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
                            if (data_pos = half_brick_x(brick_col_idx) + 8) and ((brick_col_idx = 0) or (brick_col_idx = 40)) then
                                R <= white(0); -- draw vertical mortar line for half-brick
                                G <= white(1);
                                B <= white(2);
                            elsif data_pos = (half_brick_x(brick_col_idx) + 16) then
                                R <= white(0); -- draw vertical mortar line for full bricks
                                G <= white(1);
                                B <= white(2);
                            elsif data_pos < 639 then
                                R <= red(0); -- draw brick part of brick
                                G <= red(1);
                                B <= red(2);
                            else
                                R <= black(0);
                                G <= black(1);
                                B <= black(2);
                            end if;

                        else -- Even lines (full-brick)
                            if data_pos = (full_brick_x(brick_col_idx) + 16) then
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
    ball_mid <= (ball_pos(0) + 5, ball_pos(1) + 5);
    ball_left <= (ball_pos(0) - 2, ball_pos(1) + 5);
    ball_right <= (ball_pos(0) + 12, ball_pos(1) + 5);
    ball_top <= (ball_pos(0) + 5, ball_pos(1) - 2);
    ball_bottom <= (ball_pos(0) + 5, ball_pos(1) + 12);
    -- ball movement state machine
    ball_proc : process (c0_sig, rst_l)
    begin
        if rst_l = '0' then
            ball_counter <= 5;
            ball_pos <= (700, 700);
            state <= 1;
            ball_timer <= 0;
            x_accel <= 0;
            y_accel <= 2;
            ball_active <= '0';
            ball_row_TB <= 0;
            ball_col_TB <= 0;
            ball_row_RL <= 0;
            ball_col_RL <= 0;
            ball_parity_TB <= '0';
            ball_parity_RL <= '0';
            brick_tracker <= (others => (others => '1'));
            go <= "000"; -- resets buzzer to no sound
        elsif rising_edge(c0_sig) then
            if next_ball = '1' and ball_active = '0' then
                if ball_counter > 0 then
                    ball_counter <= ball_counter - 1;
                    ball_pos <= (to_integer(rand), 241);
                    y_accel <= 2;
                    x_accel <= 0;
                    ball_active <= '1';
                end if;
            else
                -- FSM for ball movement
                if ball_timer < 300000 then -- Update ball position every 500_000 cycles
                    ball_timer <= ball_timer + 1;
                elsif ball_active = '1' then
                    ball_pos <= (ball_pos(0) + x_accel, ball_pos(1) + y_accel);
                    ball_timer <= 0;
                    -- Collision detection
                    if ball_pos(1) > 480 then
                        ball_active <= '0';
                        go <= "001"; -- game over
                    elsif ball_pos(0) < 1 then -- left wall
                        go <= "011"; -- wall hit
                        if x_accel =- 4 then
                            x_accel <= 4;
                        else
                            x_accel <= 2;
                        end if;
                    elsif ((ball_pos(0) + 10) > 638) then -- right wall
                        go <= "011"; -- wall hit
                        if x_accel = 4 then
                            x_accel <= - 4;
                        else
                            x_accel <= - 2;
                        end if;

                    elsif ball_pos(1) = 1 then -- bounce off top wall
                        y_accel <= 2;
                        go <= "011"; -- wall hit

                        -- Paddle
                    elsif (ball_pos(1) + 10) >= paddle_pos(1) and ((ball_pos(0) + 10 >= paddle_pos(0)) and (ball_pos(0) < paddle_pos(0) + 40)) then -- bounce off paddle 
                        y_accel <= - 2;
                        go <= "010"; -- paddle hit
                        -- Bounce ball depending on where it hits the paddle
                        if ball_pos(0) + 10 >= paddle_pos(0) and ball_pos(0) < (paddle_pos(0) + 9) then --leftmost quadrant
                            x_accel <= - 4;
                        elsif ball_pos(0) + 10 >= paddle_pos(0) + 10 and ball_pos(0) < (paddle_pos(0) + 19) then -- left middle quadrant
                            x_accel <= - 2;
                        elsif ball_pos(0) + 10 >= paddle_pos(0) + 20 and ball_pos(0) < (paddle_pos(0) + 29) then -- right middle quadrant
                            x_accel <= 2;
                        elsif ball_pos(0) + 10 >= paddle_pos(0) + 30 and ball_pos(0) < (paddle_pos(0) + 39) then -- rightmost quadrant
                            x_accel <= 4;
                        end if;

                        -- Bricks
                    elsif ball_pos(1) < 235 then
                        -- Top collision
                        if x_accel > 0 and y_accel > 0 then -- right and down
                            -- Check right side of ball
                            ball_row_RL <= to_integer(shift_right(to_unsigned(ball_right(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_RL <= to_unsigned(ball_row_RL, 32)(0); -- get parity of right side of ball
                            if ball_parity_RL = '1' then
                                if ball_right(0) < 8 then
                                    ball_col_RL <= 0; -- Deal with first half brick
                                else
                                    ball_col_RL <= to_integer(shift_right(to_unsigned(ball_right(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_RL <= to_integer(shift_right(to_unsigned(ball_right(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                            -- Check bottom of ball
                            ball_row_TB <= to_integer(shift_right(to_unsigned(ball_bottom(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_TB <= to_unsigned(ball_row_TB, 32)(0); -- get parity of bottom of ball
                            if ball_parity_TB = '1' then
                                if ball_bottom(0) < 8 then
                                    ball_col_TB <= 0; -- Deal with first half brick
                                else
                                    ball_col_TB <= to_integer(shift_right(to_unsigned(ball_bottom(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_TB <= to_integer(shift_right(to_unsigned(ball_bottom(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                        elsif x_accel < 0 and y_accel > 0 then -- left and down
                            -- Check right side of ball
                            ball_row_RL <= to_integer(shift_right(to_unsigned(ball_left(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_RL <= to_unsigned(ball_row_RL, 32)(0); -- get parity of right side of ball
                            if ball_parity_RL = '1' then
                                if ball_left(0) < 8 then
                                    ball_col_RL <= 0; -- Deal with first half brick
                                else
                                    ball_col_RL <= to_integer(shift_right(to_unsigned(ball_left(0), 32) + 8, 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_RL <= to_integer(shift_right(to_unsigned(ball_left(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                            -- Check bottom of ball
                            ball_row_TB <= to_integer(shift_right(to_unsigned(ball_bottom(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_TB <= to_unsigned(ball_row_TB, 32)(0); -- get parity of bottom of ball
                            if ball_parity_TB = '1' then
                                if ball_bottom(0) < 8 then
                                    ball_col_TB <= 0; -- Deal with first half brick
                                else
                                    ball_col_TB <= to_integer(shift_right(to_unsigned(ball_bottom(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_TB <= to_integer(shift_right(to_unsigned(ball_bottom(0), 32), 4)); -- divide x coordinate by 16
                            end if;
                        elsif x_accel > 0 and y_accel < 0 then -- right and up
                            -- Check right side of ball
                            ball_row_RL <= to_integer(shift_right(to_unsigned(ball_right(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_RL <= to_unsigned(ball_row_RL, 32)(0); -- get parity of right side of ball
                            if ball_parity_RL = '1' then
                                if ball_right(0) < 8 then
                                    ball_col_RL <= 0; -- Deal with first half brick
                                else
                                    ball_col_RL <= to_integer(shift_right(to_unsigned(ball_right(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_RL <= to_integer(shift_right(to_unsigned(ball_right(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                            -- Check bottom of ball
                            ball_row_TB <= to_integer(shift_right(to_unsigned(ball_top(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_TB <= to_unsigned(ball_row_TB, 32)(0); -- get parity of bottom of ball
                            if ball_parity_TB = '1' then
                                if ball_top(0) < 8 then
                                    ball_col_TB <= 0; -- Deal with first half brick
                                else
                                    ball_col_TB <= to_integer(shift_right(to_unsigned(ball_top(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_TB <= to_integer(shift_right(to_unsigned(ball_top(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                        elsif x_accel < 0 and y_accel < 0 then -- left and up
                            -- Check right side of ball
                            ball_row_RL <= to_integer(shift_right(to_unsigned(ball_left(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_RL <= to_unsigned(ball_row_RL, 32)(0); -- get parity of right side of ball
                            if ball_parity_RL = '1' then
                                if ball_left(0) < 8 then
                                    ball_col_RL <= 0; -- Deal with first half brick
                                else
                                    ball_col_RL <= to_integer(shift_right(to_unsigned(ball_left(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_RL <= to_integer(shift_right(to_unsigned(ball_left(0), 32), 4)); -- divide x coordinate by 16
                            end if;

                            -- Check bottom of ball
                            ball_row_TB <= to_integer(shift_right(to_unsigned(ball_top(1), 32), 3)); -- divide y coordinate by 8
                            ball_parity_TB <= to_unsigned(ball_row_TB, 32)(0); -- get parity of bottom of ball
                            if ball_parity_TB = '1' then
                                if ball_top(0) < 8 then
                                    ball_col_TB <= 0; -- Deal with first half brick
                                else
                                    ball_col_TB <= to_integer(shift_right(to_unsigned(ball_top(0) + 8, 32), 4)); -- compensate rest 
                                end if;
                            else
                                ball_col_TB <= to_integer(shift_right(to_unsigned(ball_top(0), 32), 4)); -- divide x coordinate by 16
                            end if;
                        end if;

                        if brick_tracker(ball_row_RL, ball_col_RL) = '1' then
                            if ball_row_RL = 0 and ball_col_RL = 0 then
                                if ball_pos(1) > 8 then
                                    brick_tracker(ball_row_RL, ball_col_RL) <= '1';
                                else
                                    brick_tracker(ball_row_RL, ball_col_RL) <= '0';
                                end if;
                            else
                                brick_tracker(ball_row_RL, ball_col_RL) <= '0';
                            end if;
                            go <= "100";
                            -- Update ball velocity
                            case x_accel is
                                when 2 =>
                                    x_accel <= 4;
                                when 4 =>
                                    x_accel <= 2;
                                when -2 =>
                                    x_accel <= - 4;
                                when -4 =>
                                    x_accel <= - 2;
                                when others =>
                                    x_accel <= 0;
                            end case;
                        elsif brick_tracker(ball_row_TB, ball_col_TB) = '1' then
                            if ball_row_TB = 0 and ball_col_TB = 0 then
                                if ball_pos(1) > 8 then
                                    brick_tracker(ball_row_TB, ball_col_TB) <= '1';
                                else
                                    brick_tracker(ball_row_TB, ball_col_TB) <= '0';
                                end if;
                            else
                                brick_tracker(ball_row_TB, ball_col_TB) <= '0';
                            end if;
                            
                            case y_accel is
                                when 2 =>
                                    y_accel <= - 2;
                                when -2 =>
                                    y_accel <= 2;
                                when others =>
                                    y_accel <= 0;
                            end case;
                        else
                            go <= "000";
                        end if;
                    else
                        go <= "000";
                    end if;
                else
                    go <= "000";
                end if;
            end if;
        end if;
    end process;

    -- ADC process
    paddle_proc : process (c1_sig, rst_l)
    begin
        if rst_l = '0' then
            paddle_x <= 304;
            paddle_pos <= (304, 474);
        elsif rising_edge(c1_sig) then
            if shift_right(unsigned(adc_data), 1) > 600 then
                paddle_x <= 600;
            else
                paddle_x <= to_integer(shift_right(unsigned(adc_data), 1));
            end if;
            paddle_pos <= (paddle_x, 474);
        end if;
    end process;

    ADC_proc : process (c1_sig, rst_l)
    begin
        if (rst_l = '0') then
            adc_count <= 0;
            adc_state <= 0;
            adc_data <= (others => '0');
        elsif rising_edge(c1_sig) then
            case(adc_state) is
                when 0 =>
                if (adc_count = 99999) then -- Update at 1 kHz
                    adc_count <= 0;
                    adc_state <= 1;
                else
                    adc_state <= 0;
                    adc_count <= adc_count + 1;
                end if;
                when 1 =>
                adc_count <= 0;
                if response_valid = '1' then
                    adc_state <= 0;
                    adc_data <= response_data;
                end if;
                when others =>
                adc_data <= (others => '0');
                adc_state <= 0;
            end case;
        end if;
    end process;

end architecture rtl;