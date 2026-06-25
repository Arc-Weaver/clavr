-- tb_avr_soc.vhdl
-- GHDL behavioural testbench for the isacle-hdl synthesised avr_soc entity.
--
-- The program (example/Example/program.S) is baked into the ROM at synth time.
-- It runs the following sequence from power-on reset:
--
--   PC=0  rjmp reset          ; jump past the IRQ vector table
--   ...
--   reset:
--     ldi  r16, 0xFF
--     sts  0x0061, r16        ; GPIO_A DDR  = 0xFF  (all outputs)
--     ldi  r16, 0x55
--     sts  0x0062, r16        ; GPIO_A PORT = 0x55  (initial drive value)
--     sei
--   loop: rjmp loop           ; spin
--
-- Expected observations:
--   gpio_ddr  = 0xFF  within 50 cycles
--   gpio_port = 0x55  within 50 cycles
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
    signal gpio_port : unsigned(7 downto 0);
    signal gpio_ddr  : unsigned(7 downto 0);

begin

    dut : entity work.avr_soc
        port map (
            dom10mhz  => clk,
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
        -- Run for up to 200 cycles sampling on every rising edge.
        for i in 0 to 199 loop
            wait until rising_edge(clk);
            if gpio_ddr  = x"FF" then ddr_ok  := true; end if;
            if gpio_port = x"55" then port_ok := true; end if;
            exit when ddr_ok and port_ok;
        end loop;

        assert ddr_ok
            report "FAIL: gpio_ddr never became 0xFF within 200 cycles"
            severity failure;

        assert port_ok
            report "FAIL: gpio_port never became 0x55 within 200 cycles"
            severity failure;

        report "PASS: gpio_ddr=0xFF, gpio_port=0x55 -- program init confirmed"
            severity note;

        stop(0);
    end process;

end architecture sim;
