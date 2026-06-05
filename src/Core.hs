module Core where


import Clash.Explicit.Prelude

type RamUnit dom addr a =  Signal dom addr -> Signal dom (Maybe (addr, a)) -> Signal dom a
type RomUnit dom addr a = Signal dom addr -> Signal dom a
