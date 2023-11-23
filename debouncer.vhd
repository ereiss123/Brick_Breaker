library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is 
    port (
        clk : in std_logic;
        rst : in std_logic;
        button : in std_logic;
        button_debounced : out std_logic
    );
end debouncer;

architecture rtl of debouncer is
    signal db_state : integer range 0 to 4;
    signal bounce_count : integer;
begin
    process(clk, rst) 
    begin
        if rst = '1' then 
            db_state <= 0;
            bounce_count <= 0;
        elsif rising_edge(clk)then 
            case db_state is
                when 0 => -- Wait
                    if button = '0' then
                        db_state <= 1;
                    end if;
                when 1 => -- debounce
                    bounce_count <= bounce_count + 1;
                    if bounce_count >= 50000 then
                        db_state <= 2;
                    end if;
                when 2 => -- send
                    button_debounced <= '1';
                    db_state <= 3;
                when 3 => -- wait for release
                    button_debounced <= '0';
                    bounce_count <= 0;
                    if button = '1' then
                        db_state <= 4;
                    end if;
                when 4 => -- buffer
                    bounce_count <= bounce_count + 1;
                    if bounce_count >= 50000 then
                        db_state <= 0;
                    end if;
                when others =>
                    db_state <= 0;

            end case;
        end if;
    end process;

   
    
    
end architecture rtl;