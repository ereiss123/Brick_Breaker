library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC is
    port
    (
        clk : in STD_LOGIC; -- clk
        rst : in STD_LOGIC; -- reset
        data : out STD_LOGIC_VECTOR (11 downto 0)
    );
end entity ADC;

architecture rtl of ADC is
    -- //////////////////////Signals/////////////////////////
    signal areset_sig : STD_LOGIC := '0';
    signal locked_sig : STD_LOGIC;
    signal command_rdy : STD_LOGIC; -- flag to indicate that a command can be recieved
    signal command_valid : STD_LOGIC; -- indicate command is sent
    signal command_channel : STD_LOGIC_VECTOR(4 downto 0); -- set command
    signal response_valid : STD_LOGIC; -- output is ready
    signal response_channel : STD_LOGIC_VECTOR(4 downto 0); -- check which channel is ready, probably don't need
    signal response_data : STD_LOGIC_VECTOR(11 downto 0); -- holds data
    signal adc_pll_locked_export : STD_LOGIC; --ADC pll clock locked signal
    signal ADC_state : INTEGER := 0; -- state machine for ADC
    signal command_startofpacket : STD_LOGIC; -- need to figure out
    signal command_endofpacket : STD_LOGIC; -- need to figure out
    signal response_startofpacket : STD_LOGIC; -- need to figure out
    signal response_endofpacket : STD_LOGIC; -- need to figure out
    --
    -- signal data : STD_LOGIC_VECTOR(11 downto 0); -- data from adc
    signal ndata : STD_LOGIC_VECTOR(11 downto 0); -- data from adc
    signal count : INTEGER := 0; -- counter for data
    signal ncount : INTEGER := 0; -- counter for data
    signal state : INTEGER := 0; -- state machine for data
    signal nstate : INTEGER := 0; -- state machine for data

    -- Create a look up table for the 7-segment display
    type LUT is array(15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
    -- 7-segment display look up table. Not to flip bits. 7 segment display is active low.
    signal seven_seg : LUT := (not(X"71"), not(X"79"), not(X"5E"), not(X"58"), not(X"7C"), not(X"77"), X"90", X"80", X"F8", X"82", X"92", X"99", X"B0", X"A4", X"F9", X"C0");

    -- //////////////////////Components/////////////////////////
    component my_adc is
        port
        (
            clock_clk              : in STD_LOGIC                    := 'X';             -- clk
            reset_sink_reset_n     : in STD_LOGIC                    := 'X';             -- reset_n
            adc_pll_clock_clk      : in STD_LOGIC                    := 'X';             -- clk
            adc_pll_locked_export  : in STD_LOGIC                    := 'X';             -- export
            command_valid          : in STD_LOGIC                    := 'X';             -- valid
            command_channel        : in STD_LOGIC_VECTOR(4 downto 0) := (others => 'X'); -- channel
            command_startofpacket  : in STD_LOGIC                    := 'X';             -- startofpacket
            command_endofpacket    : in STD_LOGIC                    := 'X';             -- endofpacket
            command_ready          : out STD_LOGIC;                                      -- ready
            response_valid         : out STD_LOGIC;                                      -- valid
            response_channel       : out STD_LOGIC_VECTOR(4 downto 0);                   -- channel
            response_data          : out STD_LOGIC_VECTOR(11 downto 0);                  -- data
            response_startofpacket : out STD_LOGIC;                                      -- startofpacket
            response_endofpacket   : out STD_LOGIC                                       -- endofpacket
        );
    end component my_adc;


begin
    --//////////////port maps/////////////////////
    u0 : my_adc port map
    (
        clock_clk              => clk,                 --     this is the clock signal
        reset_sink_reset_n     => not rst,         --     this is the reset signal
        adc_pll_clock_clk      => clk,                 --     Singal is good. This is the clock running the adc
        adc_pll_locked_export  => locked_sig,             --     this signal is high when the pll is locked
        command_valid          => '1',                    --     command.valid
        command_channel        => "00001",                --     .channel
        command_startofpacket  => '1',                    --     .startofpacket
        command_endofpacket    => '1',                    --     .endofpacket
        command_ready          => open,            --     .ready
        response_valid         => response_valid,         --     response.valid
        response_channel       => open,       --     .channel
        response_data          => open,          --     .data
        response_startofpacket => open, --     .startofpacket
        response_endofpacket   => open    --     .endofpacket
    );

    --//////////////our stuff/////////////////////
    --take future and update it to current
    process (clk, rst)
    begin
        if (rst = '1') then
            count <= 0;
            state <= 0;
            data <= (others => '0');
        elsif rising_edge(clk) then
            case(state) is
                when 0 =>
                    if (count = 999999) then -- Update at 1 Hz
                        count <= 0;
                        state <= 1;
                    else
                        state <= 0;
                        count <= count + 1;
                    end if;
                when 1 =>
                count <= 0;
                    if response_valid = '1' then
                        state <= 0;
                        data <= response_data;
                    end if;
                when others =>
                    data <= (others => '0');
                    state <= 0;
            end case;
        end if; 
    end process;
end architecture rtl;