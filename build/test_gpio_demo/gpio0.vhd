library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio0 is
  port (
    dom10mhz : in std_logic;
    rst : in std_logic;
    wr_addr : in unsigned(31 downto 0);
    wr_data : in unsigned(7 downto 0);
    wr_en : in std_logic;
    rd_addr : in unsigned(31 downto 0);
    rd_data : out unsigned(7 downto 0);
    GpioPhys_gpioPort : out unsigned(7 downto 0);
    GpioPhys_gpioDdr : out unsigned(7 downto 0)
  );
end entity gpio0;


architecture rtl of gpio0 is
  constant C_0_8 : unsigned(7 downto 0) := to_unsigned(0, 8);
  constant C_96_32 : unsigned(31 downto 0) := to_unsigned(96, 32);
  constant C_97_32 : unsigned(31 downto 0) := to_unsigned(97, 32);
  constant C_98_32 : unsigned(31 downto 0) := to_unsigned(98, 32);
  signal w5 : std_logic;
  signal w6 : std_logic;
  signal w7 : std_logic;
  signal port_s : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w9 : unsigned(7 downto 0);
  signal w11 : std_logic;
  signal w12 : std_logic;
  signal w13 : std_logic;
  signal ddr : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w15 : unsigned(7 downto 0);
  signal w17 : std_logic;
  signal w20 : unsigned(7 downto 0);
  signal w21 : unsigned(7 downto 0);
  signal w22 : unsigned(7 downto 0);
begin
  w5 <= '1' when rd_addr = C_98_32 else '0';
  w6 <= '1' when wr_addr = C_98_32 else '0';
  w7 <= wr_en and w6;
  w9 <= wr_data when w7 = '1' else port_s;
  w11 <= '1' when rd_addr = C_97_32 else '0';
  w12 <= '1' when wr_addr = C_97_32 else '0';
  w13 <= wr_en and w12;
  w15 <= wr_data when w13 = '1' else ddr;
  w17 <= '1' when rd_addr = C_96_32 else '0';
  w20 <= C_0_8 when w17 = '1' else C_0_8;
  w21 <= w15 when w11 = '1' else w20;
  w22 <= w9 when w5 = '1' else w21;
  rd_data <= w22;
  GpioPhys_gpioPort <= w9;
  GpioPhys_gpioDdr <= w15;
  process(dom10mhz, rst)
  begin
    if rst = '1' then
      ddr <= to_unsigned(0, 8);
      port_s <= to_unsigned(0, 8);
    elsif rising_edge(dom10mhz) then
      if w13 = '1' then
        ddr <= wr_data;
      end if;
      if w7 = '1' then
        port_s <= wr_data;
      end if;
    end if;
  end process;
end architecture rtl;

