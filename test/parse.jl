using FixedPointNumbers

@testset "Parse" begin
    r8(x) = reinterpret(N0f8, x)

    # Color parsing
    redN0f8 = parse(Colorant, "red")
    @test colorant"red" == redN0f8
    @test isa(redN0f8, RGB{N0f8})
    @test redN0f8 == RGB(1,0,0)
    @test parse(RGB{Float64}, "red") === RGB{Float64}(1,0,0)
    @test isa(parse(HSV, "blue"), HSV)
    @test parse(Colorant, "rgb(55,217,127)") === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test colorant"rgb(55,217,127)" === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test parse(Colorant, "rgba(55,217,127,0.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5)
    @test parse(Colorant, "rgb(55,217,127)") === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test parse(Colorant, "rgba(55,217,127,0.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5)
    @test parse(Colorant, "hsl(120, 100%, 50%)") === HSL{Float32}(120,1.0,.5)
    @test colorant"hsl(120, 100%, 50%)" === HSL{Float32}(120,1.0,.5)
    @test parse(RGB{N0f8}, "hsl(120, 100%, 50%)") === convert(RGB{N0f8}, HSL{Float32}(120,1.0,.5))
    @test_throws ErrorException  parse(Colorant, "hsl(120, 100, 50)")
    @test parse(Colorant, "#D0FF58") === RGB(r8(0xD0),r8(0xFF),r8(0x58))
    @test parse(Colorant, "#FB0") === RGB(r8(0xFF),r8(0xBB),r8(0x00))

    @test parse(Colorant, :red) === colorant"red"
    @test parse(Colorant, colorant"red") === colorant"red"

end
