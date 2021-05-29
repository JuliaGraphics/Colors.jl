using Test, Colors
using FixedPointNumbers

@testset "Parse" begin
    r8(x) = reinterpret(N0f8, x)

    # Color parsing
    # named-color
    redN0f8 = parse(Colorant, "red")
    @test colorant"red" === redN0f8
    @test redN0f8 === RGB{N0f8}(1,0,0)
    @test parse(RGB{Float64}, "red") === RGB{Float64}(1,0,0)
    @test isa(parse(HSV, "blue"), HSV)
    @test_throws ArgumentError parse(Colorant, "p ink")
    @test parse(Colorant, "transparent") === RGBA{N0f8}(0,0,0,0)
    @test parse(Colorant, "\nSeaGreen ") === RGB{N0f8}(r8(0x2E),r8(0x8B),r8(0x57))
    @test parse(Colorant, "sea GREEN") === colorant"seagreen"

    # hex-color
    @test parse(Colorant, "#D0FF58") === RGB(r8(0xD0),r8(0xFF),r8(0x58))
    @test parse(Colorant, "0xd0ff58") === RGB(r8(0xD0),r8(0xFF),r8(0x58))
    @test parse(Colorant, "#FB0") === RGB(r8(0xFF),r8(0xBB),r8(0x00))
    @test parse(Colorant, "#FB0A") === RGBA(r8(0xFF),r8(0xBB),r8(0x00),r8(0xAA))
    @test parse(Colorant, "0xFB0A") === ARGB(r8(0xBB),r8(0x00),r8(0xAA),r8(0xFF))
    @test parse(Colorant, "#FFBB00AA") === RGBA(r8(0xFF),r8(0xBB),r8(0x00),r8(0xAA))
    @test parse(Colorant, "0xFFBB00AA") === ARGB(r8(0xBB),r8(0x00),r8(0xAA),r8(0xFF))
    @test_throws ArgumentError parse(Colorant, "#BAD05")
    @test_throws ArgumentError parse(Colorant, "#BAD0007")
    @test_throws ArgumentError parse(Colorant, "#BAD000009")

    # rgb()
    @test parse(Colorant, "rgb(55,217,127)")      === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test colorant"    Rgb(  55.1, 217, 127 )   " === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x7f))
    @test parse(Colorant, "rgb(22%,85%,50%)")     === RGB{N0f8}(r8(0x38),r8(0xd9),r8(0x80))
    @test parse(Colorant, "rgba(55,217,127,0.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5)
    @test parse(Colorant, "rgb( 55,217,127,50%)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5) # CSS Color Module Level 4
    @test parse(Colorant, "rgb( 55 217 127 /.5)") === RGBA{N0f8}(r8(0x37),r8(0xd9),r8(0x7f),0.5) # CSS Color Module Level 4
    @test_throws ArgumentError parse(Colorant, "rgb(55, 85%, 50%)") # this is invalid according to CSS spec.
    @test parse(Colorant, "rgb(21.6%,85%,50%)") === RGB{N0f8}(r8(0x37),r8(0xd9),r8(0x80))

    # hsl()
    @test parse(Colorant, "hsl(120, 100%, 50%)")  === HSL{Float32}(120,1.0,.5)
    @test colorant"    Hsl(    120, 100%, 50% ) " === HSL{Float32}(120,1.0,.5)
    @test parse(RGB{N0f8},"hsl(120, 100%, 50%)")  === convert(RGB{N0f8}, HSL{Float32}(120,1.0,.5))
    @test_throws ArgumentError parse(Colorant, "hsl(120, 100, 50)")
    @test_throws ArgumentError parse(Colorant, "hsl(120%,100%,50%)")
    @test parse(Colorant, "hsla(120,50%,7%, .6)") === HSLA{Float32}(120,.5,.07,.6)
    @test parse(Colorant, "hsl( 120,50%,7%,60%)") === HSLA{Float32}(120,.5,.07,.6) # CSS Color Module Level 4
    @test parse(Colorant, "hsl( 120 50% 7% / 1)") === HSLA{Float32}(120,.5,.07, 1) # CSS Color Module Level 4
    @test parse(Colorant, "hsl(         90.0, 100%,   0%)") === HSL{Float32}(90, 1, 0)
    @test parse(Colorant, "hsl(        90Deg, 100%,   0%)") === HSL{Float32}(90, 1, 0)
    @test parse(Colorant, "hsl(     0.25turn, 120%, 0.0%)") === HSL{Float32}(90, 1, 0)
    @test parse(Colorant, "hsl(1.57079633RAD, 100%, -10%)") === HSL{Float32}(90, 1, 0)
    @test parse(Colorant, "hsl(      100grad, 100%, 0e2%)") === HSL{Float32}(90, 1, 0)

    @test parse(Colorant, :red) === colorant"red"
    @test_deprecated parse(Colorant, colorant"red") === colorant"red"

end
