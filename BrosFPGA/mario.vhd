----------------------------------------------------
--	Authors: 			- mail:
--	M. B. 				- marco_lagaro@hotmail.it
-- M. S.				- mattia_sinigaglia@yahoo.com
-- F. T.				- fabrizio.torriano@studio.unibo.it
----------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.vga_package.all;
use work.level_package.all;

entity mario is
	port(
		CLOCK_50		: in std_logic;
		KEY			: in std_logic_vector(3 downto 0);
		--GPIO FOR SNES CONTROLLER AND ACTIVE BUZZER
		GPIO_0 		: out std_logic_vector(35 downto 0);
		GPIO_1 		: in std_logic_vector(35 downto 0);
		
		LEDR			: out std_logic_vector(9 downto 0);
		LEDG			: out std_logic_vector(6 downto 0);
		SW          : in  std_logic_vector(9 downto 0);
		--7SEGMENT
		HEX0			: out std_logic_vector(6 downto 0);
		HEX1 			: out std_logic_vector(6 downto 0);
		HEX2 			: out std_logic_vector(6 downto 0);
		HEX3 			: out std_logic_vector(6 downto 0);
		--SRAM
		SRAM_ADDR           : out   std_logic_vector(17 downto 0);
		SRAM_DQ             : inout std_logic_vector(15 downto 0);
		SRAM_CE_N           : out   std_logic;
		SRAM_OE_N           : out   std_logic;
		SRAM_WE_N           : out   std_logic;
		SRAM_UB_N           : out   std_logic;
		SRAM_LB_N           : out   std_logic;
		--VGA
		VGA_R               : out std_logic_vector(3 downto 0);
		VGA_G               : out std_logic_vector(3 downto 0);
		VGA_B               : out std_logic_vector(3 downto 0);
		VGA_HS              : out std_logic;
		VGA_VS              : out std_logic;
		--CODEC WM8731
		AUD_BCLK: out std_logic;
		AUD_XCK: out std_logic;
		AUD_DACLRCK: out std_logic;
		AUD_DACDAT: out std_logic;
		I2C_SCLK: out std_logic;
		I2C_SDAT: inout std_logic;
		--FLASH
		FL_ADDR : out std_logic_vector(21 downto 0);
		FL_DQ : in std_logic_vector(7 downto 0);
		FL_OE_N : out std_logic;
		FL_RST_N : out std_logic;
		FL_WE_N : out std_logic	
	);
end;

architecture RTL of mario is

	signal clock		: std_logic;
	signal clockVGA	: std_logic;
	signal clockAUDIO	: std_logic;
	
	signal RESET		: std_logic;
	
	--sincronizzazione view datapath
	signal game_clock   : std_logic;
	
	-- SNES CONTROLLER TO CONTROL UNIT
	signal key_left	:	std_logic;
	signal key_right	:	std_logic;
	signal key_up		:	std_logic;
	signal key_down	:	std_logic;
	
	signal key_jump	:	std_logic;
	signal key_Y	:	std_logic;
	signal key_A		:	std_logic;
	signal key_X	:	std_logic;
	
	signal key_start	:	std_logic;
	signal key_select	:	std_logic;
	
	signal key_L		:	std_logic;
	signal key_R		:	std_logic;
	
	--CONTROL UNIT TO DATAPATH
	signal key_left_cu	:	std_logic;
	signal key_right_cu	:	std_logic;
	signal key_up_cu		:	std_logic;
	signal key_down_cu	:	std_logic;
	
	signal key_jump_cu	:	std_logic;
	signal key_Y_cu	:	std_logic;
	signal key_A_cu		:	std_logic;
	signal key_X_cu	:	std_logic;
	
	signal key_start_cu	:	std_logic;
	signal key_select_cu	:	std_logic;
	
	signal state         : mario_state:= PLAY;
	
	signal current_level : integer range 0 to NUM_LEVELS-1:=0;
	signal new_coin	:	std_logic;
	signal end_time	:	std_logic;
	
	--CONTROL UNIT TO 7SEGMENT
	signal countdown : integer range 0 to 9999;
	
	signal level_lost: std_logic;
	
	-- DATAPATH TO VGA
	signal draw_left	:	std_logic;
	signal draw_right	:	std_logic;
	signal draw_jump	:	std_logic;
	
	signal marioX     : integer  := MARIO_STARTING_POSX;
	signal marioY     : integer  := MARIO_STARTING_POSY;

	signal coinX     : integer  := 0;
	signal coinY     : integer  := 0;	
	
	signal lives	: integer range 0 to DEFAULT_NUM_LIVES:=DEFAULT_NUM_LIVES;
	signal num_coin_catched :integer range 0 to NUM_COIN_PER_LEVEL :=0;
	
	--DATAPATH TO CONTROL UNIT
	signal level_loaded : std_logic;
	signal life_lost : std_logic;
	signal last_life_lost : std_logic;
	signal level_complete: std_logic;
	signal coin_catched : std_logic;
	
	--reset
	signal reset_sync_reg	:	std_logic;
	
