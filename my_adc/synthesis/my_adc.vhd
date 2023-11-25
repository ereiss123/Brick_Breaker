-- my_adc.vhd

-- Generated using ACDS version 18.1 625

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity my_adc is
	port (
		adc_pll_clock_clk      : in  std_logic                     := '0';             --  adc_pll_clock.clk
		adc_pll_locked_export  : in  std_logic                     := '0';             -- adc_pll_locked.export
		clock_clk              : in  std_logic                     := '0';             --          clock.clk
		command_valid          : in  std_logic                     := '0';             --        command.valid
		command_channel        : in  std_logic_vector(4 downto 0)  := (others => '0'); --               .channel
		command_startofpacket  : in  std_logic                     := '0';             --               .startofpacket
		command_endofpacket    : in  std_logic                     := '0';             --               .endofpacket
		command_ready          : out std_logic;                                        --               .ready
		reset_sink_reset_n     : in  std_logic                     := '0';             --     reset_sink.reset_n
		response_valid         : out std_logic;                                        --       response.valid
		response_channel       : out std_logic_vector(4 downto 0);                     --               .channel
		response_data          : out std_logic_vector(11 downto 0);                    --               .data
		response_startofpacket : out std_logic;                                        --               .startofpacket
		response_endofpacket   : out std_logic                                         --               .endofpacket
	);
end entity my_adc;

architecture rtl of my_adc is
	component my_adc_modular_adc_0 is
		generic (
			is_this_first_or_second_adc : integer := 1
		);
		port (
			clock_clk              : in  std_logic                     := 'X';             -- clk
			reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
			adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
			command_valid          : in  std_logic                     := 'X';             -- valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_ready          : out std_logic;                                        -- ready
			response_valid         : out std_logic;                                        -- valid
			response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_data          : out std_logic_vector(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component my_adc_modular_adc_0;

begin

	modular_adc_0 : component my_adc_modular_adc_0
		generic map (
			is_this_first_or_second_adc => 1
		)
		port map (
			clock_clk              => clock_clk,              --          clock.clk
			reset_sink_reset_n     => reset_sink_reset_n,     --     reset_sink.reset_n
			adc_pll_clock_clk      => adc_pll_clock_clk,      --  adc_pll_clock.clk
			adc_pll_locked_export  => adc_pll_locked_export,  -- adc_pll_locked.export
			command_valid          => command_valid,          --        command.valid
			command_channel        => command_channel,        --               .channel
			command_startofpacket  => command_startofpacket,  --               .startofpacket
			command_endofpacket    => command_endofpacket,    --               .endofpacket
			command_ready          => command_ready,          --               .ready
			response_valid         => response_valid,         --       response.valid
			response_channel       => response_channel,       --               .channel
			response_data          => response_data,          --               .data
			response_startofpacket => response_startofpacket, --               .startofpacket
			response_endofpacket   => response_endofpacket    --               .endofpacket
		);

end architecture rtl; -- of my_adc
