{-# LANGUAGE BangPatterns
           , DataKinds
           , DeriveAnyClass
           , DeriveGeneric
           , DerivingVia
           , FlexibleContexts
           , NoMonomorphismRestriction
           , OverloadedLabels
           , OverloadedStrings
           , RecordWildCards
           , TypeApplications
           , TypeFamilies
           , TypeOperators
           #-}

module Main where

import Control.Concurrent

import Control.Exception

import Control.Monad

import Data.Foldable

import Data.Int

import qualified Data.Text as T

import Network.GRPC.Common
import Network.GRPC.Common.Protobuf

import Network.GRPC.Client
import Network.GRPC.Client.StreamType.IO
-- import Network.GRPC.Client.Protobuf
-- import Network.GRPC.Client.Run

import qualified Proto.Gr as P

type instance RequestMetadata (Protobuf P.GR m) = NoMetadata
type instance ResponseInitialMetadata (Protobuf P.GR m) = NoMetadata
type instance ResponseTrailingMetadata (Protobuf P.GR m) = NoMetadata

m :: Proto P.M
m = Proto (defMessage & #x .~ "jeb")

disconnected :: Connection -> IO ()
disconnected conn = do
    c <- getLine
    case c of
        "q" -> pure ()
        "d" -> putStrLn "Stream already disconnected." *> disconnected conn
        "r" -> putStrLn "Can't recv, stream disconnected." *> disconnected conn
        "c" -> do putStrLn "Connecting stream..."
                  serverStreaming conn (rpc @(Protobuf P.GR "serverStream")) m $
                    \recv -> connected recv
                  disconnected conn
        _   -> putStrLn "No." *> disconnected conn

connected :: Show a => IO a -> IO ()
connected recv = do
    c <- getLine
    case c of
        "d" -> putStrLn "Disconnecting stream..."
        "c" -> putStrLn "Stream already connected." *> connected recv
        "r" -> (recv >>= print) *> connected recv
        _   -> putStrLn "No." *> connected recv


main :: IO ()
main = do
    putStrLn "q : Quit (while stream is disconnected), c : Connect stream, d : Disconnect stream, r : Recv"
    let s = ServerInsecure $ Address "127.0.0.1" (fromIntegral 64321) Nothing
    withConnection def s $ \conn -> disconnected conn
