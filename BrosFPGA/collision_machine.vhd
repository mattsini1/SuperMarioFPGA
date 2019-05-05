library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.vga_package.all;

entity collision_machine is 
	generic (
		MARIOHEIGHT : natural := MARIO_HEIGHT; -- mario height
		MARIOWIDTH : natural := MARIO_WIDTH; -- mario width
		SCREEN_HEIGHT : natural := VISIBLE_HEIGHT; -- screen max height (480)
		SCREEN_WIDTH : natural := VISIBLE_WIDTH; -- screen max width (640)
		TOP_BORDER : natural := BOUND_TOP; -- top border
		LEFT_BORDER : natural := BOUND_LEFT; -- left border
		RIGTH_BORDER : natural := BOUND_RIGHT; -- right border
		BOTTOM_BORDER : natural := BOUND_BOTTOM; -- bottom border
		
--		mario's chek point												--   ___P1___
		HALF_MARIO_HEIGHT : natural := MARIO_HEIGHT/2;					--  |        |
		HALF_MARIO_WIDTH : natural :=	MARIO_WIDTH/2;					--  |        |
		THIRD_MARIO_WIDTH : natural :=	MARIO_WIDTH/3	  			    --  P2      P3
																		--  |        |
																		--  |___P4___|
	);
	
	port (
		CLOCK : in std_logic; -- clock in
		RESET : in std_logic; -- reset async
		
		I_X_TO_CHECK : in natural; -- x coordinate
		I_Y_TO_CHECK : in natural; -- y coordinate
		I_CE : in std_logic; -- chip enable
		
		I_REQUEST_LEFT_COLLISION : in std_logic;
		I_REQUEST_RIGHT_COLLISION : in std_logic;
		I_REQUEST_BOTTOM_COLLISION : in std_logic;
		I_REQUEST_TOP_COLLISION : in std_logic;
				
		I_CURRENT_LEVEL_NUMBER : in integer;
		I_STATE : in mario_state;
			
		O_LEVEL_LOADED_DONE : out std_logic;
		
		O_COLLISION_LEFT : out std_logic; -- left collision
		O_COLLISION_RIGHT : out std_logic; -- right collision
		O_COLLISION_TOP : out std_logic; -- top collision
		O_COLLISION_BOTTOM : out std_logic; -- bottom collision
		
--		O_COLL_OBJ : out T_COLL_OBJ;
		
		D_OUT : out std_logic_vector(5 downto 0);
		
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

architecture behav of collision_machine is

		signal S_DATA_FROM_MEMORY : std_logic_vector(15 downto 0); -- data out from the memory_mapper
		signal S_IS_UPDATING : std_logic; -- if the memory_mapper is resetting;
		signal S_X_TO_CHECK : natural range 0 to SCREEN_WIDTH;
		signal S_Y_TO_CHECK : natural range 0 to SCREEN_HEIGHT;
		signal S_CURRENT_ITERATION : natural range 0 to 6; -- iteration to read the ram
				
		procedure check_point(
			x : natural range 0 to SCREEN_WIDTH; -- x point to check
			y : natural range 0 to SCREEN_HEIGHT; -- y point to check
			output : out std_logic; -- output value to check (gets overwrited and must be init (in and with new signal))
--			signal O_COLL_OBJ : out T_COLL_OBJ; -- object readed
			signal S_X_TO_CHECK : out natural range 0 to SCREEN_WIDTH; -- output
			signal S_Y_TO_CHECK : out natural range 0 to SCREEN_HEIGHT; -- output
			signal S_DATA_FROM_MEMORY : in std_logic_vector(15 downto 0) -- output
		)
		is begin
			S_X_TO_CHECK <= x;
			S_Y_TO_CHECK <= y;
			if S_DATA_FROM_MEMORY(0) = '1' then
				output := '1';
			end if;
		end procedure;
	
	begin
	-- internal memory mapper for the reading
	mapper : entity work.memory_mapper
		port map(
			CLOCK => clock,
			RESET => RESET,
			
			I_X_TO_CHECK => S_X_TO_CHECK,
			I_Y_TO_CHECK => S_Y_TO_CHECK,
			I_CE => I_CE,
			I_STATE => I_STATE,
			I_CURRENT_LEVEL_NUMBER => I_CURRENT_LEVEL_NUMBER,
			
			O_LEVEL_LOADED_DONE => O_LEVEL_LOADED_DONE,
			O_DATA_FROM_MEMORY => S_DATA_FROM_MEMORY,
			O_IS_UPDATING => S_IS_UPDATING,
			
			SRAM_ADDR => SRAM_ADDR,
			SRAM_DQ   => SRAM_DQ,			
			SRAM_CE_N => SRAM_CE_N,
			SRAM_OE_N => SRAM_OE_N,
			SRAM_WE_N => SRAM_WE_N,
			SRAM_UB_N => SRAM_UB_N,
			SRAM_LB_N => SRAM_LB_N	
		);
	
	ColliderProcess : process(CLOCK, RESET)
	begin
		if RESET = '1' then -- reset procedure
				-- reset all outputs
				O_COLLISION_LEFT <= '0';
				O_COLLISION_RIGHT <= '0';
				O_COLLISION_BOTTOM <= '0';
				O_COLLISION_TOP <= '0';
				S_X_TO_CHECK <= I_X_TO_CHECK;
				S_Y_TO_CHECK <= I_Y_TO_CHECK;
		elsif rising_edge(CLOCK) then
		-- border detection
			-- reset all outputs
			O_COLLISION_LEFT <= '0';
			O_COLLISION_RIGHT <= '0';
			O_COLLISION_BOTTOM <= '0';
			O_COLLISION_TOP <= '0';
			if I_REQUEST_LEFT_COLLISION = '1' then
				S_X_TO_CHECK <= I_X_TO_CHECK;
				S_Y_TO_CHECK <= I_Y_TO_CHECK + HALF_MARIO_HEIGHT;
				if S_DATA_FROM_MEMORY(0) = '1' or I_X_TO_CHECK <= LEFT_BORDER then
					O_COLLISION_LEFT <= '1';
				end if;
			elsif I_REQUEST_RIGHT_COLLISION = '1' then
				S_X_TO_CHECK <= I_X_TO_CHECK + MARIOWIDTH;
				S_Y_TO_CHECK <= I_Y_TO_CHECK + HALF_MARIO_HEIGHT;
				if S_DATA_FROM_MEMORY(0) = '1' or I_X_TO_CHECK + MARIOWIDTH >= RIGTH_BORDER then
					O_COLLISION_RIGHT <= '1';
				end if;
			elsif I_REQUEST_BOTTOM_COLLISION = '1' then
				S_X_TO_CHECK <= I_X_TO_CHECK + HALF_MARIO_WIDTH;
				S_Y_TO_CHECK <= I_Y_TO_CHECK + MARIOHEIGHT;
				if S_DATA_FROM_MEMORY(0) = '1' or I_Y_TO_CHECK + MARIOHEIGHT >= BOTTOM_BORDER then
					O_COLLISION_BOTTOM <= '1';
				end if;
			elsif I_REQUEST_TOP_COLLISION = '1' then
				S_X_TO_CHECK <= I_X_TO_CHECK + HALF_MARIO_WIDTH;
				S_Y_TO_CHECK <= I_Y_TO_CHECK;
				if S_DATA_FROM_MEMORY(0) = '1' or I_Y_TO_CHECK <= TOP_BORDER then
					O_COLLISION_TOP <= '1';
				end if;
			end if;
			D_OUT <= S_DATA_FROM_MEMORY(2 downto 0) & I_REQUEST_LEFT_COLLISION & I_REQUEST_BOTTOM_COLLISION & I_REQUEST_RIGHT_COLLISION;
		end if;
	end process;

end architecture;