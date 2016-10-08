-- |
-- Module: Staversion.Internal.Exec
-- Description: executable
-- Maintainer: Toshio Ito <debug.ito@gmail.com>
--
-- __This is an internal module. End-users should not use it.__
module Staversion.Internal.Exec
       ( main,
         processCommand
       ) where

import Control.Applicative ((<$>))
import Control.Exception (catch)
import Data.Function (on)
import Data.List (groupBy)
import Data.Text (unpack)
import System.FilePath ((</>), (<.>))
import System.IO.Error (IOError)

import Staversion.Internal.BuildPlan
  ( BuildPlan, loadBuildPlanYAML, packageVersion
  )
import Staversion.Internal.Command
  ( parseCommandArgs,
    Command(..)
  )
import Staversion.Internal.Query
  ( Query(..), Result(..), PackageSource(..), resultVersionsFromList,
    ErrorMsg
  )

main :: IO ()
main = do
  comm <- parseCommandArgs
  (putStrLn . show) =<< (processCommand comm)

processCommand :: Command -> IO [Result]
processCommand comm = fmap concat $ mapM processQueriesIn $ commSources comm where
  processQueriesIn source = do
    e_build_plan <- loadBuildPlan comm source
    return $ map (makeResult source e_build_plan) $ commQueries comm
  makeResult source e_build_plan query = case e_build_plan of
    Left error_msg -> Result { resultIn = source, resultFor = query, resultVersions = Left error_msg }
    Right build_plan -> searchVersion source build_plan query

loadBuildPlan ::  Command -> PackageSource -> IO (Either ErrorMsg BuildPlan)
loadBuildPlan comm source@(SourceStackage resolver) = (Right <$> loadBuildPlanYAML yaml_file) `catch` handleIOError where
  yaml_file = commBuildPlanDir comm </> resolver <.> "yaml"
  handleIOError :: IOError -> IO (Either ErrorMsg BuildPlan)
  handleIOError e = return $ Left ("Loading build plan for package source " ++ show source ++ " failed: " ++ show e)

searchVersion :: PackageSource -> BuildPlan -> Query -> Result
searchVersion source build_plan query@(QueryName package_name) =
  Result { resultIn = source,
           resultFor = query,
           resultVersions = Right $ resultVersionsFromList [(package_name, packageVersion build_plan package_name)]
         }
