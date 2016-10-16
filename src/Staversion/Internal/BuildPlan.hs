-- |
-- Module: Staversion.Internal.BuildPlan
-- Description:  Handle build plan YAML files.
-- Maintainer: Toshio Ito <debug.ito@gmail.com>
--
-- __This is an internal module. End-users should not use it.__
module Staversion.Internal.BuildPlan
       ( PackageName,
         BuildPlan,
         loadBuildPlanYAML,
         packageVersion,
         parseVersionText
       ) where

import Control.Applicative (empty, (<$>), (<*>))
import Control.Exception (throwIO)
import Data.Aeson (FromJSON(..), (.:), Value(..), Object)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.HashMap.Strict as HM
import Data.Maybe (listToMaybe)
import Data.Monoid ((<>))
import Data.Text (Text, unpack)
import Data.Traversable (Traversable(traverse))
import Data.Version (Version, parseVersion)
import qualified Data.Yaml as Yaml
import Text.Read (readMaybe)
import Text.ParserCombinators.ReadP (readP_to_S)

import Staversion.Internal.Query (PackageName)

-- | A data structure that keeps a map between package names and their
-- versions.
newtype BuildPlan = BuildPlan (HM.HashMap PackageName Version)

instance FromJSON BuildPlan where
  parseJSON (Object object) = (\p1 p2 -> BuildPlan $ p1 <> p2) <$> core_packages <*> other_packages where
    core_packages = parseSysInfo =<< (object .: "system-info")
    parseSysInfo (Object o) = parseCorePackages =<< (o .: "core-packages")
    parseSysInfo _ = empty
    parseCorePackages (Object o) = traverse (\v -> versionParser =<< parseJSON v) o
    parseCorePackages _ = empty

    other_packages = parsePackages =<< (object .: "packages")
    parsePackages (Object o) = traverse parsePackageObject o
    parsePackages _ = empty
    parsePackageObject (Object o) = versionParser =<< (o .: "version")
    parsePackageObject _ = empty
    versionParser = maybe empty return . parseVersionText
  parseJSON _ = empty


-- | Load a 'BuildPlan' from a file.
loadBuildPlanYAML :: FilePath -> IO BuildPlan
loadBuildPlanYAML yaml_file = (toException . Yaml.decodeEither') =<< BS.readFile yaml_file where -- TODO: make it memory-efficient!
  toException = either (throwIO) return

packageVersion :: BuildPlan -> PackageName -> Maybe Version
packageVersion (BuildPlan bp_map) name = HM.lookup name bp_map

-- | Parse a version text. There must not be any trailing characters
-- after a valid version text.
parseVersionText :: Text -> Maybe Version
parseVersionText = extractResult . (readP_to_S parseVersion) . unpack where
  extractResult = listToMaybe . map fst . filter (\pair -> snd pair == "")
