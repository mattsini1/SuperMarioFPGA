library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.vga_package.all;
use work.level_package.all;

entity memory_mapper is 
	generic (
		SCREEN_HEIGHT : natural := VISIBLE_HEIGHT; -- screen max height (480)
		SCREEN_WIDTH : natural := VISIBLE_WIDTH; -- screen max width (640)
		MAX_RAM_RAPRESENTATION_HEIGHT : natural := GAME_HEIGHT/2 + 50; -- ram max height --50 padding
		MAX_RAM_RAPRESENTATION_WIDTH : natural := GAME_WIDTH/2 + 50; -- ram max width
		SCALE_FACTOR_FOR_RAM : natural := 2; -- scale factor
		OVERFLOW_GUARD : natural := 10; -- overflow guard;
		
		MAX_RAM_ADDRESS : std_logic_vector(17 downto 0) := (others => '1') -- max ram address
	);
	
	port (
		CLOCK : in std_logic; -- clock in
		RESET : in std_logic; -- reset async
		
		I_X_TO_CHECK : in natural; -- x coordinate
		I_Y_TO_CHECK : in natural; -- y coordinate
		I_CE : in std_logic; -- chip enable
		
		I_CURRENT_LEVEL_NUMBER : in integer;
		I_STATE : in mario_state;
			
		O_LEVEL_LOADED_DONE : out std_logic;
		
		O_DATA_FROM_MEMORY : out std_logic_vector(15 downto 0); -- data out for the debug
		O_IS_UPDATING : out std_logic; -- if the memory is resetting;
		
		-- ram mapping
		SRAM_ADDR : out std_logic_vector(17 downto 0);
		SRAM_DQ : inout std_logic_vector(15 downto 0);
		SRAM_CE_N : out std_logic;
		SRAM_OE_N : out std_logic;
		SRAM_WE_N : out std_logic;
		SRAM_UB_N : out std_logic;
		SRAM_LB_N : out std_logic
	);
end entity;

