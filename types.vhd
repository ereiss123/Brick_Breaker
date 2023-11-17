library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    -- Boundaries
    type brick is array(15 downto 0, 6 downto 0) of std_logic;
    type half_brick is array(7 downto 0, 6 downto 0) of std_logic;
    type line_v is array(8 downto 0) of std_logic;
    type line_h is array(15 downto 0) of std_logic;
    type half_line_h is array(7 downto 0) of std_logic;
    type paddle is array(39 downto 0, 4 downto 0) of std_logic;
    type ball is array(9 downto 0, 9 downto 0) of std_logic;
   
    -- Colors
    type white is array(2 downto 0) of std_logic_vector(3 downto 0) := ("0xF","0xF","0xF");
    type black is array(2 downto 0) of std_logic_vector(3 downto 0) := ("0x0","0x0","0x0");
    type brick_color is array(2 downto 0) of std_logic_vector(3 downto 0) := ("0xc","0xf","0x3") ; -- orange-ish
    type mortar_color is array(2 downto 0) of std_logic_vector(3 downto 0) := ("0xB","0x5","0x9") ; -- yellow-ish
end package breaker_types;