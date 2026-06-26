library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer0 is
  port (
    dom10mhz : in std_logic;
    rst : in std_logic;
    req : in std_logic;
    we : in std_logic;
    addr : in unsigned(31 downto 0);
    wdata : in unsigned(7 downto 0);
    rd_data : out unsigned(7 downto 0);
    TimerPhys_timerOvfIrq : out std_logic;
    TimerPhys_timerCmpIrq : out std_logic
  );
end entity timer0;


architecture rtl of timer0 is
  constant C_0_1 : std_logic := '0';
  constant C_0_8 : unsigned(7 downto 0) := to_unsigned(0, 8);
  constant C_1_8 : unsigned(7 downto 0) := to_unsigned(1, 8);
  constant C_80_32 : unsigned(31 downto 0) := to_unsigned(80, 32);
  constant C_81_32 : unsigned(31 downto 0) := to_unsigned(81, 32);
  constant C_82_32 : unsigned(31 downto 0) := to_unsigned(82, 32);
  constant C_255_8 : unsigned(7 downto 0) := to_unsigned(255, 8);
  signal w5 : std_logic;
  signal w6 : std_logic;
  signal w7 : std_logic;
  signal ocr : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w9 : unsigned(7 downto 0);
  signal w11 : std_logic;
  signal w12 : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w14 : std_logic;
  signal w15 : std_logic;
  signal w16 : std_logic;
  signal tccr : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w18 : unsigned(7 downto 0);
  signal w20 : unsigned(7 downto 0);
  signal w21 : unsigned(7 downto 0);
  signal w22 : unsigned(7 downto 0);
  signal w24 : std_logic;
  signal w25 : std_logic;
  signal w27 : std_logic;
  signal w28 : std_logic;
  signal w29 : std_logic;
  signal w30 : std_logic;
  signal w31 : std_logic;
  signal w32 : std_logic;
  signal w33 : std_logic;
  signal w34 : std_logic;
  signal w35 : std_logic;
  signal w36 : std_logic;
  signal w37 : std_logic;
  signal tcnt : unsigned(7 downto 0) := to_unsigned(0, 8);
  signal w39 : unsigned(7 downto 0);
  signal w40 : std_logic;
  signal w42 : std_logic;
  signal w44 : unsigned(7 downto 0);
  signal w45 : unsigned(7 downto 0);
  signal w46 : unsigned(7 downto 0);
  signal w47 : unsigned(7 downto 0);
  signal w48 : unsigned(7 downto 0);
begin
  w5 <= '1' when addr = C_82_32 else '0';
  w6 <= we and w5;
  w7 <= req and w6;
  w9 <= wdata when w7 = '1' else ocr;
  w11 <= '1' when addr = C_81_32 else '0';
  w14 <= '1' when addr = C_80_32 else '0';
  w15 <= we and w14;
  w16 <= req and w15;
  w18 <= wdata when w16 = '1' else tccr;
  w20 <= w18 when w14 = '1' else C_0_8;
  w21 <= w12 when w11 = '1' else w20;
  w22 <= w9 when w5 = '1' else w21;
  rd_data <= w22;
  w24 <= w18(0);
  w25 <= not w24;
  w27 <= '1' when w12 = C_255_8 else '0';
  w28 <= we and w11;
  w29 <= req and w28;
  w30 <= not w29;
  w31 <= w27 and w30;
  w32 <= w25 and w31;
  w33 <= C_0_1 and w32;
  w34 <= '1' when w12 = w9 else '0';
  w35 <= w34 and w30;
  w36 <= w24 and w35;
  w37 <= C_0_1 and w36;
  TimerPhys_timerOvfIrq <= w33;
  TimerPhys_timerCmpIrq <= w37;
  w39 <= wdata when w29 = '1' else tcnt;
  w40 <= w24 and w34;
  w42 <= w25 and w27;
  w44 <= w12 + C_1_8;
  w45 <= C_0_8 when w42 = '1' else w44;
  w46 <= C_0_8 when w40 = '1' else w45;
  w47 <= w46 when C_0_1 = '1' else w12;
  w48 <= w39 when w29 = '1' else w47;
  process(dom10mhz, rst)
  begin
    if rst = '1' then
      tcnt <= to_unsigned(0, 8);
      tccr <= to_unsigned(0, 8);
      w12 <= to_unsigned(0, 8);
      ocr <= to_unsigned(0, 8);
    elsif rising_edge(dom10mhz) then
      if w29 = '1' then
        tcnt <= wdata;
      end if;
      if w16 = '1' then
        tccr <= wdata;
      end if;
      w12 <= w48;
      if w7 = '1' then
        ocr <= wdata;
      end if;
    end if;
  end process;
end architecture rtl;

