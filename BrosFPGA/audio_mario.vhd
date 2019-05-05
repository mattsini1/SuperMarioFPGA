library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mario_package.all;

entity audio_mario is
generic(
	AUDIO_PRESCALER_MAX_VALUE : integer := AUDIO_PRESCALER_MAX
);
port (
	clockAUDIO	: in std_logic;
	RESET		: in std_logic;
	
	----------WM8731 pins-----
	AUD_BCLK		: out std_logic;
	AUD_XCK		: out std_logic;
	AUD_DACLRCK	: out std_logic;
	AUD_DACDAT	: out std_logic;
	
	----------I2C pins-----
	I2C_SCLK		: out std_logic;
	I2C_SDAT		: inout std_logic;
	
	---------flash pins-----
	FL_ADDR : out std_logic_vector(21 downto 0);
	FL_DQ : in std_logic_vector(7 downto 0);
	FL_OE_N : out std_logic;
	FL_RST_N : out std_logic;
	FL_WE_N : out std_logic
	
);
end entity audio_mario;


architecture main of audio_mario is

	signal dac_ready : std_logic := '0';

	signal sample_buffer: std_logic_vector(31 downto 0):=(others=>'0');

	signal read_addr: integer range 0 to LAST_FLASH_ADDR:=0;
	signal song_speed_bit_prescaler: std_logic := '0';

	signal send_sample_flag: std_logic:='0';
	signal data_index: integer range 0 to 31:=0;
	signal sample_to_send: std_logic_vector(31 downto 0):=(others=>'0');	
	signal clk_en: std_logic:='0';
	signal audio_prescaler: integer range 0 to AUDIO_PRESCALER_MAX_VALUE:=0;

	component i2c is
	port(
		CLOCK_12: in std_logic;
		RESET: in std_logic;
		
		i2c_scl: out std_logic;
		i2c_sda: inout std_logic;

		dac_ready : out std_logic
	);
	end component i2c;	
	
begin

	AUD_BCLK <= clockAUDIO;
	AUD_XCK <= clockAUDIO;
	AUD_DACLRCK <= clk_en;		
	AUD_DACDAT <= sample_to_send(data_index);

	FL_RST_N <= '1';
	FL_WE_N <= '1';
	FL_OE_N <= '0';
	FL_ADDR <= std_logic_vector(to_unsigned(read_addr,22));

	WM8731: component i2c 
	port map(
		CLOCK_12=>clockAUDIO,
		RESET=>RESET,
		
		i2c_scl=>I2C_SCLK,
		i2c_sda=>I2C_SDAT,

		dac_ready => dac_ready
	);		

	AudioGenProcess : process(clockAUDIO, RESET)
	begin
		if(RESET = '1') then
			send_sample_flag <= '0';
			data_index	<= 0;
			sample_to_send	<= (others=>'0');
			audio_prescaler	<= 0;
			clk_en		<= '0';
		elsif(falling_edge(clockAUDIO)) then
					
			if(dac_ready = '1') then 
				if(audio_prescaler<AUDIO_PRESCALER_MAX_VALUE)then------48k sample rate
					audio_prescaler<=audio_prescaler+1;
					clk_en<='0';
				else
					audio_prescaler<=0;
					sample_to_send <= sample_buffer; --get sample
					clk_en<='1';
				end if;

				if(clk_en='1')then-------send new sample
					send_sample_flag<='1';
					data_index<=31;
				end if;

				if(send_sample_flag='1')then
					if(data_index>0)then
						data_index<=data_index-1;
					else 
						send_sample_flag<='0';
					end if;
				end if;	--if(send_sample_flag='1')
			end if; --if(dac_ready = '1')
		end if;	--if(falling_edge(clockAUDIO))
	end process;

	
	ReadAudioProcess: process (clockAUDIO, RESET)
	begin
		if(RESET = '1') then		
			read_addr<=0;
			song_speed_bit_prescaler<='0';
			sample_buffer<=(others=>'0');
		elsif(rising_edge(clockAUDIO)) then
			if(dac_ready = '1') then 
				if(clk_en='1')then	--48khz
				
					song_speed_bit_prescaler <= not song_speed_bit_prescaler;
					
					if(read_addr < LAST_FLASH_ADDR) then
						read_addr <= read_addr + 1;
					else
						read_addr <= 0;
					end if;
					
					if(song_speed_bit_prescaler = '0')  then
						sample_buffer(7 downto 0) <= FL_DQ;
						sample_buffer(23 downto 16) <= FL_DQ;
					else
						sample_buffer(15 downto 8) <= FL_DQ;
						sample_buffer(31 downto 24) <= FL_DQ;
					end if;		
				end if;	--if(clk_en='1')
			end if; --if(dac_ready = '1') then 
		end if;	--if(rising_edge(clockAUDIO))
	end process;
	
end architecture main;
