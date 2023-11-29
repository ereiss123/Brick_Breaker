library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity buzz is
    port
    (
        clk    : in STD_LOGIC;
        buzzer : out STD_LOGIC;
        rst    : in STD_LOGIC;
        go     : in STD_LOGIC
    );
end entity buzz;

architecture rtl of buzz is
    signal counter : INTEGER := 10000;
    signal loop_count : INTEGER := 0;
    signal state : STD_LOGIC := '0';
begin
    process (clk, rst, go)
    begin
        if (rst = '1') then
            state <= '0';
            counter <= 0;
            buzzer <= '0';
            loop_count <= 0;
        elsif rising_edge(clk) then
            if state = '0' then
                if go = '1' then
                    state <= '1';
                else
                    state <= '0';
                end if;
            elsif state = '1' then
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
            end if;
        end if;
    end process;
end architecture rtl;