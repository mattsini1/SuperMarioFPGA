library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use ieee.math_real.uniform;
use ieee.math_real.floor;

use work.mario_package.all;
use work.vga_package.all;
use work.level_package.all;

entity mario_datapath is 
	port (
		CLOCK 		: in std_logic;
		RESET		: in std_logic;
		
		--SEGNALI RICEVUTI DALLA CONTROL UNIT
		SX : in std_logic;
		DX : in std_logic;
		UP : in std_logic;
		DOWN : in std_logic;
		
		B : in std_logic;			
		Y : in std_logic;
		X : in std_logic;
		A : in std_logic;

		STATE : in mario_state;
		CURRENT_LEVEL : in integer; 
		NEW_COIN : in std_logic;
		END_TIME : in std_logic;
		
		--RICEVUTO DAL COUNTER PER AGGIORNARE A VIDEO
		GAME_LOGIC_UPDATE		: in std_logic;

		MARIO_X	: out integer;
		MARIO_Y	: out integer;
	
		COIN_X	: out integer;
		COIN_Y	: out integer;
		
		--SEGNALI INVIATI ALLA CONTROL UNIT
		LEVEL_LOADED : out std_logic;
		LIFE_LOST: out std_logic;
		LAST_LIFE_LOST : out std_logic;
		LEVEL_COMPLETE: out std_logic;
		COIN_CATCHED : out std_logic;
		
		--SEGNALI INVIATI ALLA VGA		
		LIVES	:	out integer;
		NUM_COIN_CATCHED : out integer;
		
		LEDG : out std_logic_vector(6 downto 0);
				
		LEDR			: out std_logic_vector(9 downto 0);
		
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


architecture RTL of mario_datapath is
	
	signal S_RANDOM : natural range 0 to MAX_COIN;
	--from the collision machine
	signal S_COLLISION_TOP : std_logic;
	signal S_COLLISION_BOTTOM : std_logic;
	signal S_COLLISION_LEFT : std_logic;
	signal S_COLLISION_RIGHT : std_logic;
--	signal S_X : natural;
--	signal S_Y : natural;
	signal S_RDY : std_logic;
	
	signal S_REQUEST_LEFT_COLLISION : std_logic;
	signal S_REQUEST_RIGHT_COLLISION : std_logic;
	signal S_REQUEST_BOTTOM_COLLISION : std_logic;
	signal S_REQUEST_TOP_COLLISION : std_logic;
	
	signal S_REQ_X : natural;
	signal S_REQ_Y : natural;
	
	--FROM CONTROL UNIT TO COLLISION->MEMORY MAPPER

	signal s_mario_x : integer := MARIO_STARTING_POSX;
	signal s_mario_y : integer := MARIO_STARTING_POSY;

	signal s_coin_x : integer := 0;
	signal s_coin_y : integer := 0;	
	
	signal s_num_lives : integer := 0;
	
	signal s_num_coin_catched : integer := 0;
	signal s_coin_catched : std_logic := '0';
	
	signal coin_block_index : integer range 0 to MAX_COIN := 0;		
begin

	cm : entity work.collision_machine
		port map(
			CLOCK => clock,
			RESET => RESET,
			
			I_X_TO_CHECK => S_REQ_X,
			I_Y_TO_CHECK => S_REQ_Y,
			I_CE => '1',
			
			I_REQUEST_LEFT_COLLISION => S_REQUEST_LEFT_COLLISION,
			I_REQUEST_RIGHT_COLLISION => S_REQUEST_RIGHT_COLLISION,
			I_REQUEST_BOTTOM_COLLISION => S_REQUEST_BOTTOM_COLLISION,
			I_REQUEST_TOP_COLLISION => S_REQUEST_TOP_COLLISION,
			
			I_CURRENT_LEVEL_NUMBER => CURRENT_LEVEL,
			I_STATE => STATE,
			
			O_LEVEL_LOADED_DONE => LEVEL_LOADED,
			
			O_COLLISION_RIGHT => S_COLLISION_RIGHT,
			O_COLLISION_TOP => S_COLLISION_TOP,
			O_COLLISION_BOTTOM => S_COLLISION_BOTTOM,
			O_COLLISION_LEFT => S_COLLISION_LEFT,
--			O_COLL_OBJ => open,
			
			D_OUT => LEDR(9 downto 4),
			SRAM_ADDR => SRAM_ADDR,
			SRAM_DQ   => SRAM_DQ,			
			SRAM_CE_N => SRAM_CE_N,
			SRAM_OE_N => SRAM_OE_N,
			SRAM_WE_N => SRAM_WE_N,
			SRAM_UB_N => SRAM_UB_N,
			SRAM_LB_N => SRAM_LB_N		
		);

	mm : entity work.movement_machine
		port map(
			CLOCK => clock,
			RESET => RESET,
		
			I_CONTROLLER_BUTTON_SX => SX,  -- LEFT BUTTON
			I_CONTROLLER_BUTTON_DX => DX,  -- RIGHT BUTTON
			
			I_CONTROLLER_BUTTON_UP => B,  -- B BUTTON FOR JUMP
			--I_X_TO_CHECK => S_X,
			--I_Y_TO_CHECK => S_Y,
			I_COLLISION_SX => S_COLLISION_LEFT,
			I_COLLISION_DX => S_COLLISION_RIGHT,
			I_COLLISION_DOWN => S_COLLISION_BOTTOM,
			I_COLLISION_UP => S_COLLISION_TOP,
			I_GAME_CLOCK => GAME_LOGIC_UPDATE,
			
			D_LED => LEDR(3 downto 0),
			
			O_REQUEST_COLLISION_SX => S_REQUEST_LEFT_COLLISION,
			O_REQUEST_COLLISION_DX => S_REQUEST_RIGHT_COLLISION,
			O_REQUEST_COLLISION_DOWN => S_REQUEST_BOTTOM_COLLISION,
			O_REQUEST_COLLISION_UP => S_REQUEST_TOP_COLLISION,
			O_REQUEST_NEXT_X => S_REQ_X,
			O_REQUEST_NEXT_Y => S_REQ_Y,
			O_X => s_mario_x,
			O_Y => s_mario_y
		);
	

	
	MARIO_X <= s_mario_x;
	MARIO_Y <= s_mario_y;
	
	COIN_X <= s_coin_x;
	COIN_Y <= s_coin_y;
		
	LIVES <= s_num_lives;
	NUM_COIN_CATCHED <= s_num_coin_catched;
	COIN_CATCHED <= s_coin_catched;
	
	LEDG(0) <= s_coin_catched;
	LEDG(1) <= '1' when coin_block_index = 0 else '0';
	
	LEDG(2) <= '1' when s_num_coin_catched = 0 else '0';
	LEDG(3) <= '1' when s_num_coin_catched >= 1 else '0';
	LEDG(4) <= '1' when s_num_coin_catched >= 2 else '0';
	LEDG(5) <= '1' when s_num_coin_catched >= 3 else '0';
	
	LivesProcess : process(CLOCK, RESET)

	begin
		if(RESET = '1') then
			s_num_lives <= DEFAULT_NUM_LIVES;
		elsif(rising_edge(CLOCK)) then
			
		
			
			LAST_LIFE_LOST		<= '0';
			LIFE_LOST			<= '0';
			if (STATE=INIT) then
				s_num_lives <= DEFAULT_NUM_LIVES;	
			elsif(end_time = '1') then
				if(s_num_coin_catched < NUM_COIN_PER_LEVEL) then
					s_num_lives <= s_num_lives - 1;
					-- "-1" as update on s_num_lives will be visible at next time of clock...
					if(s_num_lives - 1 = 0) then 
						LAST_LIFE_LOST <= '1';					
					else
						LIFE_LOST <= '1';					
					end if;	
				end if;	--if(s_num_coin_catched < NUM_COIN_PER_LEVEL)
			else
				if (s_num_coin_catched = NUM_COIN_PER_LEVEL AND s_num_lives<DEFAULT_NUM_LIVES) then 
					s_num_lives <= s_num_lives + 1;
				end if;
			end if;
			
		end if;	--if(rising_edge(CLOCK))
	end process LivesProcess;

	CoinProcess : process(CLOCK, RESET)
	begin
		if(RESET = '1') then
			s_num_coin_catched <= 0;
			s_coin_catched <= '0';
			coin_block_index <= 0;
		elsif(rising_edge(CLOCK)) then
			
			s_coin_x <= GAME_COINS(CURRENT_LEVEL)(coin_block_index).x;
			s_coin_y <= GAME_COINS(CURRENT_LEVEL)(coin_block_index).y;
				
			LEVEL_COMPLETE <= '0';
			--policy: signals from cu have more priority!!
			if(end_time = '0') then	
				if(new_coin = '1') then 
					s_coin_catched <= '0';
					coin_block_index <= (S_RANDOM + coin_block_index) mod MAX_COIN;
				elsif(s_coin_catched = '0' and
					(
					((s_mario_x + MARIO_WIDTH) = s_coin_x and s_mario_y < (s_coin_y + COIN_HEIGHT) and (s_mario_y + MARIO_HEIGHT) > s_coin_y) or
					(s_mario_x = (s_coin_x + COIN_WIDTH) and s_mario_y < (s_coin_y + COIN_HEIGHT) and (s_mario_y + MARIO_HEIGHT) > s_coin_y) or
					((s_mario_y + MARIO_HEIGHT) = s_coin_y and s_mario_x < (s_coin_x + COIN_WIDTH) and (s_mario_x + MARIO_WIDTH) > s_coin_x) or
					(s_mario_y = (s_coin_y + COIN_HEIGHT) and s_mario_x < (s_coin_x + COIN_WIDTH) and (s_mario_x + MARIO_WIDTH) > s_coin_x)
					)
				) then
					s_coin_catched <= '1';
					s_num_coin_catched <= s_num_coin_catched + 1;			
				end if;		
			
			elsif(end_time = '1')	then--end_time = '1'			
				s_num_coin_catched <= 0;
				s_coin_catched <= '0';
				coin_block_index <= 0;
			end if;	--elsif(end_time = '1')
			
			if(STATE=PLAY) then
				if (s_num_coin_catched = NUM_COIN_PER_LEVEL) then 
					s_coin_catched <= '0';
					LEVEL_COMPLETE <= '1';
					s_num_coin_catched <= 0;
					coin_block_index <= 0;
				end if;
			elsif(STATE/=PAUSE) then
				s_num_coin_catched <= 0;
				s_coin_catched <= '0';
				coin_block_index <= 0;
			end if;
			
		end if;	--if(rising_edge(CLOCK))
	end process CoinProcess;

	RandomProcess : process(CLOCK, RESET)
		variable ST : natural range 0 to NUM_COIN_PER_LEVEL := 3;
	begin
		if RESET = '1' then
			S_RANDOM <= ST;
		elsif rising_edge(CLOCK) then
			S_RANDOM <= S_RANDOM + 1;
			if S_RANDOM + 1 >= NUM_COIN_PER_LEVEL then
				S_RANDOM <= 0;
			end if;
			ST := (ST + S_RANDOM) rem NUM_COIN_PER_LEVEL;
		end if;
	end process;
	
	
end architecture;
