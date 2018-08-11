@testset "Colormaps" begin
    @test length(colormap("RdBu", 100)) == 100
end
