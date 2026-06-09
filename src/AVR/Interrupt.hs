module AVR.Interrupt
    ( interruptArbiter
    ) where

import Clash.Prelude
import AVR.Core (AVRAddr)
import qualified Core.Periph.Interrupt as I

-- | AVR-specific alias: priority interrupt arbiter over word addresses.
--   Re-exports the generic arbiter with @AVRAddr@ fixed as the vector type.
interruptArbiter
    :: KnownNat n
    => Vec n (Signal dom Bool, AVRAddr)
    -> Signal dom Bool
    -> Signal dom (Maybe AVRAddr)
interruptArbiter = I.interruptArbiter
