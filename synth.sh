#!/usr/bin/env bash
set -euo pipefail

FORMAT=${1:-vhdl}   # vhdl | verilog | systemverilog

stack build clavr:exe:clash
exec stack exec clash -- Example.Project "--$FORMAT"
