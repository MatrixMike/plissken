module Paths where
import System.Directory (getDirectoryContents, createDirectoryIfMissing)
import Control.Monad (void)
import System.FilePath

gdata, game :: FilePath
gdata    = "data"
game     = "game"

model, shader, sound, save, config, fonts :: FilePath -> FilePath
model  x = gdata </> "models" </> x
shader x = gdata </> "shaders" </> x
fonts  x = gdata </> "fonts" </> x
sound  x = gdata </> "sound" </> x
save   x = game </> "saves" </> x
config x = game </> x

list :: FilePath -> IO [FilePath]
list = fmap removeDots . getDirectoryContents
  where
    removeDots = filter (\x -> x == "." || x == "..")

mkdir :: FilePath -> IO ()
mkdir = void . createDirectoryIfMissing True

