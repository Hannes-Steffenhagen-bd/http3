-- |
-- Supposed to be an implementation of QUIC - or at least the bits that are
-- necessary for HTTP3 (which I'm pretty sure is most of it).
--
-- Not production ready, not expected to become production ready at any point.
-- Proceed at your own peril.
module Network.QUIC where

import Data.Bits
import Data.Text (Text)
import Data.Word (Word64)
import qualified Network.Socket as N

data StreamInitiator = ClientInitiated | ServerInitiated
  deriving (Eq, Show)

data StreamDirection = Unidirectional | Bidirectional
  deriving (Eq, Show)

newtype Word62 = Word62 {w62ToW64 :: Word64}
  deriving (Eq, Show)
  deriving newtype (Num)

newtype StreamId = StreamId {streamIdToWord :: Word62}

-- | Which version of the QUIC protocol we support
-- Right now there's only 1, which we try to support here.
protocolVersion :: Word64
protocolVersion = 1

-- | Who started the stream (determined by LSB)
-- Examples:
--
-- >>> streamInitiator (StreamId 0b0101) == ServerInitiated
-- True
-- >>> streamInitiator (StreamId 0b0100) == ClientInitiated
-- True
streamInitiator :: StreamId -> StreamInitiator
streamInitiator id
  | serverInitiated = ServerInitiated
  | otherwise = ClientInitiated
  where
    serverInitiated = w62ToW64 (streamIdToWord id) .&. 0b01 == 0b01

-- | Uni or bidirectional? (determined by 2nd LSB)
-- Examples:
--
-- >>> streamDirection (StreamId 0b1010) == Unidirectional
-- True
-- >>> streamDirection (StreamId 0b1000) == Bidirectional
-- True
streamDirection :: StreamId -> StreamDirection
streamDirection id
  | unidirectional = Unidirectional
  | otherwise = Bidirectional
  where
    unidirectional = w62ToW64 (streamIdToWord id) .&. 0b10 == 0b10
