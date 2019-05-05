library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.level_package.all;

entity control_unit is 
	port (
		CLOCK 		: in std_logic;
		RESET		: in std_logic;
		
		--SEGNALI RICEVUTI DAL CONTROLLER SNES
		LEFT_PRESSED : in std_logic;
		RIGHT_PRESSED : in std_logic;
		UP_PRESSED : in std_logic;
		DOWN_PRESSED : in std_logic;
		B_PRESSED : in std_logic;
		Y_PRESSED : in std_logic;
		X_PRESSED : in std_logic;
		A_PRESSED : in std_logic;
		START_PRESSED : in std_logic;
		SELECT_PRESSED : in std_logic; --PAUSE
		L_PRESSED : in std_logic;
		R_PRESSED : in std_logic;
		
		--SEGNALI INVIATI AL DATAPATH
		SX : out std_logic;
		DX : out std_logic;
		UP : out std_logic;
		DOWN : out std_logic;
		B : out std_logic;			
		Y : out std_logic;
		X : out std_logic;
		A : out std_logic;
		
		STATE : out mario_state;
		LEV_LOST: out std_logic;
		CURRENT_LEVEL: out integer;
		NEW_COIN : out std_logic;
		END_TIME : out std_logic;
		GAME_CLOCK : out std_logic;
		
		--SEGNALI RICEVUTI DAL DATAPATH
		LEVEL_LOADED : in std_logic;
		LIFE_LOST: in std_logic;
		LAST_LIFE_LOST : in std_logic;
		LEVEL_COMPLETE: in std_logic;
		COIN_CATCHED : in std_logic;
		
		I_VALUE : out integer
	);
end entity;


architecture RTL of control_unit is

	signal currState			: mario_state := INIT;
	signal currentLevel		: integer range 0 to NUM_LEVELS-1 :=0;

	signal new_coin_timer    : integer range 0 to TIMER_COIN:=0;

	signal end_time_timer	 : integer range 0 to SECONDS_PER_LEVEL:=SECONDS_PER_LEVEL;
	signal one_sec_timer	 : integer range 0 to ONE_SEC:=0;

	signal game_clock_counter : integer range 0 to (GAME_CLOCK_PRESCALER-1);
	
	signal coin_timer : integer range 0 to TIMER_COIN:=TIMER_COIN;
	
begin

	CURRENT_LEVEL<=currentLevel;
	I_VALUE<=end_time_timer;
	STATE <= currState;
	
	ActionProces : process(CLOCK,RESET)
		begin
			if (RESET='1') then
				SX <= '0';
				DX <= '0';
				UP <= '0';
				DOWN <= '0';
				
				B <= '0';
				Y <= '0';
				X <= '0';
				A <= '0';

			elsif rising_edge(CLOCK) then
				if (currState=PLAY) then
					SX <= LEFT_PRESSED;
					DX <= RIGHT_PRESSED;
					UP <= UP_PRESSED;
					DOWN <= DOWN_PRESSED;
					
					B <= B_PRESSED;
					Y <= Y_PRESSED;
					X <= X_PRESSED;
					A <= A_PRESSED;
				else
					SX <= '0';
					DX <= '0';
					UP <= '0';
					DOWN <= '0';
					
					B <= '0';
					Y <= '0';
					X <= '0';
					A <= '0';
				end if;
			end if;
		end process;
		
		StateProcess : process(CLOCK, RESET)
		begin		
			if (RESET='1') then
				currState<=INIT;
			elsif (rising_edge(CLOCK)) then	
				case currState is
					--INIT
					when INIT=>
						currentLevel<=0;
						currState <= LOAD_LEVEL;
						LEV_LOST<='0';
					--LOAD_LEVEL
					when LOAD_LEVEL=>
						if(LEVEL_LOADED='1') then
							currState <= PAUSE;
						end if;
					--PAUSE
					when PAUSE=>
						if (START_PRESSED = '1' ) then
							currState <= PLAY;
							LEV_LOST<='0';
						end if;	
					--PLAY
					when PLAY=>
						if (SELECT_PRESSED = '1') then
							currState <= PAUSE;
						elsif(LEVEL_COMPLETE='1') then
							if(currentLevel<NUM_LEVELS-1) then
								currentLevel<=currentLevel+1;
								currState <= LOAD_LEVEL;
							else							
								currState <= GAMEWON;
							end if;
						elsif(LIFE_LOST='1') then
								currState <= LEVEL_LOST;
								LEV_LOST<='1';
						elsif (LAST_LIFE_LOST='1') then
							currState <= GAMELOST;
						end if;
					--LEVEL_LOST
					when LEVEL_LOST=>
						currState <= PAUSE;
					--GAMELOST
					when GAMELOST=>
						if (START_PRESSED='1') then
							currState <= INIT;
						end if;
					--GAMEWON
					when GAMEWON=>
						if (START_PRESSED='1' ) then
							currState <= INIT;
						end if;
				end case;
			end if;
		end process;
		
		GameTimingProcess : process(CLOCK, RESET)
		variable stop : boolean := false;
		begin
			if RESET='1' then
				new_coin_timer <=0;
				coin_timer<=0;
				end_time_timer <=SECONDS_PER_LEVEL;
				NEW_COIN <='0';
				END_TIME <='0';
			elsif (rising_edge(CLOCK)) then
				case currState is
					when PLAY =>
						NEW_COIN<='0';
						END_TIME <='0';
						--NEW COIN TIMER
						if (stop=false) then
							coin_timer<=TIMER_COIN-(currentLevel*ONE_SEC);
							if (new_coin_timer<coin_timer) then
								new_coin_timer <= new_coin_timer+1;
							else
								new_coin_timer<=0;
								NEW_COIN<='1';
							end if;
							--COIN CATCHED
							if(COIN_CATCHED='1')then
								new_coin_timer<=0;
								NEW_COIN<='1';
							end if;
							--END TIME TIMER
							if (one_sec_timer<ONE_SEC) then
								one_sec_timer <= one_sec_timer+1;
							else
								one_sec_timer<=0;
								if(end_time_timer>0) then
									end_time_timer<= end_time_timer-1;
									END_TIME <='0';
								else
									end_time_timer<=SECONDS_PER_LEVEL;
									END_TIME <='1';
									NEW_COIN<='0';
									stop:=true;
								end if;
							end if;
						end if;
					when PAUSE => 
					
					when others => 
						new_coin_timer<=0;
						coin_timer<=0;
						end_time_timer<=SECONDS_PER_LEVEL;
						one_sec_timer<=0;
						NEW_COIN <='0';
						END_TIME <='0';
						stop:=false;
				end case;
			end if;
		end process;
		
		GameClockProcess : process(CLOCK, RESET)
		begin
			if (RESET = '1') then
				game_clock_counter <= 0;
				GAME_CLOCK <= '0';
			elsif (rising_edge(clock)) then
				if(game_clock_counter < GAME_CLOCK_PRESCALER-1) then
					game_clock_counter <= game_clock_counter+1;
					GAME_CLOCK <= '0';
				else
					game_clock_counter <= 0;
					GAME_CLOCK <= '1';
				end if;
			end if;
		end process;		
end architecture;

