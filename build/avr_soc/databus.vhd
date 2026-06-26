library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity databus is
  port (
    wr_addr : in unsigned(31 downto 0);
    wr_data : in unsigned(7 downto 0);
    wr_en : in std_logic;
    rd_addr : in unsigned(31 downto 0);
    uart0_rd_data : in unsigned(7 downto 0);
    timer0_rd_data : in unsigned(7 downto 0);
    gpio0_rd_data : in unsigned(7 downto 0);
    ram0_rd_data : in unsigned(7 downto 0);
    uart0_req : out std_logic;
    uart0_we : out std_logic;
    uart0_addr : out unsigned(31 downto 0);
    uart0_wdata : out unsigned(7 downto 0);
    timer0_req : out std_logic;
    timer0_we : out std_logic;
    timer0_addr : out unsigned(31 downto 0);
    timer0_wdata : out unsigned(7 downto 0);
    gpio0_req : out std_logic;
    gpio0_we : out std_logic;
    gpio0_addr : out unsigned(31 downto 0);
    gpio0_wdata : out unsigned(7 downto 0);
    ram0_req : out std_logic;
    ram0_we : out std_logic;
    ram0_addr : out unsigned(31 downto 0);
    ram0_wdata : out unsigned(7 downto 0);
    rd_data : out unsigned(7 downto 0)
  );
end entity databus;


architecture rtl of databus is
  constant C_0_1 : std_logic := '0';
  constant C_0_8 : unsigned(7 downto 0) := to_unsigned(0, 8);
  constant C_1_1 : std_logic := '1';
  constant C_64_32 : unsigned(31 downto 0) := to_unsigned(64, 32);
  constant C_67_32 : unsigned(31 downto 0) := to_unsigned(67, 32);
  constant C_80_32 : unsigned(31 downto 0) := to_unsigned(80, 32);
  constant C_83_32 : unsigned(31 downto 0) := to_unsigned(83, 32);
  constant C_96_32 : unsigned(31 downto 0) := to_unsigned(96, 32);
  constant C_99_32 : unsigned(31 downto 0) := to_unsigned(99, 32);
  constant C_512_32 : unsigned(31 downto 0) := to_unsigned(512, 32);
  constant C_2560_32 : unsigned(31 downto 0) := to_unsigned(2560, 32);
  signal w9 : unsigned(31 downto 0);
  signal w33 : std_logic;
  signal w35 : std_logic;
  signal w36 : std_logic;
  signal cs_0x40 : std_logic;
  signal w38 : std_logic;
  signal w40 : std_logic;
  signal w42 : std_logic;
  signal w43 : std_logic;
  signal cs_0x50 : std_logic;
  signal w45 : std_logic;
  signal w47 : std_logic;
  signal w49 : std_logic;
  signal w50 : std_logic;
  signal cs_0x60 : std_logic;
  signal w52 : std_logic;
  signal w54 : std_logic;
  signal w56 : std_logic;
  signal w57 : std_logic;
  signal cs_0x200 : std_logic;
  signal w59 : std_logic;
  signal w61 : unsigned(7 downto 0);
  signal w62 : unsigned(7 downto 0);
  signal w63 : unsigned(7 downto 0);
  signal w64 : unsigned(7 downto 0);
begin
  w9 <= wr_addr when wr_en = '1' else rd_addr;

  -- SimpleBus interconnect: combinational decode, no stall
  w33 <= '1' when w9 < C_67_32 else '0';
  w35 <= '1' when w9 < C_64_32 else '0';
  w36 <= not w35;
  cs_0x40 <= w36 and w33;
  w38 <= C_1_1 and cs_0x40;
  w40 <= '1' when w9 < C_83_32 else '0';
  w42 <= '1' when w9 < C_80_32 else '0';
  w43 <= not w42;
  cs_0x50 <= w43 and w40;
  w45 <= C_1_1 and cs_0x50;
  w47 <= '1' when w9 < C_99_32 else '0';
  w49 <= '1' when w9 < C_96_32 else '0';
  w50 <= not w49;
  cs_0x60 <= w50 and w47;
  w52 <= C_1_1 and cs_0x60;
  w54 <= '1' when w9 < C_2560_32 else '0';
  w56 <= '1' when w9 < C_512_32 else '0';
  w57 <= not w56;
  cs_0x200 <= w57 and w54;
  w59 <= C_1_1 and cs_0x200;
  w61 <= uart0_rd_data when cs_0x40 = '1' else C_0_8;
  w62 <= timer0_rd_data when cs_0x50 = '1' else w61;
  w63 <= gpio0_rd_data when cs_0x60 = '1' else w62;
  w64 <= ram0_rd_data when cs_0x200 = '1' else w63;
  uart0_req <= w38;
  uart0_we <= wr_en;
  uart0_addr <= w9;
  uart0_wdata <= wr_data;
  timer0_req <= w45;
  timer0_we <= wr_en;
  timer0_addr <= w9;
  timer0_wdata <= wr_data;
  gpio0_req <= w52;
  gpio0_we <= wr_en;
  gpio0_addr <= w9;
  gpio0_wdata <= wr_data;
  ram0_req <= w59;
  ram0_we <= wr_en;
  ram0_addr <= w9;
  ram0_wdata <= wr_data;
  rd_data <= w64;
end architecture rtl;