begin

	audio : entity work.audio_mario
		port map(
			clockAUDIO	=> clockAUDIO,
			RESET		=> RESET,
			
			----------WM8731 pins-----
			AUD_BCLK		=> AUD_BCLK,
			AUD_XCK		=> AUD_XCK,
			AUD_DACLRCK	=> AUD_DACLRCK,
			AUD_DACDAT	=> AUD_DACDAT,
			
			----------I2C pins-----
			I2C_SCLK		=> I2C_SCLK,
			I2C_SDAT		=> I2C_SDAT,
			
			--------flash pins-------
			FL_ADDR => FL_ADDR,
			FL_DQ => FL_DQ,
			FL_OE_N => FL_OE_N,
			FL_RST_N => FL_RST_N,
			FL_WE_N => FL_WE_N		
		);
		
	buzzer : entity work.buzzer
	port map(
		CLOCK 	=> clock,
		RESET	=> RESET,
		STATE =>state,
		--USCITA BUZZER
		BUZZER_PIN => GPIO_0(2),	
		--SEGNALI RICEVUTI DAL DATAPATH
		COIN_CATCHED=> coin_catched
	);


	pll : entity work.PLL
		port map 
		(
			inclk0		=> CLOCK_50,
			c0				=> clock,		
			c1				=> clockVGA,
			c2				=> clockAUDIO
		);
	
	reset_sync : process(CLOCK_50)
	begin
		if (rising_edge(CLOCK_50)) then
			reset_sync_reg <= SW(9);
			RESET <= reset_sync_reg;
		end if;
	end process;
	
	controlUnit : entity work.control_unit
		port map(
			CLOCK 	=> clock,
			RESET	=> RESET,
			
			--SEGNALI RICEVUTI DAL CONTROLLER
			LEFT_PRESSED => key_left,
			RIGHT_PRESSED => key_right,
			UP_PRESSED => key_up,
			DOWN_PRESSED => key_down,
			
			B_PRESSED => key_jump,
			Y_PRESSED => key_Y,
			X_PRESSED => key_X,
			A_PRESSED => key_A,
			
			START_PRESSED => key_start,
			SELECT_PRESSED => key_select,
			
			L_PRESSED => key_L,
			R_PRESSED => key_R,
			
			--SEGNALI INVIATI AL DATAPATH
			SX => key_left_cu,
			DX => key_right_cu,
			UP => key_up_cu,
			DOWN => key_down_cu,
			
			B => key_jump_cu,
			Y => key_Y_cu,
			X => key_X_cu,
			A => key_A_cu,
			
			STATE =>state, --RICEVUTO ANCHE DALLA VGA
			LEV_LOST => level_lost, -- DALLA VGA
			CURRENT_LEVEL=>current_level,
			NEW_COIN=> new_coin,
			END_TIME=> end_time,
			
			--SEGNALI RICEVUTI DAL DATAPATH
			LEVEL_COMPLETE =>level_complete,
			LEVEL_LOADED =>level_loaded,
			LIFE_LOST=>life_lost,
			LAST_LIFE_LOST=>last_life_lost,
			COIN_CATCHED=> coin_catched,
			
			--SEGNALI INVIATI AL 7 SEGMENTI E ALLA VGA
			I_VALUE => countdown
	
			,GAME_CLOCK => game_clock

		);
	
	datapath : entity work.mario_datapath
		port map(
			CLOCK 	=> clock,
			RESET	=> RESET,
			LEDR => LEDR,
						
			LEDG => LEDG,
			
			--SEGNALI RICEVUTI DALLA CONTROL UNIT
			SX => key_left_cu,
			DX => key_right_cu,
			UP => key_up_cu,
			DOWN => key_down_cu,
						
			
			B => key_jump_cu,
			Y => key_Y_cu,
			X => key_X_cu,
			A => key_A_cu,
			
			STATE => state,
			CURRENT_LEVEL=>current_level,
			NEW_COIN=> new_coin,
			END_TIME=> end_time,
			
			--SEGNALI INVIATI ALLA CONTROL UNIT
			LEVEL_COMPLETE =>level_complete,
			LEVEL_LOADED =>level_loaded,
			LIFE_LOST=>life_lost,
			LAST_LIFE_LOST=>last_life_lost,
			COIN_CATCHED=> coin_catched,
			
			--SEGNALI INVIATI ALLA VGA
			
			GAME_LOGIC_UPDATE	=> game_clock,
			
			MARIO_X	=> marioX,
			MARIO_Y	=> marioY,
			
			COIN_X => coinX,
			COIN_Y => coinY,
			
			LIVES => lives, --GIUNGE ANCHE ALLA CONTROL UNIT
			NUM_COIN_CATCHED=> num_coin_catched,
			
			SRAM_ADDR => SRAM_ADDR,
			SRAM_DQ   => SRAM_DQ,			
			SRAM_CE_N => SRAM_CE_N,
			SRAM_OE_N => SRAM_OE_N,
			SRAM_WE_N => SRAM_WE_N,
			SRAM_UB_N => SRAM_UB_N,
			SRAM_LB_N => SRAM_LB_N	
		);
		
		snes : entity work.mario_snes
		port map(
			CLOCK 	=> clock,
			RESET	=> RESET,
			
			--PIN DI OUTPUT  DEL CONTROLLER
			CLOCK_PIN => GPIO_0(0),
			LATCH_PIN => GPIO_0(1),
			
			--PIN DI INPUT DEL CONTROLLER
			DATA_PIN => GPIO_1(0),
			
			--SEGNALI INVIATI ALLA CONTROL UNIT 
			LEFT_PRESSED => key_left,
			RIGHT_PRESSED => key_right,
			UP_PRESSED => key_up,
			DOWN_PRESSED => key_down,
			
			B_PRESSED => key_jump,
			Y_PRESSED => key_Y,
			X_PRESSED => key_X,
			A_PRESSED => key_A,
			
			START_PRESSED => key_start,
			SELECT_PRESSED => key_select,
			
			L_PRESSED => key_L,
			R_PRESSED => key_R
			
		);	
		
		mario_view : entity work.mario_view
		port map(
			CLOCK 	=> clockVGA,

			RESET	=> RESET,
			
			VGA_R 	=> VGA_R,
			VGA_G  	=> VGA_G,
			VGA_B 	=> VGA_B,
			VGA_HS	=> VGA_HS,
			VGA_VS	=> VGA_VS,
			
			LIVES => lives,
			CURRENT_LEVEL => current_level,
			NUM_COIN_CATCHED=> num_coin_catched,
			STATE => state,
			LEV_LOST => level_lost,
			TIMER_VALUE => countdown,
			
			--SEGNALI RICEVUTI DAL DATAPATH
			MARIO_X	=> marioX,
			MARIO_Y	=> marioY,
			
			COIN_X => coinX,
			COIN_Y => coinY
		);
		
		lc : entity work.led_controller
		port map(
			CLOCK => clock,
			RESET => RESET,
			
			I_VALUE => countdown,
			
			HEX0 => HEX0,
			HEX1 => HEX1,
			HEX2 => HEX2,
			HEX3 => HEX3
		);
end architecture;