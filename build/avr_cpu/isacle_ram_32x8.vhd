library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity isacle_ram_32x8 is
  port (
    clk     : in  std_logic;
    rd_addr : in  unsigned(4 downto 0);
    wr_addr : in  unsigned(4 downto 0);
    wr_data : in  unsigned(7 downto 0);
    wr_en   : in  std_logic;
    rd_data : out unsigned(7 downto 0)
  );
end entity isacle_ram_32x8;

architecture rtl of isacle_ram_32x8 is
  type ram_t is array(0 to 31) of unsigned(7 downto 0);
  signal ram_r : ram_t := (to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8), to_unsigned(0, 8));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if wr_en = '1' then
        ram_r(to_integer(wr_addr)) <= wr_data;
      end if;
    end if;
  end process;
  rd_data <= ram_r(to_integer(rd_addr));
end architecture rtl;
