using Colors, Test
@test isempty(detect_ambiguities(Colors, Base, Core))

include("algorithms.jl")
include("conversion.jl")
include("colormaps.jl")
include("colordiff.jl")
include("din99.jl")
include("utilities.jl")
