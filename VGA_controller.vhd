library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity VGA_controller is
    port (
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
end entity VGA_controller;

architecture rtl of VGA_controller is

    signal horizontal_counter : integer := 0;
    signal horizontal_counter_n : integer := 0;
    signal vertical_counter : integer := 0;
    signal vertical_counter_n : integer := 0;
    
    signal hor_state : integer := 0;
    signal hor_state_n : integer := 0;
    signal ver_state : integer := 0;
    signal ver_state_n : integer := 0;
    signal line_count : integer := 0;
    signal line_count_n : integer := 0;
    

begin

    -- Take future and update to current
    process(clk, rst_l)
    begin
        if rst_l = '0' then
            horizontal_counter <= 0;
            vertical_counter <= 0;
            hor_state <= 0;
            ver_state <= 0;
            line_count <= 0;
        elsif rising_edge(clk) then
            horizontal_counter <= horizontal_counter_n;
            vertical_counter <= vertical_counter_n;
            hor_state <= hor_state_n;
            ver_state <= ver_state_n;
            line_count <= line_count_n;
        end if;
    end process;
    -- Horizontal state machine
    process(hor_state, horizontal_counter)
    begin
        case hor_state is
        when 0 => -- front porch
            if horizontal_counter < 15 then
                horizontal_counter_n <= horizontal_counter + 1;
            else
                horizontal_counter_n <= 0;
                hor_state_n <= 1;
            end if;
        when 1 => -- sync pulse
            if horizontal_counter < 95 then
                VGA_HS <= '0';
                horizontal_counter_n <= horizontal_counter + 1;
            else
                VGA_HS <= '1';
                horizontal_counter_n <= 0;
                hor_state_n <= 2;
            end if;
        when 2 => -- back porch
            if horizontal_counter < 47 then
                horizontal_counter_n <= horizontal_counter + 1;
            else
                horizontal_counter <= 0;
                hor_state_n <= 3;
            end if;
        when 3 =>
            if horizontal_counter < 639 then
                horizontal_counter_n <= horizontal_counter + 1;
            else
                horizontal_counter_n <= 0;
                hor_state_n <= 0;
            end if;
        when others =>
            hor_state_n <= 0;
        end case;
    end process;

    -- Vertical state machine
    process(ver_state, vertical_counter, line_count)
    begin
        case ver_state is
        when 0 => -- front porch
            if vertical_counter < 7999 then
                vertical_counter_n <= vertical_counter + 1;
            else
                vertical_counter_n <= 0;
                ver_state_n <= 1;
            end if;
        when 1 => -- sync pulse
            if vertical_counter < 1599 then
                VGA_VS <= '0';
                vertical_counter_n <= vertical_counter + 1;
            else
                VGA_VS <= '1';
                vertical_counter_n <= 0;
                ver_state_n <= 2;
            end if;
        when 2 => -- back porch
            if vertical_counter < 26399 then
                vertical_counter_n <= vertical_counter + 1;
            else
                vertical_counter_n <= 0;
                ver_state_n <= 3;
                line_count_n <= 0;
            end if;
        when 3 => -- data
            if vertical_counter >= 799 and line_count >= 478 then
                ver_state_n <= 0;
                vertical_counter_n <= 0;
            else
                if vertical_counter >= 799
                then
                    line_count_n <= line_count + 1;
                    vertical_counter_n <= 0;
                else
                    vertical_counter_n <= vertical_counter + 1;
                end if;
            end if;
        when others =>
            ver_state_n <= 0;
        end case;
    end process;

    process(hor_state, ver_state, line_count, horizontal_counter)
    begin
        if ver_state = 3 and hor_state = 3 then
            current_line <= to_unsigned(line_count,current_line'length);
            data_pos <= to_unsigned(horizontal_counter, data_pos'length);
            request_data <= '1';
            VGA_R <= R;
            VGA_G <= G;
            VGA_B <= B;
        else 
            VGA_R <= X"0";
            VGA_G <= X"0";
            VGA_B <= X"0";
            request_data <= '0';
            current_line <= "0000000000";
            data_pos <= "0000000000";
        end if;
    end process;


end architecture rtl; 
