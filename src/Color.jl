module Color

import Base: convert, hex, isless, writemime, linspace
import Base.Graphics: set_source, set_source_rgb, GraphicsContext

export ColorValue, color,
       ColourValue, colour,
       AlphaColorValue,
       weighted_color_mean, hex,
       RGB, HSV, HSL, XYZ, xyY, Lab, LAB, Luv, LUV, LCHab, LCHuv, DIN99, DIN99d, DIN99o, LMS, RGB24,
       RGBA, HSVA, HSLA, XYZA, xyYA, LabA, LuvA, LCHabA, LCHuvA, DIN99A, DIN99dA, DIN99oA, LMSA, RGBA32,
       protanopic, deuteranopic, tritanopic,
       distinguishable_colors,
       colordiff, DE_2000, DE_94, DE_JPC79, DE_CMC, DE_BFD, DE_AB, DE_DIN99, DE_DIN99d, DE_DIN99o,
       MSC, sequential_palette, diverging_palette, colormap,
       colormatch, CIE1931_CMF, CIE1964_CMF, CIE1931J_CMF, CIE1931JV_CMF

# Delete once 0.2 is no longer supported:
if !isdefined(:rad2deg)
  const rad2deg = radians2degrees
  const deg2rad = degrees2radians
end

# The core; every other include will need these type definitions
include("colorspaces.jl")

# Early utilities
include("utilities.jl")

# Include other module components
include("conversions.jl")
include("algorithms.jl")
include("parse.jl")
include("differences.jl")
include("colormaps.jl")
include("display.jl")
include("colormatch.jl")

end # module
