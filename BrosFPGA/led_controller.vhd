library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;

entity led_controller is 
	generic(
		CLEARED_HEX : std_logic_vector(6 downto 0) := "1111111"
	);
	
	port (
		CLOCK 		: in std_logic;
		RESET		: in std_logic;
		
		I_VALUE 		: in integer range 0 to 9999; -- value to print
		
		HEX0 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX2 : out std_logic_vector(6 downto 0);
		HEX3 : out std_logic_vector(6 downto 0)
	);
end entity;


architecture behav of led_controller is
	--convert to the seven segment display an integer in the [0:9] range 
	function convert(
		I_INPUT : in integer range 0 to 9 
	)
		return std_logic_vector 
	is
		variable RES : std_logic_vector(6 downto 0);
	begin
			case I_INPUT is
		--		                  gfedcba
				when 0 => RES := "1000000";
				when 1 => RES := "1111001";
				when 2 => RES := "0100100";
				when 3 => RES := "0110000";
				when 4 => RES := "0011001";
				when 5 => RES := "0010010";
				when 6 => RES := "0000010";
				when 7 => RES := "1111000";
				when 8 => RES := "0000000";
				when 9 => RES := "0010000";
			end case;
			return RES;
	 end function;

	 begin
		
	LedController : process(CLOCK, RESET)
	begin
		if RESET = '1' then
			HEX0 <= CLEARED_HEX;
			HEX1 <= CLEARED_HEX;
			HEX2 <= CLEARED_HEX;
			HEX3 <= CLEARED_HEX;
		elsif(rising_edge(CLOCK)) then
			HEX0 <= (convert(I_VALUE rem 10));
			HEX1 <= (convert((I_VALUE / 10) rem 10));
			HEX2 <= (convert((I_VALUE / 100) rem 10));
			HEX3 <= (convert(I_VALUE / 1000));
		end if;
	end process;
end architecture;
