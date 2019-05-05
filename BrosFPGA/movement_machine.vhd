library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.vga_package.all;

entity movement_machine is 
	generic (
		MARIOHEIGHT : natural := MARIO_HEIGHT; -- mario height
		MARIOWIDTH : natural := MARIO_WIDTH; -- mario width
		MAX_JUMP_HEIGHT : natural := JUMP_UNIT;
		SCREEN_HEIGHT : natural := VISIBLE_HEIGHT; -- screen max height (480)
		SCREEN_WIDTH : natural := VISIBLE_WIDTH; -- screen max width (640)
		TOP_BORDER : natural := BOUND_TOP; -- top border
		LEFT_BORDER : natural := BOUND_LEFT; -- left border
		RIGHT_BORDER : natural := BOUND_RIGHT; -- right border
		BOTTOM_BORDER : natural := BOUND_BOTTOM; -- bottom border
		CYCLES_TO_WASTE_JUMP : natural := 5; -- waste tuning in jump
		CYCLES_TO_WASTE_MOVEMENT : natural := 1 -- waste tuning in movement
	);
	
	port (
		CLOCK : in std_logic; -- clock in
		RESET : in std_logic; -- reset async
		
		I_CONTROLLER_BUTTON_SX : in std_logic; -- controller sx button
		I_CONTROLLER_BUTTON_DX : in std_logic; -- controller dx button
		I_CONTROLLER_BUTTON_UP : in std_logic; -- controller up button
		I_COLLISION_SX : in std_logic; -- collision sx
		I_COLLISION_DX : in std_logic; -- collision dx
		I_COLLISION_UP : in std_logic;
		I_COLLISION_DOWN : in std_logic; -- collision down
		I_GAME_CLOCK : in std_logic; -- clockish
		
		D_LED : out std_logic_vector(3 downto 0);
		
		O_REQUEST_COLLISION_SX : out std_logic; -- request to move sx
		O_REQUEST_COLLISION_DX : out std_logic; -- request to move dx
		O_REQUEST_COLLISION_DOWN : out std_logic; -- request to move down
		O_REQUEST_COLLISION_UP : out std_logic; -- request to move up
		O_REQUEST_NEXT_X : out natural; -- x of the request
		O_REQUEST_NEXT_Y : out natural; -- y of the request
		O_X : out natural; -- actual next x
		O_Y : out natural -- actual next y
	);
end entity;

architecture behav of movement_machine is
	signal S_WASTE_CYCLES_JUMP : natural range 0 to CYCLES_TO_WASTE_JUMP;
	signal S_WASTE_CYCLES_LATERAL_MOVEMENT : natural range 0 to CYCLES_TO_WASTE_MOVEMENT;
	signal S_JUMP_HIGHEST_POINT : natural;
	signal S_PROCESS_JUMP_PHASE : boolean;
begin

	MovementProcess : process(CLOCK, RESET)
		variable NEW_X : natural range 0 to GAME_WIDTH;
		variable NEW_Y : natural range 0 to GAME_HEIGHT;
		variable IS_JUMPING : boolean;
		variable IS_FALLING : boolean;
	begin
		if RESET = '1' then -- reset procedure
			NEW_X := MARIO_STARTING_POSX;--I_Y;
			NEW_Y := MARIO_STARTING_POSY;--I_X;
			IS_JUMPING := false;
			IS_FALLING := false;
		elsif rising_edge(CLOCK) then
			if I_GAME_CLOCK = '1' then
				if S_PROCESS_JUMP_PHASE then
					if S_WASTE_CYCLES_JUMP = 0 then
						D_LED(2) <= I_CONTROLLER_BUTTON_UP;
						
						O_REQUEST_COLLISION_DOWN <= '0';
						if I_CONTROLLER_BUTTON_UP = '1' and not IS_JUMPING and not IS_FALLING then
							IS_JUMPING := true;
							S_JUMP_HIGHEST_POINT <= NEW_Y - MAX_JUMP_HEIGHT;
						end if;
						
						if IS_JUMPING then
							if NEW_Y <= S_JUMP_HIGHEST_POINT then -- reached vertex
								IS_JUMPING := false;
								IS_FALLING := true;
							else
								O_REQUEST_COLLISION_UP <= '1'; -- requests if we can go up
								NEW_Y := NEW_Y - 1;
							end if;
						elsif IS_FALLING then -- we are falling! (and can't get up! D:)
								O_REQUEST_COLLISION_DOWN <= '1';
								NEW_Y := NEW_Y + 1;
						else
							O_REQUEST_COLLISION_DOWN <= '1';
						end if;
						O_REQUEST_NEXT_X <= NEW_X; -- send the request
						O_REQUEST_NEXT_Y <= NEW_Y;
						
						D_LED(1) <= I_COLLISION_DOWN;
						if I_COLLISION_DOWN = '1' then
							if IS_FALLING then
								NEW_Y := NEW_Y - 1;
								IS_FALLING := false;
							end if;
						else
							IS_FALLING := true;
						end if;
						if I_COLLISION_UP = '1' and IS_JUMPING then
							NEW_Y := NEW_Y + 1;
							IS_JUMPING := false;
							IS_FALLING := true;
						end if;
					end if;
					S_WASTE_CYCLES_JUMP <= S_WASTE_CYCLES_JUMP + 1 rem CYCLES_TO_WASTE_JUMP; -- waste clocks
				else
					if S_WASTE_CYCLES_LATERAL_MOVEMENT = 0 then
						O_REQUEST_COLLISION_DX <= '0';
						O_REQUEST_COLLISION_SX <= '0';
						
						if I_CONTROLLER_BUTTON_SX = '1' then -- if button left is pressed
							O_REQUEST_COLLISION_SX <= '1';
							NEW_X := NEW_X - 1 ; -- mario's next x lefted
						elsif I_CONTROLLER_BUTTON_DX='1' then -- if button right is pressed
							O_REQUEST_COLLISION_DX <= '1';
							NEW_X := NEW_X + 1; -- mario's next x righted
						end if;
						O_REQUEST_NEXT_X <= NEW_X; -- send the request
						O_REQUEST_NEXT_Y <= NEW_Y;
						--check the request
						if I_COLLISION_SX = '1' then
							NEW_X := NEW_X + 1;
						end if;
						if I_COLLISION_DX = '1' then
							NEW_X := NEW_X - 1;
						end if;
					end if;
					S_WASTE_CYCLES_LATERAL_MOVEMENT <= S_WASTE_CYCLES_LATERAL_MOVEMENT + 1 rem CYCLES_TO_WASTE_MOVEMENT;
				end if;
				S_PROCESS_JUMP_PHASE <= not S_PROCESS_JUMP_PHASE;
				O_X <= NEW_X;
				O_Y <= NEW_Y;
			end if;
		end if;
	end process;

end architecture;