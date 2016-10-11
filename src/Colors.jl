__precompile__()

module Colors

using FixedPointNumbers, ColorTypes, Reexport, Compat
@reexport using ColorTypes
# deprecated exports
export U8, U16

typealias AbstractGray{T} Color{T,1}
typealias Color3{T} Color{T,3}

import Base: ==, +, -, *, /
import Base: convert, eltype, hex, isless, linspace, show, typemin, typemax

# Additional exports, not exported by ColorTypes
export weighted_color_mean,
       hex, @colorant_str,
       protanopic, deuteranopic, tritanopic,
       distinguishable_colors, whitebalance,
       colordiff, DE_2000, DE_94, DE_JPC79, DE_CMC, DE_BFD, DE_AB, DE_DIN99, DE_DIN99d, DE_DIN99o,
       MSC, sequential_palette, diverging_palette, colormap,
       colormatch, CIE1931_CMF, CIE1964_CMF, CIE1931J_CMF, CIE1931JV_CMF

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

@deprecate rgba RGBA
@deprecate hsva HSVA
@deprecate hsla HSLA
@deprecate xyza XYZA
@deprecate xyYa xyYA
@deprecate laba LabA
@deprecate luva LuvA
@deprecate lchaba LCHabA
@deprecate lchuva LCHuvA
@deprecate din99a DIN99A
@deprecate din99da DIN99dA
@deprecate din99oa DIN99oA
@deprecate lmsa LMSA
@deprecate argb32 ARGB32

end # module
