library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity VGA_controller is
    port (
        MAX10_CLK1_50 : in std_logic;
        KEY : in std_logic_vector(1 downto 0);
        VGA_B : out std_logic_vector(3 downto 0);
        VGA_G : out std_logic_vector(3 downto 0);
        VGA_R : out std_logic_vector(3 downto 0);
        VGA_HS : out std_logic;
        VGA_VS : out std_logic
    );
end entity VGA;

architecture rtl of VGA_controller is
    signal areset_sig : std_logic;
    signal inclk0_sig : std_logic;
    signal c0_sig : std_logic;
    signal locked_sig : std_logic;

    signal horizontal_counter : integer := 0;
    signal vertical_counter : integer := 0;
    signal advance : std_logic := '0';
    signal aclr_sig : std_logic := '0';
    signal db_state : std_logic_vector(1 downto 0) := "00";
    signal button_count : integer := 0;

    signal flag_state : integer := 0;
    
    signal hor_state : integer := 0;
    signal ver_state : integer := 0;
    signal line_count : integer := 0;
    
component PLL
PORT
(
    areset		: IN STD_LOGIC  := '0';
    inclk0		: IN STD_LOGIC  := '0';
    c0		: OUT STD_LOGIC ;
    locked		: OUT STD_LOGIC 
);
end component;

begin
PLL_inst : PLL PORT MAP 
(
    areset	 => areset_sig,
    inclk0	 => MAX10_CLK1_50,
    c0	 => c0_sig,
    locked	 => locked_sig
);
    
    areset_sig <= '1' when KEY(0) = '0' else '0'; -- asynchronous clear signal
    aclr_sig <= not(locked_sig); -- asynchronous clear signal

