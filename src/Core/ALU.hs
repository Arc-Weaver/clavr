module Core.ALU where
import Data.Maybe

--class ALU (instr,state,ramaddr,romaddr,val) where 
--    read :: instr -> state -> Maybe ramaddr
--    compute :: instr -> Maybe val -> state -> state
--    write :: instr -> state -> Maybe (ramaddr, val) 
--    jump :: instr -> state -> Maybe romaddr 

data ALU instr state ramaddr romaddr val = ALU {
    read :: instr -> state -> Maybe ramaddr
    ,compute :: instr -> Maybe val -> state -> state
    ,write :: instr -> state -> Maybe (ramaddr, val) 
    ,jump :: instr -> state -> Maybe romaddr
}