architecture behav of memory_mapper is
	constant CLEARED_RAM : std_logic_vector(15 downto 0) := (others => '0'); -- desribes how cleared ram looks;
	
	signal S_RESET : boolean; -- if in the last clock we had a reset;
	signal S_RESET_ADDR : natural range 0 to MAX_RAM_RAPRESENTATION_HEIGHT * MAX_RAM_RAPRESENTATION_WIDTH + OVERFLOW_GUARD; -- counter for the current ram address for the soft reset
	
	signal S_READ : std_logic_vector(15 downto 0); -- data read by process
	-- signal from/to sram_controller
	signal S_DATA_IN_SRAM : std_logic_vector(15 downto 0); -- data in to sram controller
	signal S_DATA_OUT_SRAM : std_logic_vector(15 downto 0); -- data out from sram controller
	signal S_ACTION_TO_PERFORM_SRAM : std_logic; -- action the controller have to do (0 to read, 1 to write)
	signal S_ADDR : std_logic_vector(17 downto 0); -- address to read/write
	signal S_CE : std_logic;
	signal S_MAPPING_IN_RAM : std_logic;
	
	signal S_CURRENT_LEVEL : natural;
	
	type T_COORDS is array (0 to 60) of natural range 0 to GAME_WIDTH;
		
	signal S_BLOCKS_ARRAY_COUNTER : natural range 0 to NUM_BLOCKS + OVERFLOW_GUARD := 0; -- cycle on the all block array (cycle on all blocks)
	signal S_ROW_COUNTER : natural range 0 to BLOCK_HEIGHT + OVERFLOW_GUARD := 0; -- cycle on the row of the block
	signal S_COLUMN_COUNTER : natural range 0 to BLOCK_WIDTH + OVERFLOW_GUARD := 0; -- cycle on the column of the block
	signal S_INIT_DONE : boolean := false; -- signals that the injection of the blocks in the sram
			
	-- conversion between integer to std_logic_vector
	pure function to_logic_vector(
		input : natural
	)
		return std_logic_vector
	is begin
		return std_logic_vector(to_unsigned(input, 18));
	end function;
	
	-- converts the (x, y) coordinates to an address (integer)
	pure function translate(
		x : natural range 0 to MAX_RAM_RAPRESENTATION_WIDTH; -- 320
		y : natural range 0 to MAX_RAM_RAPRESENTATION_HEIGHT -- 240
	)
		return natural
	is begin
		return y * MAX_RAM_RAPRESENTATION_HEIGHT + x; -- column number * element in a column + row number
	end function;
	
	-- reduce the coordinate by his factor of scaling (2)
	pure function compress(
		input : natural range 0 to SCREEN_WIDTH -- 640
	)
		return natural
	is begin
		return (input + SCALE_FACTOR_FOR_RAM / 2) / SCALE_FACTOR_FOR_RAM; -- halves the value (e.g. 0 and 1 are mapped to 0, 2 and 3 are mapped to 2)
		-- this is a smart way to do a/b and approssimate its value to integer conversion
		-- [(a / b) == ((a + b / 2) / b)]
	end function;
	
	-- main function to convert a coordinate to an addres (logic vector)
	pure function position_to_address(
		x : natural range 0 to SCREEN_WIDTH; -- 640
		y : natural range 0 to SCREEN_HEIGHT -- 480
	)
		return std_logic_vector	-- translated pure ram address
	is	
		variable compressed_x : natural range 0 to MAX_RAM_RAPRESENTATION_WIDTH; -- compressed x value
		variable compressed_y : natural range 0 to MAX_RAM_RAPRESENTATION_HEIGHT; -- compressed y value
		variable decimal_address : natural range 0 to MAX_RAM_RAPRESENTATION_WIDTH * MAX_RAM_RAPRESENTATION_HEIGHT; -- translated decimal address
	begin
			compressed_x := compress(x);
			compressed_y := compress(y);
			decimal_address := translate(compressed_x, compressed_y);
			return to_logic_vector(decimal_address);
	end function;
	-- writes in an address a passed data;
	procedure write_ram(
		data : in std_logic_vector(15 downto 0); -- data in
		a : in std_logic_vector(17 downto 0); -- address to write
		signal S_ACTION_TO_PERFORM_SRAM : out std_logic;
		signal S_DATA_IN_SRAM : out std_logic_vector(15 downto 0);
		signal S_ADDR : out std_logic_vector(17 downto 0)
	)
	is	begin
		S_ADDR <= a;
		S_ACTION_TO_PERFORM_SRAM <= '1'; -- writes
		S_DATA_IN_SRAM <= data;
	end procedure;
	-- writes a block in ram
	procedure write_block(
		bl : in T_BL; -- data in
		x : natural range 0 to SCREEN_WIDTH; -- 640
		y : natural range 0 to SCREEN_HEIGHT; -- 480
		signal S_ACTION_TO_PERFORM_SRAM : out std_logic;
		signal S_DATA_IN_SRAM : out std_logic_vector(15 downto 0);
		signal S_ADDR : out std_logic_vector(17 downto 0)
	)
	is	begin
		write_ram(bl.repr, to_logic_vector(translate(compress(x), compress(y))), S_ACTION_TO_PERFORM_SRAM, S_DATA_IN_SRAM, S_ADDR); 
	end procedure;
	begin
	-- internal memory controller for the sram
	sram : entity work.sram_controller
		port map(
			CLOCK => clock,
			RESET => RESET,
			-- internal signals
			ACTION => S_ACTION_TO_PERFORM_SRAM, -- 0 to read, 1 to write
			DATA_OUT => S_DATA_OUT_SRAM,
			DATA_IN => S_DATA_IN_SRAM,
			ADDR => S_ADDR,
			I_CE => S_CE,
			-- rewire to sram in/outputs
			SRAM_ADDR => SRAM_ADDR,
			SRAM_DQ   => SRAM_DQ,			
			SRAM_CE_N => SRAM_CE_N,
			SRAM_OE_N => SRAM_OE_N,
			SRAM_WE_N => SRAM_WE_N,
			SRAM_UB_N => SRAM_UB_N,
			SRAM_LB_N => SRAM_LB_N	
		);
	
	MapperProcess : process(CLOCK, RESET)	
	begin
	if rising_edge(CLOCK) then
			O_LEVEL_LOADED_DONE <= '0';
			if S_RESET then -- soft reset in place
				if S_RESET_ADDR < MAX_RAM_RAPRESENTATION_HEIGHT * MAX_RAM_RAPRESENTATION_WIDTH then
					write_ram(CLEARED_RAM, to_logic_vector(S_RESET_ADDR), S_ACTION_TO_PERFORM_SRAM, S_DATA_IN_SRAM, S_ADDR); -- clears the S_RESET_ADDR-nth byte of the ram;
					S_RESET_ADDR <= S_RESET_ADDR + 1; -- set the new address to erase;
				else
					S_RESET <= false; -- tells to stop reset;
					S_MAPPING_IN_RAM <= '1'; -- starts remapping;
				end if;
			elsif S_MAPPING_IN_RAM = '1' then
				if not S_INIT_DONE then -- while the mapping is flowing, proceed writing blocks
					write_block(R_BORDER, GAME(S_CURRENT_LEVEL)(S_BLOCKS_ARRAY_COUNTER).x + S_COLUMN_COUNTER, GAME(S_CURRENT_LEVEL)(S_BLOCKS_ARRAY_COUNTER).y + S_ROW_COUNTER, S_ACTION_TO_PERFORM_SRAM, S_DATA_IN_SRAM, S_ADDR);
				else
					S_MAPPING_IN_RAM <= '0'; -- stop the mapping
					O_IS_UPDATING <= '0'; -- we are not resetting anymore
					O_LEVEL_LOADED_DONE <= '1'; -- confirm new level loading
				end if;
			elsif I_STATE = LOAD_LEVEL then -- if the current state is the changing level state
				S_RESET <= true; -- start soft resetting
				S_RESET_ADDR <= 0; -- reset address reset
				S_CURRENT_LEVEL <= I_CURRENT_LEVEL_NUMBER; -- buffer the current
				S_MAPPING_IN_RAM <= '0'; -- assure the map is not enabled
				O_IS_UPDATING <= '1'; -- comunicate we are updating
			elsif I_CE = '1' then -- chip is enabled
				S_CE <= '1';
				S_ADDR <= position_to_address(I_X_TO_CHECK, I_Y_TO_CHECK); -- reads at (x, y) position;
				S_ACTION_TO_PERFORM_SRAM <= '0'; -- reads;
				O_DATA_FROM_MEMORY <= S_DATA_OUT_SRAM; -- outputs the read value;
			elsif I_CE = '0' then
				S_CE <= '0';
			end if;
		end if;
	end process;

	InitProcess : process(CLOCK, RESET)
	-- generates all block coordinates
	begin
		if RESET = '1' then
			S_BLOCKS_ARRAY_COUNTER <= 0;
			S_ROW_COUNTER <= 0;
			S_COLUMN_COUNTER <= 0;
			S_INIT_DONE <= false;
			
		elsif rising_edge(CLOCK) then
			if S_MAPPING_IN_RAM = '1' then
				S_INIT_DONE <= false; -- assure the mapping is not finished
				if S_BLOCKS_ARRAY_COUNTER < NUM_BLOCKS then -- if there are other blocks	
					if S_COLUMN_COUNTER < BLOCK_WIDTH then
						S_COLUMN_COUNTER <= S_COLUMN_COUNTER + SCALE_FACTOR_FOR_RAM; -- skips because of the ram mapping
					else
						S_COLUMN_COUNTER <= 0; -- column finished
						if S_ROW_COUNTER < BLOCK_HEIGHT then
							S_ROW_COUNTER <= S_ROW_COUNTER + SCALE_FACTOR_FOR_RAM; -- skips because of the ram mapping
						else
							S_ROW_COUNTER <= 0; -- row finished
							S_BLOCKS_ARRAY_COUNTER <= S_BLOCKS_ARRAY_COUNTER + 1; -- iterate to the next block
						end if;
					end if;	
				else
					S_INIT_DONE <= true; -- the mapping is done
					S_ROW_COUNTER <= 0; -- reset the row counter
					S_COLUMN_COUNTER <= 0; -- reset the column counter
					S_BLOCKS_ARRAY_COUNTER <= 0; -- reset the array block
				end if;	--	if(S_BLOCKS_ARRAY_COUNTER = NUM_BLOCKS)			
			end if;
		end if; -- if(rising_edge(CLOCK))
	end process;
	
end architecture;