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

import Data.Int

import qualified Data.Text as T

import Network.GRPC.Common
import Network.GRPC.Common.Protobuf

import Network.GRPC.Server
import Network.GRPC.Server.Protobuf
import Network.GRPC.Server.Run
import Network.GRPC.Server.StreamType

import qualified Proto.Gr as P
import qualified Proto.Gr as P

main :: IO ()
main = undefined
