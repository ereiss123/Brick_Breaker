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
    signal db_state : std_logic_vector(1 downto 0);
    signal button_count : integer;
begin
    process(clk, rst)
    begin
        -- Reset
        if(rst = '1') then 
            button_debounced <= '0';
            db_state <= "00";
            button_count <= 0;
        elsif(rising_edge(clk)) then
            case (db_state) is
                when "00" =>  -- idle
                    if(button = '0') then
                        db_state <= "01";
                        button_count <= 0;
                    end if;
                when "01" => -- button pressed
                    -- check if button is still pressed
                    if button = '1' then
                        db_state <= "10";
                        button_debounced <= '1'; -- set button high
                    else
                        db_state <= "01";
                    end if;
                when "10" =>
                    button_debounced <= '0'; -- set button low
                    db_state <= "00";
                when others =>
                    db_state <= "00";
            end case;
        end if;
    end process;
    
    
end architecture rtl;