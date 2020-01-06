using FixedPointNumbers

@testset "Parse" begin
    r8(x) = reinterpret(N0f8, x)

    # Color parsing
    # named-color
    redN0f8 = parse(Colorant, "red")
    @test colorant"red" == redN0f8
    @test isa(redN0f8, RGB{N0f8})
    @test redN0f8 == RGB(1,0,0)
    @test parse(RGB{Float64}, "red") === RGB{Float64}(1,0,0)
    @test isa(parse(HSV, "blue"), HSV)
    @test_throws ErrorException parse(Colorant, "p ink")
    @test parse(Colorant, "transparent") === RGBA{N0f8}(0,0,0,0)
    @test parse(Colorant, "\nSeaGreen ") === RGB{N0f8}(r8(0x2E),r8(0x8B),r8(0x57))
    seagreen = @test_logs (:warn, r"Use \"SeaGreen\" or \"seagreen\"") parse(Colorant, "sea GREEN")
    @test seagreen == colorant"seagreen"

    # hex-color
    @test parse(Colorant, "#D0FF58") === RGB(r8(0xD0),r8(0xFF),r8(0x58))
    @test parse(Colorant, "0xd0ff58") === RGB(r8(0xD0),r8(0xFF),r8(0x58))
    @test parse(Colorant, "#FB0") === RGB(r8(0xFF),r8(0xBB),r8(0x00))
    @test parse(Colorant, "#FB0A") === RGBA(r8(0xFF),r8(0xBB),r8(0x00),r8(0xAA))
    @test parse(Colorant, "0xFB0A") === ARGB(r8(0xBB),r8(0x00),r8(0xAA),r8(0xFF))
    @test parse(Colorant, "#FFBB00AA") === RGBA(r8(0xFF),r8(0xBB),r8(0x00),r8(0xAA))
    @test parse(Colorant, "0xFFBB00AA") === ARGB(r8(0xBB),r8(0x00),r8(0xAA),r8(0xFF))
    @test_throws ErrorException parse(Colorant, "#BAD05")
    @test_throws ErrorException parse(Colorant, "#BAD0007")
    @test_throws ErrorException parse(Colorant, "#BAD000009")

    # rgb()
    @test parse(Colorant, "rgb(55,217,127)")      === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test colorant"    rgb(    55, 217, 127 )   " === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test parse(Colorant, "rgb(22%,85%,50%)")     === RGB{N0f8}(r8(0x38),r8(0xd9),r8(0x80))
    @test parse(Colorant, "rgba(55,217,127,0.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5)
    @test parse(Colorant, "rgb( 55,217,127,50%)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5) # CSS Color Module Level 4
    @test parse(Colorant, "rgb( 55 217 127 /.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5) # CSS Color Module Level 4
    @test parse(Colorant, "rgb(55, 85%, 50%)")    === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x80)) # this is invalid according to CSS spec.
    @test_throws ErrorException parse(Colorant, "rgb(21.6%,85%,50%)") # this is valid but not supported

    # hsl()
    @test parse(Colorant, "hsl(120, 100%, 50%)")  === HSL{Float32}(120,1.0,.5)
    @test colorant"    hsl(    120, 100%, 50% ) " === HSL{Float32}(120,1.0,.5)
    @test parse(RGB{N0f8},"hsl(120, 100%, 50%)")  === convert(RGB{N0f8}, HSL{Float32}(120,1.0,.5))
    @test_throws ErrorException  parse(Colorant, "hsl(120, 100, 50)")
    @test_throws ErrorException  parse(Colorant, "hsl(120%,100%,50%)")
    @test parse(Colorant, "hsla(120,50%,7%, .6)") === HSLA{Float32}(120,.5,.07,.6)
    @test parse(Colorant, "hsl( 120,50%,7%,60%)") === HSLA{Float32}(120,.5,.07,.6) # CSS Color Module Level 4
    @test parse(Colorant, "hsl( 120 50% 7% / 1)") === HSLA{Float32}(120,.5,.07, 1) # CSS Color Module Level 4

    @test parse(Colorant, :red) === colorant"red"
    @test parse(Colorant, colorant"red") === colorant"red"

end
