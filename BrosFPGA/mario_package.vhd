--
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;

package mario_package is
	
	type T_COLL_OBJ is(
		TCO_NULL, -- no collision
		TCO_BORDER, -- border
		TCO_RESERVED -- reserved type (must be the last one)
	);
	
	type T_BL is record -- define a block
		kind : T_COLL_OBJ;
		repr : std_logic_vector(15 downto 0);
	end record;
	
	constant R_NULL : T_BL :=( -- void block
		kind => TCO_NULL,
		repr => "00000000" & "00000" & "000"
	);
	constant R_BORDER : T_BL :=( -- collision border block
		kind => TCO_BORDER,
		repr => "00000000" & "00000" & "011"
	);
	

	
	--STATI DEL SISTEMA
	type mario_state is (INIT, PAUSE, PLAY, LOAD_LEVEL,LEVEL_LOST, GAMELOST, GAMEWON);

		
	type coord is record
		x : natural;
		y : natural;
	end record coord;

	--GAME CLOCK
	constant GAME_CLOCK_PRESCALER : positive := 4000;

	--AUDIO CONSTANTS
	constant BEEP_DURATION : positive := 10000000; -- 200 ms !
	constant LAST_FLASH_ADDR : positive := 3628183;
	constant AUDIO_PRESCALER_MAX : positive := 250;
	constant I2C_PRESCALER : positive := 60;
	
	--VIEW CONSTANTS
	constant STAR_WIDTH : positive := 32;
	constant STAR_HEIGHT : positive := 32;
	
	constant CIFRA_WIDTH : positive := 16;
	constant CIFRA_HEIGHT : positive := 32;
	
	constant PAUSE_WIDTH : positive := 32;
	constant PAUSE_HEIGHT : positive := 32;

	constant PLAY_WIDTH : positive := 32;
	constant PLAY_HEIGHT : positive := 32;	
	
	constant COIN_WIDTH : positive := 16;
	constant COIN_HEIGHT : positive := 32;
	
	constant X_SCORE_WIDTH : positive := 16;
	constant X_SCORE_HEIGHT : positive := 32;
	
	constant COINS_TO_CATCH_WIDTH : positive := 32;
	constant COINS_TO_CATCH_HEIGHT : positive := 32;
	
	constant EQUAL_WIDTH : positive := 16;
	constant EQUAL_HEIGHT : positive := 32;
	
	constant MARIO_WIDTH : positive := 16;
	constant MARIO_HEIGHT : positive := 32;
	
	constant HILL_WIDTH : positive := 96;
	constant HILL_HEIGTH : positive := 38;
	
	constant CLOUD_WIDTH : positive := 64;
	constant CLOUD_HEIGHT : positive := 48;
	
	constant FLOOR_WIDTH : positive := 600;
	constant FLOOR_HEIGTH : positive := 18;
	
	constant BLOCK_WIDTH : natural := 125;
	constant BLOCK_HEIGHT : natural := 20;	
	
	constant DEFAULT_NUM_LIVES : integer := 3;

	constant SECONDS_PER_LEVEL : integer range 0 to 99:= 60;
	constant TIMER_COIN : natural := 250000000;
	constant ONE_SEC : natural := 50000000;
end package;


--body mario package
package body mario_package is
end mario_package;
