module Color

import Base: convert, hex, isless, writemime, linspace
import Base.Graphics: set_source, set_source_rgb, GraphicsContext

export ColorValue, color,
       ColourValue, colour,
       AlphaColorValue,
       weighted_color_mean, hex,
       RGB, HSV, HSL, XYZ, LAB, LUV, LCHab, LCHuv, DIN99, DIN99d, DIN99o, LMS, RGB24,
       RGBA, HSVA, HSLA, XYZA, LABA, LUVA, LCHabA, LCHuvA, DIN99A, DIN99dA, DIN99oA, LMSA, RGBA32,
       protanopic, deuteranopic, tritanopic,
       cie_color_match, distinguishable_colors,
       colordiff, colordiff_din99, colordiff_din99d, colordiff_din99o,
       MSC, sequential_palette, diverging_palette, colormap

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

end # module
