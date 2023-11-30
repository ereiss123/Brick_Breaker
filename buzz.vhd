library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity buzz is
    port
    (
        clk    : in STD_LOGIC;                    -- 50 MHz
        buzzer : out STD_LOGIC;                   -- outputs on arduino pin 0
        rst    : in STD_LOGIC;                    -- active high
        go     : in STD_LOGIC_VECTOR (2 downto 0) -- 001 = death, 010 = paddle, 011 = top/side of screen, 100 = brick
    );
end entity buzz;

architecture rtl of buzz is
    signal counter : INTEGER := 10000; -- count for frequency to get different sounds
    signal loop_count : INTEGER := 0; -- count for how long to play sound
    signal state : STD_LOGIC := '0'; -- state machine state
begin
    process (clk, rst, go)
    begin
        if (rst = '1') then -- reset
            state <= '0';
            counter <= 0;
            buzzer <= '0';
            loop_count <= 0;
        elsif rising_edge(clk) then
            if state = '0' then -- idle. No buzzer
                if go /= "000" then
                    state <= '1';
                else
                    state <= '0';
                end if;
            elsif state = '1' then -- buzzer
                case (go) is -- different sounds for different events
                    when "001" => --death sound
                        if loop_count < 100000000 then --loop for how long to play sound
                            loop_count <= loop_count + 1;
                            if counter < 45000 then -- set buzzer to high to get sound
                                counter <= counter + 1;
                                buzzer <= '1';
                            elsif counter >= 45000 and counter < 50000 then --create low period to get sound
                                counter <= counter + 1;
                                buzzer <= '0';
                            else -- reset counter and buzzer
                                counter <= 0;
                                buzzer <= '0';
                            end if;
                        else
                            buzzer <= '0';
                            state <= '0';
                            loop_count <= 0;
                            counter <= 0;
                        end if;
                    when "010" => -- paddle
                        if loop_count < 10000000 then
                            loop_count <= loop_count + 1;
                            if counter < 5000 then
                                counter <= counter + 1;
                                buzzer <= '1';
                            elsif counter >= 5000 and counter < 500000 then
                                counter <= counter + 1;
                                buzzer <= '0';
                            else
                                counter <= 0;
                                buzzer <= '0';
                            end if;
                        else
                            buzzer <= '0';
                            state <= '0';
                            loop_count <= 0;
                            counter <= 0;
                        end if;
                    when "011" => -- top/side of screen
                        if loop_count < 10000000 then
                            loop_count <= loop_count + 1;
                            if counter < 25000 then
                                counter <= counter + 1;
                                buzzer <= '1';
                            elsif counter >= 25000 and counter < 50000 then
                                counter <= counter + 1;
                                buzzer <= '0';
                            else
                                counter <= 0;
                                buzzer <= '0';
                            end if;
                        else
                            buzzer <= '0';
                            state <= '0';
                            loop_count <= 0;
                            counter <= 0;
                        end if;
                    when "100" => --brick
                        if loop_count < 10000000 then
                            loop_count <= loop_count + 1;
                            if counter < 10000 then
                                counter <= counter + 1;
                                buzzer <= '1';
                            elsif counter >= 10000 and counter < 500000 then
                                counter <= counter + 1;
                                buzzer <= '0';
                            else
                                counter <= 0;
                                buzzer <= '0';
                            end if;
                        else
                            buzzer <= '0';
                            state <= '0';
                            loop_count <= 0;
                            counter <= 0;
                        end if;
                    when others =>
                        buzzer <= '0';
                        state <= '0';
                        loop_count <= 0;
                        counter <= 0;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;