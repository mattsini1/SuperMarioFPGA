library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;

entity mario_snes is 
	port (
		CLOCK 		: in std_logic;
		RESET		: in std_logic;
		
		--PIN DI OUTPUT SNES
		CLOCK_PIN	: out std_logic;
		LATCH_PIN	: out std_logic;
		
		--PIN DI INPUT SNES
		DATA_PIN		: in std_logic;
		
		--SEGNALI INVIATI ALLA CONTROL UNIT
		
		LEFT_PRESSED : out std_logic;
		RIGHT_PRESSED : out std_logic;
		UP_PRESSED : out std_logic;
		DOWN_PRESSED : out std_logic;
		
		B_PRESSED : out std_logic;
		Y_PRESSED : out std_logic;
		X_PRESSED : out std_logic;
		A_PRESSED : out std_logic;
		
		START_PRESSED : out std_logic;
		SELECT_PRESSED : out std_logic;
		
		L_PRESSED : out std_logic;
		R_PRESSED : out std_logic
		
	);
end entity;


architecture RTL of mario_snes is

	--questo tipo di dato definisce lo stato di lettura del controller snes
	--L : STATO DI ATTIVAZIONE LATCH 12us
	--WC : STATO DI ATTESA 6us PRIMA DELL'ATTIVAZIONE DEL CLOCK
	--WL : STATO DI ATTESA 6us PRIMA DELL'ATTIVAZIONE DEL LATCH
	--C : STATO DI INVIO CLOCK AL CONTROLLER CON PERIODO 12us
	type snes_state is (L,WC,WL,C);
	
	
-- 600 clk = 12us
-- 300 clk = 6us

signal   clock_counter_timer    : integer range 0 to 600;
signal   clock_counter    : integer range 0 to 16;
signal 	current_state	:	snes_state;
signal 	current_clock	:	std_logic;  



begin
	
	CLOCK_PIN<=current_clock;
	
	SnesProcess : process(CLOCK,RESET)
		constant STATE_AT_RESET :	snes_state:= L;
		begin
			if rising_edge(CLOCK) then
				if (RESET = '1') then
					current_state<=STATE_AT_RESET;
					clock_counter_timer<=0;
					current_clock<='1';
					LATCH_PIN<='1';
					--RESET SEGNALI DATAPATH
					
					LEFT_PRESSED <='0';
					RIGHT_PRESSED <='0';
					UP_PRESSED <='0';
					DOWN_PRESSED <='0';
					
					B_PRESSED <='0';
					Y_PRESSED <='0';
					X_PRESSED <='0';
					A_PRESSED <='0';
					
					START_PRESSED <='0';
					SELECT_PRESSED <='0';
					
					L_PRESSED<='0';
					R_PRESSED<='0';
					
				else
					--INIZIO CORPO LATCH
					
					if (current_state=L) then
						--stato di attivazione del latch
						if (clock_counter_timer<600) then
							clock_counter_timer<=clock_counter_timer+1;
						else
							--tempo di attivazione latch scaduto
							LATCH_PIN<='0';
							current_state<=WC;
							clock_counter_timer<=0;
						end if;
					end if;
					--FINE CORPO LATCH
					
					-- INIZIO CORPO WAIT CLOCK
					if (current_state=WC) then
						--stato di wait 6us
						if (clock_counter_timer<300) then
							clock_counter_timer<=clock_counter_timer+1;
						else
							--tempo di wait scaduto
							current_state<=C;
							clock_counter_timer<=0;
							--ATTIVO IL CLOCK_PIN
							current_clock<='0';
							clock_counter<=1;
						end if;
					end if;
					-- FINE CORPO WAIT CLOCK
					
					-- INIZIO CORPO WAIT LATCH
					if (current_state=WL) then
						--stato di wait 6us
						if (clock_counter_timer<300) then
							clock_counter_timer<=clock_counter_timer+1;
						else
							current_state<=L;
							LATCH_PIN<='1';
							clock_counter<=0;
							clock_counter_timer<=0;
						end if;
					end if;
					-- FINE CORPO WAIT LATCH
					
					-- INIZIO CORPO CLOCK
					if (current_state=C) then
						if (current_clock='0') then
							--CLOCK BASSO
							if (clock_counter_timer<300) then
								clock_counter_timer<=clock_counter_timer+1;
								--LEGGO DATA_PIN
								
								--CASE
								if(DATA_PIN='0') then
									-- CHECK BUTTON
									case clock_counter is
										
										when 1 =>
											B_PRESSED<='1';
										
										when 2 =>
											Y_PRESSED<='1';
										
										when 3 =>
											SELECT_PRESSED<='1';
										
										when 4 =>
											START_PRESSED<='1';
											
										when 5 =>
											UP_PRESSED<='1';
											
										when 6 =>
											DOWN_PRESSED<='1';
										
										when 7 =>
											LEFT_PRESSED<='1';
											
										when 8 =>
											RIGHT_PRESSED<='1';
											
										when 9 =>
											A_PRESSED<='1';
										
										when 10 =>
											X_PRESSED<='1';
											
										when 11 =>
											L_PRESSED<='1';

											when 12 =>
											R_PRESSED<='1';
											
										when others =>
											LEFT_PRESSED <='0';
											RIGHT_PRESSED <='0';
											UP_PRESSED <='0';
											DOWN_PRESSED <='0';
											
											B_PRESSED <='0';
											Y_PRESSED <='0';
											X_PRESSED <='0';
											A_PRESSED <='0';
											
											START_PRESSED <='0';
											SELECT_PRESSED <='0';
											
											L_PRESSED<='0';
											R_PRESSED<='0';
										
									end case;
								else
									LEFT_PRESSED <='0';
									RIGHT_PRESSED <='0';
									UP_PRESSED <='0';
									DOWN_PRESSED <='0';
									
									B_PRESSED <='0';
									Y_PRESSED <='0';
									X_PRESSED <='0';
									A_PRESSED <='0';
									
									START_PRESSED <='0';
									SELECT_PRESSED <='0';
									
									L_PRESSED<='0';
									R_PRESSED<='0';
								end if;
								
								--FINE LETTURA DATA_PIN
							else
								current_clock<='1';
								clock_counter_timer<=0;
								--HO RAGGIUNTO I 16 COLPI DI CLOCK INVIATI AL CONTROLLER SNES
								if (clock_counter=16) then
									current_state<=WL;
								end if;
							end if;
						else
							--CLOCK ALTO
							if (clock_counter<16) then
								if (clock_counter_timer<300) then
									clock_counter_timer<=clock_counter_timer+1;
								else
									current_clock<='0';
									clock_counter<=clock_counter+1;
									clock_counter_timer<=0;
								end if;
							end if;
						end if;
					end if;
					-- FINE CORPO CLOCK
				end if;
			end if;
		end process;
end architecture;
