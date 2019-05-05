library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.level_package.all;
use work.mario_package.all;

package level_package is
	
	constant NUM_BLOCKS : natural := 6;
	constant NUM_COIN_PER_LEVEL : natural := 15;
	constant NUM_LEVELS : natural := 5;
	
	constant MAX_COIN : natural := 10;
	
	type t_blocks_array is array(0 to NUM_BLOCKS-1) of coord; -- coordinate type

--LEVEL 1-----------------------------------------------------------------------------	
	constant BLOCCO_1 : coord :=(
		x => 70,
		y => 400
	);
	
	constant BLOCCO_2 : coord :=(
		x => 140,
		y => 340
	);
	
	constant BLOCCO_3 : coord :=(
		x => 210,
		y => 280
	);
	
	constant BLOCCO_4 : coord :=(
		x => 280,
		y => 220
	);
	
	constant BLOCCO_5 : coord :=(
		x => 350,
		y => 160
	);
	
	constant BLOCCO_6 : coord :=(
		x => 420,
		y => 100
	);		
	
--LEVEL 1-----------------------------------------------------------------------------	
	
--LEVEL 2-----------------------------------------------------------------------------	
	constant BLOCCO_7 : coord :=(
		x => 245,
		y => 400
	);
	
	constant BLOCCO_8 : coord :=(
		x => 70,
		y => 360
	);
	
	constant BLOCCO_9 : coord :=(
		x => 415,
		y => 360
	);
	
	constant BLOCCO_10 : coord :=(
		x => 130,
		y => 265
	);
	
	constant BLOCCO_11 : coord :=(
		x => 365,
		y => 265
	);
	
	constant BLOCCO_12 : coord :=(
		x => 245,
		y => 170
	);	
--LEVEL 2-----------------------------------------------------------------------------		

--LEVEL 3-----------------------------------------------------------------------------	
	constant BLOCCO_13 : coord :=(
		x => 65,
		y => 388
	);
	
	constant BLOCCO_14 : coord :=(
		x => 439,
		y => 388
	);
	
	constant BLOCCO_15 : coord :=(
		x => 125,
		y => 294
	);
	
	constant BLOCCO_16 : coord :=(
		x => 377,
		y => 294
	);
	
	constant BLOCCO_17 : coord :=(
		x => 179,
		y => 200
	);
	
	constant BLOCCO_18 : coord :=(
		x => 324,
		y => 200
	);		
	
--LEVEL 3-----------------------------------------------------------------------------					
	
--LEVEL 4-----------------------------------------------------------------------------	
	constant BLOCCO_19 : coord :=(
		x => 90,
		y => 385
	);
	
	constant BLOCCO_20 : coord :=(
		x => 90,
		y => 188
	);
	
	constant BLOCCO_21 : coord :=(
		x => 404,
		y => 188
	);
	
	constant BLOCCO_22 : coord :=(
		x => 404,
		y => 385
	);
	
	constant BLOCCO_23 : coord :=(
		x => 247,
		y => 263
	);
	
	constant BLOCCO_24 : coord :=(
		x => 247,
		y => 330
	);		
	
--LEVEL 4-----------------------------------------------------------------------------	

--LEVEL 5-----------------------------------------------------------------------------	
	constant BLOCCO_25 : coord :=(
		x => 175,
		y => 400
	);
	
	constant BLOCCO_26 : coord :=(
		x => 320,
		y => 340
	);
	
	constant BLOCCO_27 : coord :=(
		x => 175,
		y => 280
	);
	
	constant BLOCCO_28 : coord :=(
		x => 320,
		y => 220
	);
	
	constant BLOCCO_29 : coord :=(
		x => 175,
		y => 160
	);
	
	constant BLOCCO_30 : coord :=(
		x => 320,
		y => 100
	);		
	
