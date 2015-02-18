using Base.Test, Color

@test isleaftype(eltype(colormap("Grays")))

@test_throws ArgumentError colormap("Grays", N=10)
