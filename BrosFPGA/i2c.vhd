library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mario_package.all;

			entity i2c is
			port(
				CLOCK_12			: in std_logic;
				RESET				: in std_logic;
				
				I2C_SCL			: out std_logic;
				I2C_SDA			: inout std_logic;

				DAC_READY		: out std_logic
			);
			end i2c;


architecture RTL of i2c is

	constant i2c_addr : std_logic_vector(7 downto 0) := "00110100";

	type fsm is (IDLE, START, ADDR, ACK_ADDR, FIRST, ACK_FIRST, SECOND, ACK_SECOND, STOP);
	
	signal i2c_fsm:fsm:=IDLE;

	signal i2c_clk_en: std_logic:='0';
	signal clk_prs: integer range 0 to I2C_PRESCALER:=0;
	signal clk_en: std_logic:='0';
	signal ack_en: std_logic:='0';
	signal clk_i2c: std_logic:='0';
	signal get_ack: std_logic:='0';
	signal data_index: integer range 0 to 15:=0;

	signal init_counter		: integer range 0 to 15:=0;
	signal init					: std_logic:='0';

	signal i2c_busy: std_logic := '0';
	signal i2c_send_flag: std_logic := '0';
	signal i2c_done: std_logic := '0';
	signal i2c_data: std_logic_vector(15 downto 0) := "0000000000000000";
	
	signal in_idle : std_logic := '0';
	signal idle_state		: std_logic:='1';
	