--LEVEL 5-----------------------------------------------------------------------------	 	
	
	constant LEVEL_1 : t_blocks_array := (BLOCCO_1, BLOCCO_2, BLOCCO_3, BLOCCO_4, BLOCCO_5, BLOCCO_6); -- all the blocks are stored here
	constant LEVEL_2 : t_blocks_array := (BLOCCO_7, BLOCCO_8, BLOCCO_9, BLOCCO_10, BLOCCO_11, BLOCCO_12); -- all the blocks are stored here
	constant LEVEL_3 : t_blocks_array := (BLOCCO_13,BLOCCO_14, BLOCCO_15, BLOCCO_16, BLOCCO_17, BLOCCO_18); -- all the blocks are stored here
	constant LEVEL_4 : t_blocks_array := (BLOCCO_19,BLOCCO_20, BLOCCO_21,BLOCCO_22, BLOCCO_23, BLOCCO_24); -- all the blocks are stored here
	constant LEVEL_5 : t_blocks_array := (BLOCCO_25,BLOCCO_26,BLOCCO_27,BLOCCO_28, BLOCCO_29, BLOCCO_30); -- all the blocks are stored here

	type matrix_levels is array (0 to NUM_LEVELS-1) of t_blocks_array;
	
	constant GAME : matrix_levels := (LEVEL_1, LEVEL_2, LEVEL_3, LEVEL_4, LEVEL_5);

	type t_coins_array is array(0 to MAX_COIN-1) of coord; -- coordinate type
	type matrix_coins is array (0 to NUM_LEVELS-1) of t_coins_array;	
		
	constant C_11 : coord :=(x => 120,y => 368);		
	constant C_12 : coord :=(x => 157,y => 308);		
	constant C_13 : coord :=(x => 310,y => 248);		
	constant C_14 : coord :=(x => 280,y => 188);		
	constant C_15 : coord :=(x => 410,y => 128);		
	constant C_16 : coord :=(x => 430,y => 68);		
	constant C_17 : coord :=(x => 290,y => 248);		
	constant C_18 : coord :=(x => 280,y => 188);		
	constant C_19 : coord :=(x => 530,y => 68);		
	constant C_110 : coord :=(x => 162,y => 308);	

	constant C_21 : coord :=(x => 308,y => 360);		
	constant C_22 : coord :=(x => 250,y => 368);		
	constant C_23 : coord :=(x => 305,y => 138);		
	constant C_24 : coord :=(x => 200,y => 233);		
	constant C_25 : coord :=(x => 370,y => 233);		
	constant C_26 : coord :=(x => 480,y => 233);		
	constant C_27 : coord :=(x => 163,y => 328);		
	constant C_28 : coord :=(x => 500,y => 328);		
	constant C_29 : coord :=(x => 360,y => 138);		
	constant C_210 : coord :=(x => 193,y => 170);		
	
	constant C_31 : coord :=(x => 308,y => 284);		
	constant C_32 : coord :=(x => 300,y => 380);		
	constant C_33 : coord :=(x => 227,y => 356);		
	constant C_34 : coord :=(x => 476,y => 356);		
	constant C_35 : coord :=(x => 312,y => 258);		
	constant C_36 : coord :=(x => 377,y => 258);		
	constant C_37 : coord :=(x => 473,y => 262);		
	constant C_38 : coord :=(x => 204,y => 168);		
	constant C_39 : coord :=(x => 300,y => 168);		
	constant C_310 : coord :=(x => 420,y => 168);	
	
	constant C_41 : coord :=(x => 70,y => 260);		
	constant C_42 : coord :=(x => 550,y => 330);		
	constant C_43 : coord :=(x => 303,y => 231);		
	constant C_44 : coord :=(x => 372,y => 231);		
	constant C_45 : coord :=(x => 100,y => 156);		
	constant C_46 : coord :=(x => 420,y => 156);		
	constant C_47 : coord :=(x => 149,y => 353);		
	constant C_48 : coord :=(x => 502,y => 353);		
	constant C_49 : coord :=(x => 367,y => 298);		
	constant C_410 : coord :=(x => 267,y => 298);		
	
	constant C_51 : coord :=(x => 420,y => 68);		
	constant C_52 : coord :=(x => 180,y => 68);		
	constant C_53 : coord :=(x => 295,y => 128);		
	constant C_54 : coord :=(x => 426,y => 188);		
	constant C_55 : coord :=(x => 273,y => 248);		
	constant C_56 : coord :=(x => 348,y => 308);		
	constant C_57 : coord :=(x => 264,y => 368);		
	constant C_58 : coord :=(x => 154,y => 204);		
	constant C_59 : coord :=(x => 540,y => 437);		
	constant C_510 : coord :=(x => 161,y => 290);		
	
	constant LEVEL_C1 : t_coins_array := (C_11, C_12, C_13, C_14, C_15, C_16, C_17, C_18, C_19, C_110);
	constant LEVEL_C2 : t_coins_array := (C_21, C_22, C_23, C_24, C_25, C_26, C_27, C_28, C_29, C_210);
	constant LEVEL_C3 : t_coins_array := (C_31, C_32, C_33, C_34, C_35, C_36, C_37, C_38, C_39, C_310);
	constant LEVEL_C4 : t_coins_array := (C_41, C_42, C_43, C_44, C_45, C_46, C_47, C_48, C_49, C_410);
	constant LEVEL_C5 : t_coins_array := (C_51, C_52, C_53, C_54, C_55, C_56, C_57, C_58, C_59, C_510);

	constant GAME_COINS : matrix_coins := (LEVEL_C1, LEVEL_C2, LEVEL_C3, LEVEL_C4, LEVEL_C5);


--end level package
end package;


--body level package
package body level_package is

end level_package;