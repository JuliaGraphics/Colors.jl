@testset "Colormaps" begin
    @test length(colormap("RdBu", 100)) == 100

    # test ability to add to previously shown array of colors - issue #328
    a = [colorant"white", colorant"red"]
    show(stdout, MIME"image/svg+xml"(), a)
    push!(a, colorant"blue")
    @test length(a) == 3
end
