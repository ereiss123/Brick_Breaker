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

    signal hor_count : integer := 0;
    signal ver_count : integer := 0;
    
    signal hor_state : integer := 0;
    signal ver_state : integer := 0;
    signal line_count : integer := 0;
    
    signal h_flag : std_logic := '0';
    signal v_flag : std_logic := '0';
begin

    -- Take future and update to current
    process(clk, rst_l)
    begin
        if rst_l = '0' then
            hor_count <= 0;
            hor_state <= 0;
            VGA_HS <= '1';
            h_flag <= '0';
        elsif rising_edge(clk) then
            
            case hor_state is
            when 0 => -- front porch
                VGA_HS <= '1';
                h_flag <= '0';
                if hor_count < 15 then
                    hor_count <= hor_count + 1;
                else
                    hor_count <= 0;
                    hor_state <= 1;
                end if;
            when 1 => -- sync pulse
                if hor_count < 95 then
                    VGA_HS <= '0';
                    hor_count <= hor_count + 1;
                else
                    VGA_HS <= '1';
                    hor_count <= 0;
                    hor_state <= 2;
                end if;
            when 2 => -- back porch
                VGA_HS <= '1';
                if hor_count < 47 then
                    hor_count <= hor_count + 1;
                else
                    hor_count <= 0;
                    hor_state <= 3;
                    h_flag <= '1';
                end if;
            when 3 =>
                VGA_HS <= '1';
                if hor_count < 639 then
                    hor_count <= hor_count + 1;
                else
                    hor_count <= 0;
                    hor_state <= 0;
                end if;
            when others =>
                hor_state <= 0;
                hor_count <= 0;
                VGA_HS <= '1';
            end case;
        end if;
    end process;

    -- Vertical state machine
    process(clk, rst_l)
    begin
        if rst_l = '0' then
            ver_state <= 0;
            ver_count <= 0;
            line_count <= 0;
            VGA_VS <= '1';
        elsif rising_edge(clk) then 
            case ver_state is
            when 0 => -- front porch
                VGA_VS <= '1';
                v_flag <= '0';
                if ver_count < 7999 then
                    ver_count <= ver_count + 1;
                else
                    ver_count <= 0;
                    ver_state <= 1;
                end if;
            when 1 => -- sync pulse
                if ver_count < 1599 then
                    VGA_VS <= '0';
                    ver_count <= ver_count + 1;
                else
                    VGA_VS <= '1';
                    ver_count <= 0;
                    ver_state <= 2;
                end if;
            when 2 => -- back porch
                VGA_VS <= '1';
                if ver_count < 26399 then
                    ver_count <= ver_count + 1;
                else
                    ver_count <= 0;
                    ver_state <= 3;
                    v_flag <= '1';
                    line_count <= 0;
                end if;
            when 3 => -- data
                VGA_VS <= '1';
                if ver_count >= 799 and line_count >= 478 then
                    ver_state <= 0;
                    ver_count <= 0;
                else
                    if ver_count >= 799
                    then
                        line_count <= line_count + 1;
                        ver_count <= 0;
                    else
                        ver_count <= ver_count + 1;
                    end if;
                end if;
            when others =>
                ver_state <= 0;
            end case;
        end if;
    end process;

    process(clk, rst_l)
    begin
        if rst_l = '0' then
            VGA_R <= X"0";
            VGA_G <= X"0";
            VGA_B <= X"0";
            request_data <= '0';
            current_line <= "0000000000";
            data_pos <= "0000000000";
        elsif rising_edge(clk) then
            if v_flag = '1' and h_flag = '1' then
                current_line <= to_unsigned(line_count,current_line'length);
                data_pos <= to_unsigned(hor_count, data_pos'length);
                request_data <= '1';
                VGA_R <= R;
                VGA_G <= G;
                VGA_B <= B;
            else 
                request_data <= '0';
                VGA_R <= X"0";
                VGA_G <= X"0";
                VGA_B <= X"0";
            end if;
        end if;
    end process;


end architecture rtl; 
