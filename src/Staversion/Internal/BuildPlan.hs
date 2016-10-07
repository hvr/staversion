-- |
-- Module: Staversion.Internal.BuildPlan
-- Description:  Handle build plan YAML files.
-- Maintainer: Toshio Ito <debug.ito@gmail.com>
--
-- __This is an internal module. End-users should not use it.__
module Staversion.Internal.BuildPlan
       ( BuildPlan,
         loadBuildPlanYAML,
         packageVersion
       ) where

import Control.Applicative (empty)
import Data.Aeson (FromJSON(..), (.:), Value(..), Object)
import qualified Data.HashMap.Strict as HM
import Data.Text (Text, unpack)
import Data.Version (Version)
import Text.Read (readMaybe)
  
-- | A data structure that keeps a map between package names and their
-- versions.
newtype BuildPlan = BuildPlan (HM.HashMap Text Version)

instance FromJSON BuildPlan where
  parseJSON (Object object) = toBuildPlan =<< (object .: "packages") where
    toBuildPlan (Object o) = BuildPlan <$> traverse parsePackageObject o
    toBuildPlan _ = empty
    parsePackageObject (Object o) = parseVersionText =<< (o .: "version")
    parsePackageObject _ = empty
    parseVersionText = maybe empty return . readMaybe  . unpack
  parseJSON _ = empty

-- | Load a 'BuildPlan' from a file.
loadBuildPlanYAML :: FilePath -> IO BuildPlan
loadBuildPlanYAML = undefined

packageVersion :: BuildPlan -> Text -> Maybe Version
packageVersion = undefined
