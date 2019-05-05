library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mario_package.all;
use work.vga_package.all;
use work.level_package.all;

entity mario_view is

port
	(  
		CLOCK					: in std_logic;			
		RESET					: in std_logic;
		
		-- RICEVUTI DAL DATAPATH
		MARIO_X					: in integer;
		MARIO_Y					: in integer;
		COIN_X					: in integer;
		COIN_Y					: in integer;	
		LIVES						: in integer;
		NUM_COIN_CATCHED		: in integer;
		
		-- RICEVUTI DALLA CONTROL UNIT
		CURRENT_LEVEL			: in integer;
		STATE 					: in mario_state;
		LEV_LOST				: in std_logic;
		TIMER_VALUE				: in integer;
		
		VGA_HS					: out std_logic;
		VGA_VS					: out std_logic;
		VGA_R 					: out std_logic_vector(3 downto 0);
		VGA_G						: out std_logic_vector(3 downto 0);
		VGA_B						: out std_logic_vector(3 downto 0)
	);
end;
architecture RTL of mario_view is
	signal horizontal_pointer : integer range 0 to TOTAL_W := 0;	
	signal vertical_pointer : integer range 0 to TOTAL_H := 0;		
	
begin 
		
	DrawProcess : process(CLOCK,RESET)
	
	variable x						: integer range 0 to VISIBLE_WIDTH:=0;
	variable y						: integer range 0 to VISIBLE_HEIGHT:=0;
	
	variable ENABLE_STAR1		: boolean:=true;
	variable ENABLE_STAR2		: boolean:=true;
	variable ENABLE_STAR3		: boolean:=true;
	
	variable colors				: matrix_color;
	variable color_state : matrix_color;

	begin
		if(RESET='1') then
			horizontal_pointer<=0;
			vertical_pointer<=0;
			x:=0;
			y:=0;
			
			VGA_HS<='0';
			VGA_VS<='0';
			VGA_R <= X"0";
			VGA_G <= X"0";
			VGA_B <= X"0";
		elsif rising_edge(CLOCK) then
		
			x:=horizontal_pointer-WINDOW_HORIZONTAL_START;
			y:=vertical_pointer-WINDOW_VERTICAL_START;
		
			--Vertical sync
			if(vertical_pointer >= VERTICAL_FRONT_PORCH and vertical_pointer < VERTICAL_FRONT_PORCH + VERTICAL_SYNC_PULSE) then
				VGA_VS <='1';			
			else
				VGA_VS <='0';			
			end if;					
			--Horizontal sync
			if(horizontal_pointer >= HORIZONTAL_FRONT_PORCH and horizontal_pointer < HORIZONTAL_FRONT_PORCH + HORIZONTAL_SYNC_PULSE) then
				VGA_HS <='1';			
			else
				VGA_HS <='0';			
			end if;			
			
			case LIVES is
			
				when 1=>
					ENABLE_STAR1 := true;
					ENABLE_STAR2 := false;
					ENABLE_STAR3 := false;
					
				when 2=>
					ENABLE_STAR1 := true;
					ENABLE_STAR2 := true;
					ENABLE_STAR3 := false;
				
				when 3=>
					ENABLE_STAR1 := true;
					ENABLE_STAR2 := true;
					ENABLE_STAR3 := true;
					
				when others =>
			end case;
			
			--BORDER COLOR 
			if (STATE=LOAD_LEVEL OR STATE=GAMEWON ) then
				color_state := get_color(x"5"); --("0000","1111","0000"); --green
			elsif (LEV_LOST='1' OR STATE=GAMELOST ) then
				color_state :=  get_color(x"2"); --("1111","0000","0000"); --red
			elsif (STATE=PLAY ) then
				color_state :=  get_color(x"6"); --("1111","0000","0000"); --white
			end if;
			
			--inside the visible window
			if(x>=0 and x<VISIBLE_WIDTH and y>=0 and y<VISIBLE_HEIGHT) then
				
				--draw background
					colors:=get_color(x"7");
					VGA_R <= colors(0);
					VGA_G <= colors(1);
					VGA_B <= colors(2);					
				--end draw background
				
				--draw bounds
				if(x<BOUND_LEFT or x>=BOUND_RIGHT or y<BOUND_TOP) then
					VGA_R <= color_state(0); 
					VGA_G <= color_state(1);
					VGA_B <= color_state(2); 
					if(x>=BOUND_LEFT-2 and x<BOUND_RIGHT+2 and y>=BOUND_TOP-2) then
						colors:=get_color(x"2"); --red
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
					end if;
				end if;
				--end draw bounds
				
				--DRAW STATUS GAME BAR
				
				--DRAW LIVES STAR
				IF(x >= STAR1_X and x < STAR1_X + STAR_WIDTH and y >= STAR1_Y and y < STAR1_Y + STAR_HEIGHT and ENABLE_STAR1=true and  star_borders(y-STAR1_Y, x-STAR1_x) = '1') then
						colors:=get_color(star_colors(y-STAR1_Y, x-STAR1_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				
				IF(x >= STAR2_X and x < STAR2_X + STAR_WIDTH and y >= STAR2_Y and y < STAR2_Y + STAR_HEIGHT and ENABLE_STAR2=true and star_borders(y-STAR2_Y, x-STAR2_x) = '1') then
						colors:=get_color(star_colors(y-STAR2_Y, x-STAR2_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				
				IF(x >= STAR3_X and x < STAR3_X + STAR_WIDTH and y >= STAR3_Y and y < STAR3_Y + STAR_HEIGHT and ENABLE_STAR3=true and star_borders(y-STAR3_Y, x-STAR3_x) = '1') then
						colors:=get_color(star_colors(y-STAR3_Y, x-STAR3_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				--END DRAW LIVES STAR
				
				--DRAW TIMER_VALUE
				
				--PRIMA CIFRA
				if(x >= PRIMA_CIFRA_X and x < PRIMA_CIFRA_X + CIFRA_WIDTH and y >= PRIMA_CIFRA_Y and y < PRIMA_CIFRA_Y + CIFRA_HEIGHT and STATE=PLAY and CIFRE(TIMER_VALUE/10)(y-PRIMA_CIFRA_Y, x-PRIMA_CIFRA_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
			
				--SECONDA CIFRA
				if(x >= SECONDA_CIFRA_X and x < SECONDA_CIFRA_X + CIFRA_WIDTH and y >= SECONDA_CIFRA_Y and y < SECONDA_CIFRA_Y + CIFRA_HEIGHT and STATE=PLAY and CIFRE(TIMER_VALUE rem 10)(y-SECONDA_CIFRA_Y, x-SECONDA_CIFRA_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
				--END DRAW TIMER
				
				-- DRAW PAUSE
				IF(x >= PAUSE_X and x < PAUSE_X + PAUSE_WIDTH and y >= PAUSE_Y and y < PAUSE_Y + PAUSE_HEIGHT and STATE=PAUSE and pause_borders(y-PAUSE_Y, x-PAUSE_X) = '1') then
						VGA_R <= "0000";
						VGA_G <= "0000";
						VGA_B <= "0000";
				end if;
				-- END DRAW PAUSE

				--DRAW COIN SCORE
				IF(x >= COIN_SCORE_X and x < COIN_SCORE_X + COIN_WIDTH and y >= COIN_SCORE_Y and y < COIN_SCORE_Y + COIN_HEIGHT and coin_borders(y-COIN_SCORE_Y, x-COIN_SCORE_X) = '1') then
						colors:=get_color(coin_colors(y-COIN_SCORE_Y, x-COIN_SCORE_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				--END DRAW COIN SCORE
				
				-- DRAW X
				IF(x >= X_SCORE_X and x < X_SCORE_X + X_SCORE_WIDTH and y >= X_SCORE_Y and y < X_SCORE_Y + X_SCORE_HEIGHT and x_borders(y-X_SCORE_Y, x-X_SCORE_X) = '1') then
						VGA_R <= "0000";
						VGA_G <= "0000";
						VGA_B <= "0000";
				end if;
				-- END DRAW X
				
				-- DRAW NUMBER COIN TO CATCH
				--PRIMA CIFRA
				if(x >= COIN_TO_CATCH_FIRST_X and x < COIN_TO_CATCH_FIRST_X + CIFRA_WIDTH and y >= COIN_TO_CATCH_FIRST_Y and y < COIN_TO_CATCH_FIRST_Y + CIFRA_HEIGHT and CIFRE(NUM_COIN_PER_LEVEL/10)(y-COIN_TO_CATCH_FIRST_Y, x-COIN_TO_CATCH_FIRST_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
			
				--SECONDA CIFRA
				if(x >= COIN_TO_CATCH_SECOND_X and x < COIN_TO_CATCH_SECOND_X + CIFRA_WIDTH and y >= COIN_TO_CATCH_SECOND_Y and y < COIN_TO_CATCH_SECOND_Y + CIFRA_HEIGHT and CIFRE(NUM_COIN_PER_LEVEL rem 10)(y-COIN_TO_CATCH_SECOND_Y, x-COIN_TO_CATCH_SECOND_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
				-- END DRAW NUMBER COIN TO CATCH
				
				-- DRAW =
				IF(x >= EQUAL_X and x < EQUAL_X + EQUAL_WIDTH and y >= EQUAL_Y and y < EQUAL_Y + EQUAL_HEIGHT and eq_borders(y-EQUAL_Y, x-EQUAL_X) = '1') then
						VGA_R <= "0000";
						VGA_G <= "0000";
						VGA_B <= "0000";
				end if;
				-- END DRAW =
				
				--DRAW MY SCORE				
				if(x >= MY_FIRST_SCORE_X and x < MY_FIRST_SCORE_X + CIFRA_WIDTH and y >= MY_FIRST_SCORE_Y and y < MY_FIRST_SCORE_Y + CIFRA_HEIGHT and CIFRE(NUM_COIN_CATCHED/10)(y-MY_FIRST_SCORE_Y, x-MY_FIRST_SCORE_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
			
				if(x >= MY_SECOND_SCORE_X and x < MY_SECOND_SCORE_X + CIFRA_WIDTH and y >= MY_SECOND_SCORE_Y and y < MY_SECOND_SCORE_Y + CIFRA_HEIGHT and CIFRE(NUM_COIN_CATCHED rem 10)(y-MY_SECOND_SCORE_Y, x-MY_SECOND_SCORE_X) = '1') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				end if;
				--END DRAW MY SCORE
						
				--DRAW CLOUDS
				for i in 0 to NUM_CLOUDS - 1 loop
					if(x>=CLOUDS(i).x and x<CLOUDS(i).x+CLOUD_WIDTH and y>=CLOUDS(i).y and y<=CLOUDS(i).y+CLOUD_HEIGHT and cloud_borders(y-CLOUDS(i).y, x-CLOUDS(i).x) = '1') then
							colors:=get_color(cloud_colors(y-CLOUDS(i).y, x-CLOUDS(i).x));
							VGA_R <= colors(0);
							VGA_G <= colors(1);
							VGA_B <= colors(2);
					END IF;				
				end loop;
				--END DRAW CLOUDS
				
				--DRAW HILLS
				IF(x >= HILL1_X and x < HILL1_X + HILL_WIDTH and y >= HILL1_Y and y < HILL1_Y + HILL_HEIGTH and hill_borders(y-HILL1_Y, x-HILL1_X) = '1') then
						colors:=get_color(hill_colors(y-HILL1_Y, x-HILL1_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
						
				end if;
				
				IF(x >= HILL2_X and x < HILL2_X + HILL_WIDTH and y >= HILL2_Y and y < HILL2_Y + HILL_HEIGTH and hill_borders(y-HILL2_Y, x-HILL2_X) = '1') then
						colors:=get_color(hill_colors(y-HILL2_Y, x-HILL2_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
						
				end if;
				--END DRAW HILLS
				
				--DRAW BRICK
				for i in 0 to NUM_BLOCKS - 1 loop
					IF(x >= GAME(CURRENT_LEVEL)(i).x and x < GAME(CURRENT_LEVEL)(i).x + BLOCK_WIDTH and y >= GAME(CURRENT_LEVEL)(i).y and y < GAME(CURRENT_LEVEL)(i).y + BLOCK_HEIGHT) then
							colors:=get_color(brick_colors(y-GAME(CURRENT_LEVEL)(i).y, x-GAME(CURRENT_LEVEL)(i).x));
							VGA_R <= colors(0);
							VGA_G <= colors(1);
							VGA_B <= colors(2);
					end if;
				end loop;
				
				--DRAW FLOOR
				IF(x >= FLOOR_X and x < FLOOR_X + FLOOR_WIDTH and y >= FLOOR_Y and y < FLOOR_Y + FLOOR_HEIGTH) then
						colors:=get_color(floor_colors(y-FLOOR_Y, x-FLOOR_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
						
				end if;
				--END DRAW FLOOR
				
				--DRAW COIN
				IF(x >= COIN_X and x < COIN_X + COIN_WIDTH and y >= COIN_Y and y < COIN_Y + COIN_HEIGHT and coin_borders(y-COIN_Y, x-COIN_X) = '1') then
						colors:=get_color(coin_colors(y-COIN_Y, x-COIN_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				--END DRAW COIN
				
				--DRAW MARIO
				IF(x >= MARIO_X and x < MARIO_X + MARIO_WIDTH and y >= MARIO_Y and y < MARIO_Y + MARIO_HEIGHT and mario_borders(y-MARIO_Y, x-MARIO_X) = '1') then
						colors:=get_color(mario_colors(y-MARIO_Y, x-MARIO_X));
						VGA_R <= colors(0);
						VGA_G <= colors(1);
						VGA_B <= colors(2);
				end if;
				--END DRAW MARIO
				
			--outside visible screen	
			else
				VGA_R <= X"0";
				VGA_G <= X"0";
				VGA_B <= X"0";
			end if;
			
			--update coordinates
			if(horizontal_pointer = TOTAL_W-1) then			
				if(vertical_pointer = TOTAL_H-1) then 
					vertical_pointer <= 0;
				else
					vertical_pointer <= vertical_pointer + 1;
				end if;
				horizontal_pointer <= 0;
			else
				horizontal_pointer <= horizontal_pointer + 1;
			end if;
			
		end if;
	end process;
	
end architecture;