module Colors

using FixedPointNumbers
using Reexport
using Printf

@reexport using ColorTypes
Base.@deprecate_binding RGB1 XRGB
Base.@deprecate_binding RGB4 RGBX

# TODO: why these types are defined here? Can they move to ColorTypes.jl?
AbstractAGray{C<:AbstractGray,T} = AlphaColor{C,T,2}
AbstractGrayA{C<:AbstractGray,T} = ColorAlpha{C,T,2}

import Base: ==, +, -, *, /
import Base: convert, eltype, hex, isless, range, show, typemin, typemax

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
include("promotions.jl")
include("algorithms.jl")
include("parse.jl")
include("differences.jl")
include("colormaps.jl")
include("display.jl")
include("colormatch.jl")

if VERSION >= v"1.1"   # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end # module
