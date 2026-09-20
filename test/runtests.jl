using Colors, Test
using Aqua

@testset "Aqua tests" begin
    Aqua.test_all(Colors, piracies=false)

    colorantnames = filter(names(ColorTypes, all=false)) do s
                        isdefined(ColorTypes, s) || return false
                        t = getfield(ColorTypes, s)
                        return isa(t, Type) && t <: Colorant
                    end
    coloranttypes = map(s -> getfield(ColorTypes,s), colorantnames)
    Aqua.test_piracies(Colors, treat_as_own=coloranttypes)
end

include("algorithms.jl")
include("conversion.jl")
include("colormaps.jl")
include("colormatch.jl")
include("colordiff.jl")
include("din99.jl")
include("display.jl")
include("parse.jl")
include("utilities.jl")

# cf. https://github.com/JuliaGraphics/Colors.jl/pull/513
using AbstractTrees
@test isempty(detect_ambiguities(Colors))
