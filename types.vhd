library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    -- Boundaries
    type coorid is array(0 to 1) of integer;
    type hbrick_corrid is array(0 to 39) of integer;
    type hhalf_brick_corrid is array(0 to 40) of integer;
    type vbrick_corrid is array(0 to 29) of integer;
    type tracker is array(0 to 29,0 to 40) of std_logic;
    -- type brick is array(15 downto 0, 7 downto 0) of std_logic;
    -- type half_brick is array(7 downto 0, 7 downto 0) of std_logic;
    -- type half_line_h is array(7 downto 0) of std_logic;
    -- type paddle is array(39 downto 0, 4 downto 0) of std_logic;
    -- type ball is array(9 downto 0, 9 downto 0) of std_logic;
   
    -- Colors
    type color is array(0 to 2) of std_logic_vector(3 downto 0);
end package types;