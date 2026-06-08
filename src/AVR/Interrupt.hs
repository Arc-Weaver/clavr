module AVR.Interrupt
    ( interruptArbiter
    ) where

import Clash.Prelude
import AVR.Core (AVRAddr)

-- | Combinational priority interrupt arbiter.
--
--   Sources are in priority order: index 0 = highest priority.  When multiple
--   sources are active simultaneously the lowest-index request wins.
--
--   The output is gated by the caller-supplied @iEnabled@ signal (SREG.I).
--   If @iEnabled@ is False the output is always Nothing regardless of requests,
--   matching the AVR global interrupt enable semantics.
--
--   Usage — wire one request line per peripheral:
--
--     interruptArbiter
--         (    (timerOvfReq,  0x0020)  -- TIMER0_OVF at word address 0x0020
--          :> (uartRxReq,    0x0024)  -- USART_RX  at word address 0x0024
--          :> Nil )
--         iEnabled
interruptArbiter
    :: KnownNat n
    => Vec n (Signal dom Bool, AVRAddr)   -- (request line, vector word address)
    -> Signal dom Bool                    -- SREG.I (global interrupt enable)
    -> Signal dom (Maybe AVRAddr)
interruptArbiter sources iEnabled = liftA2 gate iEnabled winner
  where
    -- Convert each (request, vector) pair to Signal (Maybe AVRAddr).
    -- foldr over the Vec: leftmost Just wins (lowest index = highest priority).
    candidates = map toCandidate sources
    winner     = foldr (liftA2 firstJust) (pure Nothing) candidates

    toCandidate (req, vec) = fmap (\r -> if r then Just vec else Nothing) req

    firstJust (Just a) _ = Just a
    firstJust Nothing  b = b

    gate True  w = w
    gate False _ = Nothing
