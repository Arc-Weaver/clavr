-- tb_avr_soc.vhdl
-- GHDL behavioural testbench for the Clash-synthesised avr_soc top entity.
--
-- What is tested (mirrors Tests.Example.Project.prop_socGpioToggle):
--   1. DDR register is written to 0xFF by the reset handler.
--   2. PORT_A starts at 0x55 (set by reset handler).
--   3. PORT_A toggles to 0xAA when the periodic timer fires an interrupt
--      and the ISR runs.
--
-- Run via the Makefile in this directory:
--   make sim          -- compile + simulate (pass/fail on stdout)
--   make sim VCD=1    -- also write sim.vcd for waveform inspection
--
-- Or manually:
--   ghdl -a --std=08 --work=work \
--       ../vhdl/Example.Project.topEntity/avr_soc_types.vhdl \
--       ../vhdl/Example.Project.topEntity/avr_soc.vhdl \
--       tb_avr_soc.vhdl
--   ghdl -e --std=08 --work=work tb_avr_soc
--   ghdl -r --std=08 --work=work tb_avr_soc

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;
use work.avr_soc_types.all;

entity tb_avr_soc is
end entity tb_avr_soc;

architecture sim of tb_avr_soc is

    -- 10 MHz clock matches Dom10MHz
    constant CLK_PERIOD : time := 100 ns;

    signal clk       : std_logic := '0';
    -- Active-HIGH reset (Clash vSystem default).  Named rst_n in the port map
    -- to match the Synthesize annotation, but the polarity is active-high.
    signal rst_n     : std_logic := '1';
    signal en        : boolean   := true;
    signal gpio_a_in : unsigned(7 downto 0) := (others => '0');

    signal gpio_a_port : unsigned(7 downto 0);
    signal gpio_a_ddr  : unsigned(7 downto 0);

begin

    -- ── DUT ────────────────────────────────────────────────────────────────────
    dut : entity work.avr_soc
        port map (
            clk         => clk,
            rst_n       => rst_n,
            en          => en,
            gpio_a_in   => gpio_a_in,
            gpio_a_port => gpio_a_port,
            gpio_a_ddr  => gpio_a_ddr
        );

    -- ── Clock ──────────────────────────────────────────────────────────────────
    clk_gen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- ── Stimulus and checker ────────────────────────────────────────────────────
    stimulus : process
        variable seen_55 : boolean := false;
        variable seen_aa : boolean := false;
        variable ddr_ok  : boolean := false;
        variable cycle   : integer := 0;
    begin
        -- Assert reset for 2 clock cycles, then release.
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        rst_n <= '0';

        -- Sample outputs on each rising edge for 600 cycles.
        -- Expected timeline (approximate, all cycle counts post-reset):
        --   ~4  cycles: DDR written to 0xFF
        --   ~7  cycles: PORT written to 0x55 (reset handler done)
        --   ~32 cycles: first timer tick → interrupt accepted
        --   ~45 cycles: ISR completes → PORT written to 0xAA
        --   ~64 cycles: second timer tick → PORT back to 0x55
        for i in 0 to 599 loop
            wait until rising_edge(clk);
            cycle := cycle + 1;

            if gpio_a_ddr  = x"FF" then ddr_ok  := true; end if;
            if gpio_a_port = x"55" then seen_55 := true; end if;
            if gpio_a_port = x"AA" then seen_aa := true; end if;
        end loop;

        -- ── Assertions ──────────────────────────────────────────────────────────
        assert ddr_ok
            report "FAIL: DDR_A never became 0xFF within 600 cycles"
            severity failure;

        assert seen_55
            report "FAIL: PORT_A never showed 0x55 within 600 cycles"
            severity failure;

        assert seen_aa
            report "FAIL: PORT_A never showed 0xAA (timer interrupt never fired) within 600 cycles"
            severity failure;

        report "PASS: DDR=0xFF, PORT toggled 0x55<->0xAA via periodic timer interrupt"
            severity note;

        stop(0);
    end process;

end architecture sim;
