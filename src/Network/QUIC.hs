-- |
-- Supposed to be an implementation of QUIC - or at least the bits that are
-- necessary for HTTP3 (which I'm pretty sure is most of it).
--
-- Not production ready, not expected to become production ready at any point.
-- Proceed at your own peril.
module Network.QUIC where

import Control.Monad (forever)
import Data.Bits
import qualified Data.ByteString as B
import Data.Text (Text)
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as T
import Data.Word (Word64)
import qualified Network.Socket as N
import qualified Network.Socket.ByteString as N

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

server :: Int -> IO ()
server port = do
  sock <- N.socket N.AF_INET6 N.Datagram N.defaultProtocol
  addr : _ <- N.getAddrInfo (Just N.defaultHints {N.addrFamily = N.AF_INET6, N.addrSocketType = N.Datagram}) (Just "::1") (Just $ show port)
  N.bind sock (N.addrAddress addr)
  forever $ do
    result <- N.recvFrom sock 4096
    print result

client :: Int -> IO ()
client port = do
  sock <- N.socket N.AF_INET6 N.Datagram N.defaultProtocol
  addr : _ <- N.getAddrInfo (Just N.defaultHints {N.addrFamily = N.AF_INET6, N.addrSocketType = N.Datagram}) (Just "::1") Nothing
  sendAddr : _ <- N.getAddrInfo (Just N.defaultHints {N.addrFamily = N.AF_INET6, N.addrSocketType = N.Datagram}) (Just "::1") (Just $ show port)
  N.bind sock (N.addrAddress addr)
  forever $ do
    t <- T.getLine
    let dat = T.encodeUtf8 t
    N.sendTo sock dat (N.addrAddress sendAddr)
