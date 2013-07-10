{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -funbox-strict-fields #-}
module Engine where
import qualified Data.Vector.Storable as S
import Graphics.Rendering.OpenGL.Raw
import Foreign

import Uniform
import Shader
import Model
import Util

clear :: IO ()
clear = glClear (gl_COLOR_BUFFER_BIT .|. gl_DEPTH_BUFFER_BIT)

--------------------------------------------------------------------------------
--  Models

loadModel :: FilePath
          -> IO GLmodel
loadModel model = do
    mesh <- loadMesh model
    meshToGL mesh

vertexAttribute, uvAttribute, normalAttribute :: GLuint
vertexAttribute = 0
uvAttribute     = 1
normalAttribute = 2

data GLmodel = GLmodel
    { vertArray :: !GLuint
    , normArray :: !GLuint
    , uvArray   :: !GLuint
    , ixArray   :: !GLuint
    , arrSize   :: !GLsizei
    }

meshToGL :: Mesh -> IO GLmodel
meshToGL (Mesh v n u f) = newGLmodel
    (S.map realToFrac v) (S.map realToFrac n) (S.map realToFrac u)
    f

-- | 'newGLmodel' vertices normals uvs indices vertexShader fragmentShader
newGLmodel :: S.Vector GLfloat 
           -> S.Vector GLfloat 
           -> S.Vector GLfloat 
           -> S.Vector GLushort 
           -> IO GLmodel
newGLmodel !vert !norm !uv !elems = do
    vertArray     <- staticArray vert
    normArray     <- staticArray norm
    uvArray       <- staticArray uv
    ixArray       <- staticElementArray elems
    return GLmodel{ arrSize = fromIntegral (S.length elems), .. }

{-# INLINE drawModel #-}
drawModel :: Uploadable s r => GLmodel -> Shaders s -> r
drawModel GLmodel{..} shaders = runShaders shaders $ do
    -- Vertice attribute buffer
    glEnableVertexAttribArray vertexAttribute
    glBindBuffer gl_ARRAY_BUFFER vertArray
    glVertexAttribPointer
        vertexAttribute 
        3 
        gl_FLOAT 
        0
        0 
        nullPtr
    -- UV attribute buffer
    glEnableVertexAttribArray uvAttribute
    glBindBuffer gl_ARRAY_BUFFER uvArray
    glVertexAttribPointer
        uvAttribute
        2
        gl_FLOAT
        0
        0
        nullPtr
    -- Normal attribute buffer
    glEnableVertexAttribArray normalAttribute
    glBindBuffer gl_ARRAY_BUFFER normArray
    glVertexAttribPointer
        normalAttribute
        3
        gl_FLOAT
        0
        0
        nullPtr
    -- Vertex indices
    glBindBuffer gl_ELEMENT_ARRAY_BUFFER ixArray
    glDrawElements gl_TRIANGLES arrSize gl_UNSIGNED_SHORT 0
    -- Clean up
    glDisableVertexAttribArray vertexAttribute
    glDisableVertexAttribArray uvAttribute
    glDisableVertexAttribArray normalAttribute
    glUseProgram 0


--------------------------------------------------------------------------------
--  Buffer creation

newBuffer :: Storable a => GLenum -> GLenum -> S.Vector a -> IO GLuint
newBuffer target hint (buf :: S.Vector a) = do
    gid <- alloca' (glGenBuffers 1)
    glBindBuffer target gid
    S.unsafeWith buf (\ptr -> glBufferData target size ptr hint)
    glBindBuffer target 0
    return gid
  where
    size = fromIntegral (sizeOf (undefined :: a) * S.length buf)

staticArray :: Storable a => S.Vector a -> IO GLuint
staticArray = newBuffer gl_ARRAY_BUFFER gl_STATIC_DRAW

staticElementArray :: Storable a => S.Vector a -> IO GLuint
staticElementArray = newBuffer gl_ELEMENT_ARRAY_BUFFER gl_STATIC_DRAW


