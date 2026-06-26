library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity isacle_rom_16x16 is
  port (
    rd_addr : in  unsigned(3 downto 0);
    rd_data : out unsigned(15 downto 0)
  );
end entity isacle_rom_16x16;

architecture rtl of isacle_rom_16x16 is
  type rom_t is array(0 to 15) of unsigned(15 downto 0);
  constant ROM : rom_t := (to_unsigned(49153, 16), to_unsigned(49160, 16), to_unsigned(61199, 16), to_unsigned(37632, 16), to_unsigned(97, 16), to_unsigned(58629, 16), to_unsigned(37632, 16), to_unsigned(98, 16), to_unsigned(38008, 16), to_unsigned(53247, 16), to_unsigned(61215, 16), to_unsigned(9985, 16), to_unsigned(37632, 16), to_unsigned(98, 16), to_unsigned(38168, 16), to_unsigned(0, 16));
begin
  rd_data <= ROM(to_integer(rd_addr));
end architecture rtl;
