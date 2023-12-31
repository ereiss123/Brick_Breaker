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
   
    -- Colors
    type color is array(0 to 2) of std_logic_vector(3 downto 0);
end package types;