begin

	------generate two clocks for i2c and data transitions
	i2cClockProcess : process(CLOCK_12, RESET)
	begin
	
		if(RESET = '1') then
			clk_prs	<= 0;
			clk_en 	<= '0';
			ack_en 	<= '0';
			clk_i2c	<= '0';
		elsif rising_edge(CLOCK_12) then
		
			if(clk_prs<I2C_PRESCALER)then
				clk_prs<=clk_prs+1;
			else
				clk_prs<=0;
			end if;
			
			if(clk_prs<I2C_PRESCALER/2)then ---50 % duty cylce clock for i2c
				clk_i2c<='1';
			else
				clk_i2c<='0';
			end if;

			---- clock for ack  on SCL=HIGH
			if(clk_prs=I2C_PRESCALER/4)then 
				ack_en<='1';
			else
				ack_en<='0';
			end if;
			---- clock for data on SCL=LOW
			if(clk_prs=I2C_PRESCALER/2 + I2C_PRESCALER/4)then 
				clk_en<='1';
			else
				clk_en<='0';
			end if;
		end if;	--if(rising_edge(CLOCK_12))
	end process;

	FSMI2CProcess : process(CLOCK_12, RESET)
	begin
		if(RESET = '1') then	
			i2c_fsm 	<= IDLE;
			in_idle<='1';
			get_ack 		<= '0';
			data_index	<= 0;	
			i2c_clk_en <= '0';
			i2c_busy	<= '0';
			i2c_done <= '0';
		elsif(rising_edge(CLOCK_12)) then

			if(i2c_clk_en='1')then
				I2C_SCL<=clk_i2c;
			else 
				I2C_SCL<='1';
			end if;

			----ack on SCL=HIGH
			if(ack_en='1')then
				case i2c_fsm is
					when ACK_ADDR=> ---- get ack
						if(I2C_SDA='0')then
							i2c_fsm<=FIRST;---ack
							data_index<=15;			
						else
							i2c_clk_en<='0';
							i2c_fsm<=IDLE;---nack
							in_idle<='1';
						end if;

					when ACK_FIRST=> --- get ack
						if(I2C_SDA='0')then
							i2c_fsm<=SECOND;---ack
							data_index<=7;			
						else
							in_idle<='1';
							i2c_fsm<=IDLE;---nack
							i2c_clk_en<='0';
						end if;

					when ACK_SECOND => ----get ack
						if(I2C_SDA='0')then
							i2c_fsm<=STOP;---ack
						else
							in_idle<='1';
							i2c_fsm<=IDLE;---nack
							i2c_clk_en<='0';
						end if;	

					when others=>NULL;
				end case;
			end if;	--if(ack_en='1')

			-----data tranfer on SCL=LOW
			if(clk_en='1')then
				case i2c_fsm is
					when IDLE=> ----------stand by
						I2C_SDA<='1';
						i2c_busy<='0';
						i2c_done<='0';
						if(i2c_send_flag='1')then
							i2c_fsm<=START;
							in_idle<='0';
							i2c_busy<='1';
						end if;

					when START=> -------start condition
						I2C_SDA<='0';
						i2c_fsm<=ADDR;
						data_index<=7;
						
					when ADDR=> -------send addr
						i2c_clk_en<='1';---start clocking I2C_SCL
						if(data_index>0) then
							data_index<=data_index-1;
							I2C_SDA<=i2c_addr(data_index);
						else
							I2C_SDA<=i2c_addr(data_index);
							get_ack<='1';
						end if;
						if(get_ack='1')then
							get_ack<='0';
							i2c_fsm<=ACK_ADDR;
							I2C_SDA<='Z';
						end if;

					when FIRST=> ---- send 1st 8 bit
						if(data_index>8) then
							data_index<=data_index-1;
							I2C_SDA<=i2c_data(data_index);
						else
							I2C_SDA<=i2c_data(data_index);
							get_ack<='1';
						end if;
						if(get_ack='1')then
							get_ack<='0';
							i2c_fsm<=ACK_FIRST;
							I2C_SDA<='Z';				
						end if;

					when SECOND => ---send 2nd 8 bit
						if(data_index>0) then
							data_index<=data_index-1;
							I2C_SDA<=i2c_data(data_index);
						else
							I2C_SDA<=i2c_data(data_index);
							get_ack<='1';
						end if;
						if(get_ack='1')then
							get_ack<='0';
							i2c_fsm<=ACK_SECOND;
							I2C_SDA<='Z';
						end if;

					when STOP => --stop condition
						i2c_clk_en<='0';
						I2C_SDA<='0';
						i2c_fsm<=IDLE;
						in_idle<='1';
						i2c_done<='1';
				
					when others=>NULL;
					
				end case;	--case i2c_fsm
			end if;	--if(clk_en='1')
		end if;	--if(rising_edge(CLOCK_12))
	end process;

	InitProcess: process(CLOCK_12, RESET)
	begin
		if(RESET = '1') then
			init <= '0';
			dac_ready<='0';
			idle_state<='1';
			init_counter <= 0;
			i2c_send_flag <= '0';
			i2c_data <= "0000000000000000";
		elsif(rising_edge(CLOCK_12)) then

			if(in_idle='0' AND idle_state='0') then
				idle_state<='1';
			end if;
			
			if(in_idle='1' AND idle_state='1' AND init = '0' ) then
				case init_counter is
					when 0 =>
						---reset
						i2c_data(15 downto 9)<="0001111";
						i2c_data(8 downto 0)<="000000000";
						i2c_send_flag<='1';					
					when 1 =>
						--activ interface
						i2c_data(15 downto 9)<="0001001";
						i2c_data(8 downto 0)<="111111111";
						i2c_send_flag<='1';
						
					when 2 =>
						--ADC off, DAC on, Linout ON, Power ON
						i2c_data(15 downto 9)<="0000110";
						i2c_data(8 downto 0)<="000000111";
						i2c_send_flag<='1';
						
					when 3 =>
						--Digital Interface: DSP, 16 bit, slave mode
						i2c_data(15 downto 9)<="0000111";
						i2c_data(8 downto 0)<="000010011";	
						i2c_send_flag<='1';
					when 4 =>
						--HEADPHONE VOLUME						
						i2c_data(15 downto 9)<="0000010";
						i2c_data(8 downto 0)<="101111001";
						i2c_send_flag<='1';
					when 5 =>
						---USB mode
						i2c_data(15 downto 9)<="0001000";
						i2c_data(8 downto 0)<="000000001";
						i2c_send_flag<='1';
					when 6 =>
						--Enable DAC to LINOUT
						i2c_data(15 downto 9)<="0000100";
						i2c_data(8 downto 0)<="000010010";
						i2c_send_flag<='1';
					when 7 =>
						--remove mute DAC
						i2c_data(15 downto 9)<="0000101";
						i2c_data(8 downto 0)<="000000000";
						i2c_send_flag<='1';
						init <= '1';
						dac_ready<='1';
					when others =>
						--should never happen...
						i2c_data(15 downto 9)<="0000000";
						i2c_data(8 downto 0)<="000000000";
						i2c_send_flag<='0';
				end case;	--case init_counter is	
				init_counter <= init_counter + 1;
				idle_state<='0';
			end if;
		end if;	--if(rising_edge(CLOCK_12))
	
	end process;
end RTL;