-- Debounce KEY(1)
    process(c0_sig, aclr_sig)
    begin
        -- Reset
        if(aclr_sig = '1') then 
            advance <= '0';
            db_state <= "00";
            button_count <= 0;
        elsif(rising_edge(c0_sig)) then
            case (db_state) is
                when "00" =>  -- idle
                    if(KEY(1) = '0') then
                        db_state <= "01";
                        button_count <= 0;
                    end if;
                when "01" => -- button pressed
                    -- check if button is still pressed
                    if KEY(1) = '1' then
                        db_state <= "10";
                        advance <= '1'; -- set button high
                    else
                        db_state <= "01";
                    end if;
                when "10" =>
                    advance <= '0'; -- set button low
                    db_state <= "00";
                when others =>
                    db_state <= "00";
            end case;
        end if;
    end process;

    -- Horizontal state machine
    process(c0_sig, advance, aclr_sig)
    begin
        if aclr_sig = '1' then
            horizontal_counter <= 0;
            hor_state <= 0;
            VGA_HS <= '0';
        elsif rising_edge(c0_sig) then
            case hor_state is
            when 0 => -- front porch
                if horizontal_counter < 15 then
                    horizontal_counter <= horizontal_counter + 1;
                else
                    horizontal_counter <= 0;
                    hor_state <= 1;
                end if;
            when 1 => -- sync pulse
                if horizontal_counter < 95 then
                    VGA_HS <= '0';
                    horizontal_counter <= horizontal_counter + 1;
                else
                    VGA_HS <= '1';
                    horizontal_counter <= 0;
                    hor_state <= 2;
                end if;
            when 2 => -- back porch
                if horizontal_counter < 47 then
                    horizontal_counter <= horizontal_counter + 1;
                else
                    horizontal_counter <= 0;
                    hor_state <= 3;
                end if;
            when 3 =>
                if horizontal_counter < 639 then
                    horizontal_counter <= horizontal_counter + 1;
                else
                    horizontal_counter <= 0;
                    hor_state <= 0;
                end if;
            when others =>
                hor_state <= 0;
            end case;
        end if;
    end process;

    -- Vertical state machine
    process(c0_sig, aclr_sig)
    begin
        if aclr_sig = '1' then
            vertical_counter <= 0;
            ver_state <= 0;
            VGA_VS <= '0';
            line_count <= 0;
        elsif rising_edge(c0_sig) then
            case ver_state is
            when 0 => -- front porch
                if vertical_counter < 7999 then
                    vertical_counter <= vertical_counter + 1;
                else
                    vertical_counter <= 0;
                    ver_state <= 1;
                end if;
            when 1 => -- sync pulse
                if vertical_counter < 1599 then
                    VGA_VS <= '0';
                    vertical_counter <= vertical_counter + 1;
                else
                    VGA_VS <= '1';
                    vertical_counter <= 0;
                    ver_state <= 2;
                end if;
            when 2 => -- back porch
                if vertical_counter < 26399 then
                    vertical_counter <= vertical_counter + 1;
                else
                    vertical_counter <= 0;
                    ver_state <= 3;
                    line_count <= 0;
                end if;
            when 3 => -- data
                if vertical_counter >= 799 and line_count >= 478 then
                    ver_state <= 0;
                    vertical_counter <= 0;
                else
                    if vertical_counter >= 799
                    then
                        line_count <= line_count + 1;
                        vertical_counter <= 0;
                    else
                        vertical_counter <= vertical_counter + 1;
                    end if;
                end if;
            when others =>
                ver_state <= 0;
            end case;
        end if;
    end process;

    process(c0_sig,advance,hor_state,ver_state, aclr_sig)
    begin
        if aclr_sig = '1' then
            VGA_R <= X"f";
            VGA_G <= X"a";
            VGA_B <= X"0";
            flag_state <= 0;
        elsif rising_edge(c0_sig) then
            if hor_state = 3 and ver_state = 3 then
                case flag_state is 
                    when 0 => -- FRANCE (surrender)
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"0";
                                VGA_B <= X"f";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 1 => -- ITALY
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"a";
                                VGA_B <= X"0";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 2 => -- IRELAND
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"F";
                                VGA_G <= X"7";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 3 => -- BELGIUM
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            else 
                                VGA_R <= X"F";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 4 => -- MALI
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"f";
                                VGA_B <= X"4";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            else 
                                VGA_R <= X"F";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 5 => -- CHAD
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"0";
                                VGA_B <= X"f";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            else 
                                VGA_R <= X"F";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 6 => -- NIGERIA
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"0";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"0";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 7 => -- IVORY COAST
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if horizontal_counter < 213 then
                                VGA_R <= X"F";
                                VGA_G <= X"b";
                                VGA_B <= X"0";
                            elsif horizontal_counter < 426 and horizontal_counter >= 213 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"0";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 8 => -- POLAND
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if line_count < 240 then
                                VGA_R <= X"F";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 9 => -- GERMANY
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if line_count < 160 then
                                VGA_R <= X"0";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            elsif line_count < 320 and line_count >= 160 then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            else 
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 10 => -- AUSTRIA
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if line_count < 160 then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            elsif line_count < 320 and line_count >= 160 then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                            else 
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 11 => -- DRC
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if (horizontal_counter + line_count < 428) then
                                VGA_R <= X"0";
                                VGA_G <= X"9";
                                VGA_B <= X"1";
                            elsif (horizontal_counter + line_count < 640) then
                                VGA_R <= X"e";
                                VGA_G <= X"e";
                                VGA_B <= X"1";
                            else 
                                VGA_R <= X"d";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when 12 => -- USA!!!!!!!!!!!!!!
                        if advance = '1' then
                            flag_state <= flag_state + 1;
                        else
                            if (line_count < 259 and horizontal_counter < 300) then
                                if ((line_count = 9 or line_count = 64 or line_count = 119 or line_count = 174 or line_count = 229) and (horizontal_counter = 25 or horizontal_counter = 75 or horizontal_counter = 125 or horizontal_counter = 175 or horizontal_counter = 225 or horizontal_counter = 275)) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 10 or line_count = 65 or line_count = 120 or line_count = 175 or line_count = 230) and ((horizontal_counter >= 24 and horizontal_counter <= 26) or (horizontal_counter >= 74 and horizontal_counter <= 76) or (horizontal_counter >= 124 and horizontal_counter <= 126) or (horizontal_counter >= 174 and horizontal_counter <= 176) or (horizontal_counter >= 224 and horizontal_counter <= 226) or (horizontal_counter >= 274 and horizontal_counter <= 276))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 11 or line_count = 66 or line_count = 121 or line_count = 176 or line_count = 231) and ((horizontal_counter >= 24 and horizontal_counter <= 26) or (horizontal_counter >= 74 and horizontal_counter <= 76) or (horizontal_counter >= 124 and horizontal_counter <= 126) or (horizontal_counter >= 174 and horizontal_counter <= 176) or (horizontal_counter >= 224 and horizontal_counter <= 226) or (horizontal_counter >= 274 and horizontal_counter <= 276))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 12 or line_count = 67 or line_count = 122 or line_count = 177 or line_count = 232) and ((horizontal_counter >= 23 and horizontal_counter <= 27) or (horizontal_counter >= 73 and horizontal_counter <= 77) or (horizontal_counter >= 123 and horizontal_counter <= 127) or (horizontal_counter >= 173 and horizontal_counter <= 177) or (horizontal_counter >= 223 and horizontal_counter <= 227) or (horizontal_counter >= 273 and horizontal_counter <= 277))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 13 or line_count = 68 or line_count = 123 or line_count = 178 or line_count = 233) and ((horizontal_counter >= 19 and horizontal_counter <= 31) or (horizontal_counter >= 69 and horizontal_counter <= 81) or (horizontal_counter >= 119 and horizontal_counter <= 131) or (horizontal_counter >= 169 and horizontal_counter <= 181) or (horizontal_counter >= 219 and horizontal_counter <= 231) or (horizontal_counter >= 269 and horizontal_counter <= 281))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 14 or line_count = 69 or line_count = 124 or line_count = 179 or line_count = 234) and ((horizontal_counter >= 20 and horizontal_counter <= 30) or (horizontal_counter >= 70 and horizontal_counter <= 80) or (horizontal_counter >= 120 and horizontal_counter <= 130) or (horizontal_counter >= 170 and horizontal_counter <= 180) or (horizontal_counter >= 220 and horizontal_counter <= 230) or (horizontal_counter >= 270 and horizontal_counter <= 280))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 15 or line_count = 70 or line_count = 125 or line_count = 180 or line_count = 235) and ((horizontal_counter >= 20 and horizontal_counter <= 30) or (horizontal_counter >= 70 and horizontal_counter <= 80) or (horizontal_counter >= 120 and horizontal_counter <= 130) or (horizontal_counter >= 170 and horizontal_counter <= 180) or (horizontal_counter >= 220 and horizontal_counter <= 230) or (horizontal_counter >= 270 and horizontal_counter <= 280))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 16 or line_count = 71 or line_count = 126 or line_count = 181 or line_count = 236) and ((horizontal_counter >= 21 and horizontal_counter <= 29) or (horizontal_counter >= 71 and horizontal_counter <= 79) or (horizontal_counter >= 121 and horizontal_counter <= 129) or (horizontal_counter >= 171 and horizontal_counter <= 179) or (horizontal_counter >= 221 and horizontal_counter <= 229) or (horizontal_counter >= 271 and horizontal_counter <= 279))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 17 or line_count = 72 or line_count = 127 or line_count = 182 or line_count = 237) and ((horizontal_counter >= 22 and horizontal_counter <= 28) or (horizontal_counter >= 72 and horizontal_counter <= 78) or (horizontal_counter >= 122 and horizontal_counter <= 128) or (horizontal_counter >= 172 and horizontal_counter <= 178) or (horizontal_counter >= 222 and horizontal_counter <= 228) or (horizontal_counter >= 272 and horizontal_counter <= 278))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 18 or line_count = 73 or line_count = 128 or line_count = 183 or line_count = 238) and ((horizontal_counter >= 21 and horizontal_counter <= 24) or (horizontal_counter >= 26 and horizontal_counter <= 29) or (horizontal_counter >= 71 and horizontal_counter <= 74) or (horizontal_counter >= 76 and horizontal_counter <= 79) or (horizontal_counter >= 121 and horizontal_counter <= 124) or (horizontal_counter >= 126 and horizontal_counter <= 129) or (horizontal_counter >= 171 and horizontal_counter <= 174) or (horizontal_counter >= 176 and horizontal_counter <= 179) or (horizontal_counter >= 221 and horizontal_counter <= 224) or (horizontal_counter >= 226 and horizontal_counter <= 229) or (horizontal_counter >= 271 and horizontal_counter <= 274) or (horizontal_counter >= 276 and horizontal_counter <= 279))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 19 or line_count = 74 or line_count = 129 or line_count = 184 or line_count = 239) and ((horizontal_counter >= 21 and horizontal_counter <= 22) or (horizontal_counter >= 28 and horizontal_counter <= 29) or (horizontal_counter >= 71 and horizontal_counter <= 72) or (horizontal_counter >= 78 and horizontal_counter <= 79) or (horizontal_counter >= 121 and horizontal_counter <= 122) or (horizontal_counter >= 128 and horizontal_counter <= 129) or (horizontal_counter >= 171 and horizontal_counter <= 172) or (horizontal_counter >= 178 and horizontal_counter <= 179) or (horizontal_counter >= 221 and horizontal_counter <= 222) or (horizontal_counter >= 228 and horizontal_counter <= 229) or (horizontal_counter >= 271 and horizontal_counter <= 272) or (horizontal_counter >= 278 and horizontal_counter <= 279))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            ---change hor spot for these
                            elsif ((line_count = 37 or line_count = 92 or line_count = 147 or line_count = 202) and (horizontal_counter = 50 or horizontal_counter = 100 or horizontal_counter = 150 or horizontal_counter = 200 or horizontal_counter = 250)) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 38 or line_count = 93 or line_count = 148 or line_count = 203) and ((horizontal_counter >= 49 and horizontal_counter <= 51) or (horizontal_counter >= 99 and horizontal_counter <= 101) or (horizontal_counter >= 149 and horizontal_counter <= 151) or (horizontal_counter >= 199 and horizontal_counter <= 201) or (horizontal_counter >= 249 and horizontal_counter <= 251))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 39 or line_count = 94 or line_count = 149 or line_count = 204) and ((horizontal_counter >= 49 and horizontal_counter <= 51) or (horizontal_counter >= 99 and horizontal_counter <= 101) or (horizontal_counter >= 149 and horizontal_counter <= 151) or (horizontal_counter >= 199 and horizontal_counter <= 201) or (horizontal_counter >= 249 and horizontal_counter <= 251))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 40 or line_count = 95 or line_count = 150 or line_count = 205) and ((horizontal_counter >= 48 and horizontal_counter <= 52) or (horizontal_counter >= 98 and horizontal_counter <= 102) or (horizontal_counter >= 148 and horizontal_counter <= 152) or (horizontal_counter >= 198 and horizontal_counter <= 202) or (horizontal_counter >= 248 and horizontal_counter <= 252))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 41 or line_count = 96 or line_count = 151 or line_count = 206) and ((horizontal_counter >= 44 and horizontal_counter <= 56) or (horizontal_counter >= 94 and horizontal_counter <= 106) or (horizontal_counter >= 144 and horizontal_counter <= 156) or (horizontal_counter >= 194 and horizontal_counter <= 206) or (horizontal_counter >= 244 and horizontal_counter <= 256))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 42 or line_count = 97 or line_count = 152 or line_count = 207) and ((horizontal_counter >= 45 and horizontal_counter <= 55) or (horizontal_counter >= 95 and horizontal_counter <= 105) or (horizontal_counter >= 145 and horizontal_counter <= 155) or (horizontal_counter >= 195 and horizontal_counter <= 205) or (horizontal_counter >= 245 and horizontal_counter <= 255))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 43 or line_count = 98 or line_count = 153 or line_count = 208) and ((horizontal_counter >= 45 and horizontal_counter <= 55) or (horizontal_counter >= 95 and horizontal_counter <= 105) or (horizontal_counter >= 145 and horizontal_counter <= 155) or (horizontal_counter >= 195 and horizontal_counter <= 205) or (horizontal_counter >= 245 and horizontal_counter <= 255))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 44 or line_count = 99 or line_count = 154 or line_count = 209) and ((horizontal_counter >= 46 and horizontal_counter <= 54) or (horizontal_counter >= 96 and horizontal_counter <= 104) or (horizontal_counter >= 146 and horizontal_counter <= 154) or (horizontal_counter >= 196 and horizontal_counter <= 204) or (horizontal_counter >= 246 and horizontal_counter <= 254))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 45 or line_count = 100 or line_count = 155 or line_count = 210) and ((horizontal_counter >= 47 and horizontal_counter <= 53) or (horizontal_counter >= 97 and horizontal_counter <= 103) or (horizontal_counter >= 147 and horizontal_counter <= 153) or (horizontal_counter >= 197 and horizontal_counter <= 203) or (horizontal_counter >= 247 and horizontal_counter <= 253))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 46 or line_count = 101 or line_count = 156 or line_count = 211) and ((horizontal_counter >= 46 and horizontal_counter <= 49) or (horizontal_counter >= 51 and horizontal_counter <= 54) or (horizontal_counter >= 96 and horizontal_counter <= 99) or (horizontal_counter >= 101 and horizontal_counter <= 104) or (horizontal_counter >= 146 and horizontal_counter <= 149) or (horizontal_counter >= 151 and horizontal_counter <= 154) or (horizontal_counter >= 146 and horizontal_counter <= 149) or (horizontal_counter >= 151 and horizontal_counter <= 154) or (horizontal_counter >= 196 and horizontal_counter <= 199) or (horizontal_counter >= 201 and horizontal_counter <= 204) or (horizontal_counter >= 246 and horizontal_counter <= 249) or (horizontal_counter >= 251 and horizontal_counter <= 254))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            elsif ((line_count = 47 or line_count = 102 or line_count = 157 or line_count = 212) and ((horizontal_counter >= 46 and horizontal_counter <= 47) or (horizontal_counter >= 53 and horizontal_counter <= 54) or (horizontal_counter >= 96 and horizontal_counter <= 97) or (horizontal_counter >= 103 and horizontal_counter <= 104) or (horizontal_counter >= 146 and horizontal_counter <= 147) or (horizontal_counter >= 153 and horizontal_counter <= 154) or (horizontal_counter >= 146 and horizontal_counter <= 147) or (horizontal_counter >= 153 and horizontal_counter <= 154) or (horizontal_counter >= 196 and horizontal_counter <= 197) or (horizontal_counter >= 203 and horizontal_counter <= 204) or (horizontal_counter >= 246 and horizontal_counter <= 247) or (horizontal_counter >= 253 and horizontal_counter <= 254))) then
                                VGA_R <= X"F";
                                VGA_G <= X"F";
                                VGA_B <= X"F";
                            else
                                VGA_R <= X"0";
                                VGA_G <= X"2";
                                VGA_B <= X"6"; 
                            end if;
                                
                            -- //////////////stripes/////////////
                            elsif (line_count < 37) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            elsif (line_count < 74) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 111) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                             elsif (line_count < 148) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 185) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                             elsif (line_count < 222) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 259) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                             elsif (line_count < 296) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 333) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                             elsif (line_count < 370) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 407) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                             elsif (line_count < 444) then
                                VGA_R <= X"f";
                                VGA_G <= X"f";
                                VGA_B <= X"f";
                             elsif (line_count < 480) then
                                VGA_R <= X"f";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            else 
                                VGA_R <= X"d";
                                VGA_G <= X"0";
                                VGA_B <= X"0";
                            end if;
                        end if;
                    when others =>
                        flag_state <= 0;
                end case;
                else 
                    VGA_R <= X"0";
                    VGA_G <= X"0";
                    VGA_B <= X"0";
                end if;
            end if;
    end process;
end architecture rtl; 