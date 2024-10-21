module Colors

using FixedPointNumbers
using Reexport

@reexport using ColorTypes
# remove deprecated bindings 
# see discussion https://github.com/JuliaIO/ImageMagick.jl/issues/235
# Base.@deprecate_binding RGB1 XRGB
# Base.@deprecate_binding RGB4 RGBX


import Base: ==, +, -, *, /
import Base: convert, eltype, isless, range, show, showable, typemin, typemax

# Additional exports, not exported by ColorTypes
export weighted_color_mean,
       hex, @colorant_str,
       protanopic, deuteranopic, tritanopic,
       distinguishable_colors, whitebalance,
       colordiff, DE_2000, DE_94, DE_JPC79, DE_CMC, DE_BFD, DE_AB, DE_DIN99, DE_DIN99d, DE_DIN99o,
       MSC, sequential_palette, diverging_palette, colormap,
       normalize_hue, mean_hue,
       colormatch, CIE1931_CMF, CIE1964_CMF, CIE1931J_CMF, CIE1931JV_CMF, CIE2006_2_CMF, CIE2006_10_CMF

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

"""
Colors used in the Julia logo as a `NamedTuple`.

The keys are approximate descriptions of the hue and do not include black.

Not exported, use as `JULIA_LOGO_COLORS.red` etc.
"""
const JULIA_LOGO_COLORS = (red = RGB{N0f8}(0.796, 0.235, 0.2),  # colorant"#cb3c33" blocks precompilation
                           green = RGB{N0f8}(0.22, 0.596, 0.149),
                           blue = RGB{N0f8}(0.251, 0.388, 0.847),
                           purple = RGB{N0f8}(0.584, 0.345, 0.698))

if VERSION >= v"1.1"   # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end # module
