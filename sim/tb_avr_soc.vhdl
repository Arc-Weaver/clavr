-- tb_avr_soc.vhdl
-- GHDL behavioural testbench for the isacle-hdl synthesised avr_soc entity.
--
-- The program (example/Example/program.S) is baked into the ROM at synth time.
-- It exercises the memory-mapped-register *read* path (SREG aliased at 0x5F):
--
--   PC=0  rjmp reset          ; jump past the IRQ vector table
--   ...
--   reset:
--     ldi  r16, 0xFF
--     sts  0x0061, r16        ; GPIO_A DDR  = 0xFF  (all outputs)
--     sec                     ; SREG.C = 1 → SREG register = 0x01, SRAM[0x5F] = 0x00
--     lds  r17, 0x005F        ; r17 = SREG  (alias READ of the status register)
--     sts  0x0062, r17        ; GPIO_A PORT = r17 = 0x01
--   loop: rjmp loop           ; spin
--
-- The 0x01 on PORT can only come from reading the *live* SREG register; a broken
-- alias read would return raw SRAM[0x5F] = 0x00.
--
-- Expected observations:
--   gpio_ddr  = 0xFF
--   gpio_port = 0x01
--
-- Run via the Makefile in this directory:
--   make sim          -- compile + simulate (pass/fail on stdout)
--   make sim VCD=1    -- also write work/sim.vcd for waveform inspection

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_avr_soc is
end entity tb_avr_soc;

architecture sim of tb_avr_soc is

    constant CLK_PERIOD : time := 100 ns;   -- 10 MHz

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';   -- active-high; released after a few cycles
    signal gpio_port : unsigned(7 downto 0);
    signal gpio_ddr  : unsigned(7 downto 0);

begin

    dut : entity work.avr_soc
        port map (
            dom10mhz  => clk,
            rst       => rst,
            gpio_port => gpio_port,
            gpio_ddr  => gpio_ddr
        );

    clk_gen : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stimulus : process
        variable ddr_ok  : boolean := false;
        variable port_ok : boolean := false;
    begin
        -- Hold reset for a few cycles, then release and let the program run.
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';

        -- Run for up to 200 cycles sampling on every rising edge.
        for i in 0 to 199 loop
            wait until rising_edge(clk);
            if gpio_ddr  = x"FF" then ddr_ok  := true; end if;
            if gpio_port = x"01" then port_ok := true; end if;
            exit when ddr_ok and port_ok;
        end loop;

        assert ddr_ok
            report "FAIL: gpio_ddr never became 0xFF within 200 cycles"
            severity failure;

        assert port_ok
            report "FAIL: gpio_port never became 0x01 (alias read of SREG failed) within 200 cycles"
            severity failure;

        report "PASS: gpio_ddr=0xFF, gpio_port=0x01 -- alias read of SREG confirmed"
            severity note;

        stop(0);
    end process;

end architecture sim;
