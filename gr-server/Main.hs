{-# LANGUAGE BangPatterns
           -- , DataKinds
           , DeriveAnyClass
           , DeriveGeneric
           , DerivingVia
           , FlexibleContexts
           , NoMonomorphismRestriction
           , OverloadedLabels
           , OverloadedStrings
           , RecordWildCards
           , TypeFamilies
           , TypeOperators
           #-}

module Main where

import Control.Concurrent

import Control.Exception

import Control.Monad

import Data.Foldable

import Network.GRPC.Common
import Network.GRPC.Common.Protobuf

import Network.GRPC.Server
import Network.GRPC.Server.Protobuf
import Network.GRPC.Server.Run
import Network.GRPC.Server.StreamType

import qualified Proto.Gr as P

import System.Environment

import qualified System.Remote.Counter    as EC
import qualified System.Remote.Gauge      as EG
import qualified System.Remote.Monitoring as E

type instance RequestMetadata (Protobuf P.GR m) = NoMetadata
type instance ResponseInitialMetadata (Protobuf P.GR m) = NoMetadata
type instance ResponseTrailingMetadata (Protobuf P.GR m) = NoMetadata

data E = E {
    eStreamers :: EG.Gauge
  , eSent :: EC.Counter
  }

mkE :: IO E
mkE = do
    s <- E.forkServer "0.0.0.0" 61337
    eStreamers <- E.getGauge "streamers" s
    eSent <- E.getCounter "sent" s
    pure E{..}

_ss1 :: E -> Proto P.M -> (NextElem (Proto P.M) -> IO ()) -> IO ()
_ss1 E{..} m f =
    let hnd = forever $ do
                f $ NextElem m
                EC.inc eSent
                threadDelay 100000
    in bracket_ (EG.inc eStreamers)
                (EG.dec eStreamers)
                hnd

_ss2 :: E -> Proto P.M -> (NextElem (Proto P.M) -> IO ()) -> IO ()
_ss2 E{..} m f =
    let hnd = do
                f $ NextElem m
                EC.inc eSent
                putStrLn "Disconnect client now..."
                threadDelay (10 * 1000000)
                f $ NoNextElem
    in bracket_ (EG.inc eStreamers)
                (EG.dec eStreamers)
                hnd

methods1 :: E -> Methods IO (ProtobufMethodsOf P.GR)
methods1 e = Method (mkServerStreaming (_ss1 e)) NoMoreMethods

methods2 :: E -> Methods IO (ProtobufMethodsOf P.GR)
methods2 e = Method (mkServerStreaming (_ss2 e)) NoMoreMethods

runArgs :: [String] -> IO ()
runArgs as =
    let config = ServerConfig {
             serverInsecure = Just $
               InsecureConfig (Just "0.0.0.0") 64321
           , serverSecure = Nothing
           }
        mm = case as of
                ["t1"] -> Just methods1
                ["t2"] -> Just methods2
                _    -> Nothing
        go m = do
            e <- mkE
            s <- mkGrpcServer def $ fromMethods $ m e
            runServer def config s
    in traverse_ go mm

main :: IO ()
main = getArgs >>= runArgs
