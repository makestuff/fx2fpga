--
-- Copyright (C) 2009 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fx2fpga is
	generic(
		COUNTER_WIDTH: natural := 18
	);
	port(
		reset : in std_logic;
		ifclk : in std_logic;
		fifoAddr : out std_logic_vector(1 downto 0);
		flagA : out std_logic;  -- These are really inputs, but tristate outs are good enough
		flagB : out std_logic;
		gotData : in std_logic;
		slrd : out std_logic;
		sloe : out std_logic;
		slwr : out std_logic;
		pktEnd : out std_logic;
		sseg : out std_logic_vector(7 downto 0);
		anode : out std_logic_vector(3 downto 0);
		fd : in std_logic_vector(7 downto 0);
		sw : in std_logic_vector(1 downto 0);
		led_out : out std_logic_vector(7 downto 0)
	);
end fx2fpga;

architecture arch of fx2fpga is
	signal counter, counter_next: unsigned(COUNTER_WIDTH-1 downto 0);
	signal hex: std_logic_vector(3 downto 0);
	signal checksum, checksum_next: unsigned(15 downto 0);
	--signal oldValue, oldValue_next: std_logic_vector(7 downto 0);
	signal led, led_next: std_logic_vector(7 downto 0);
begin
	process(ifclk, reset)
	begin
		if ( reset = '1' ) then
			counter <= (others => '0');
			checksum <= (others => '0');
			led <= (others => '0');
			--oldValue <= (others => '0');
		elsif ( ifclk'event and ifclk = '1' ) then
			counter <= counter_next;
			checksum <= checksum_next;
			led <= led_next;
			--oldValue <= oldValue_next;
		end if;
	end process;

	-- binary counter
	counter_next <= counter + 1;
	
	led_out <= led;
	--oldValue_next <= fd;
	
	fifoAddr <= sw;
	flagA <= 'Z';
	flagB <= 'Z';
	sloe <= '0';
	slrd <= '0';
	slwr <= '1';
	pktEnd <= '1';

	--checksum_next <=
	--	checksum + 1 when gotData = '1' and oldValue /= fd
	--	else checksum;
	checksum_next <=
		checksum + unsigned(fd) when gotData = '1'
		else checksum;

	led_next <=
		fd when gotData = '1'
		else led;

	-- process to choose which 7-seg display to light
	process(counter(17 downto 16), checksum)
	begin
		case counter(17 downto 16) is
			when "00" =>
				anode <= "1110";
				hex <= std_logic_vector(checksum(3 downto 0));
				sseg(7) <= '1';
			when "01" =>
				anode <= "1101";
				hex <= std_logic_vector(checksum(7 downto 4));
				sseg(7) <= '1';
			when "10" =>
				anode <= "1011";
				hex <= std_logic_vector(checksum(11 downto 8));
				sseg(7) <= '1';
			when others =>
				anode <= "0111";
				hex <= std_logic_vector(checksum(15 downto 12));
				sseg(7) <= '1';
		end case;
	end process;

	-- combinatorial logic to display the correct pattern based
	-- on the output of the selector process above.
	with hex select
		sseg(6 downto 0) <=
			"0000001" when "0000",
			"1001111" when "0001",
			"0010010" when "0010",
			"0000110" when "0011",
			"1001100" when "0100",
			"0100100" when "0101",
			"0100000" when "0110",
			"0001111" when "0111",
			"0000000" when "1000",
			"0000100" when "1001",
			"0001000" when "1010",  -- a
			"1100000" when "1011",  -- b
			"0110001" when "1100",  -- c
			"1000010" when "1101",  -- d
			"0110000" when "1110",  -- e
			"0111000" when others;  -- f
end arch;
