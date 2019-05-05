library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;
use work.level_package.all;

entity buzzer is 
	port (
		CLOCK 		: in std_logic;
		RESET		: in std_logic;
		STATE 		: in mario_state;
		BUZZER_PIN : out std_logic;	
		--SEGNALI RICEVUTI DAL DATAPATH
		COIN_CATCHED : in std_logic
	);
end entity;


architecture RTL of buzzer is

signal one_sec_timer	 : integer range 0 to BEEP_DURATION:=0;

begin
	
	CoinCathed : process(CLOCK, RESET)
		variable stop : boolean := false;
		begin
			if RESET='1' then
				one_sec_timer<=0;
				BUZZER_PIN<='0';
				stop:=false;
			elsif (rising_edge(CLOCK)) then
				
				if(COIN_CATCHED='1' AND STATE/=PAUSE) then
					stop:=true;
				end if;
				
				if (stop=true) then
					if(one_sec_timer<BEEP_DURATION) then
						one_sec_timer<=one_sec_timer+1;
						BUZZER_PIN<='1';
					else
						one_sec_timer<=0;
						BUZZER_PIN<='0';
						stop:=false;
					end if;
				end if;
			end if;
		end process;
	
end architecture;