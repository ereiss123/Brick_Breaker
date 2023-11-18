library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    -- Boundaries
    type coorid is array(1 downto 0) of unsigned(9 downto 0);
    type brick is array(15 downto 0, 7 downto 0) of std_logic;
    type half_brick is array(7 downto 0, 7 downto 0) of std_logic;
    type half_line_h is array(7 downto 0) of std_logic;
    type paddle is array(39 downto 0, 4 downto 0) of std_logic;
    type ball is array(9 downto 0, 9 downto 0) of std_logic;
   
    -- Colors
    type color is array(2 downto 0) of std_logic_vector(3 downto 0);
end package types;