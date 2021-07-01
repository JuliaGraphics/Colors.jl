using Colors, Test

# Test the colordiff function against example input and output from:
#
#   Sharma, G., Wu, W., & Dalal, E. N. (2005). The CIEDE2000 color‐difference
#   formula: Implementation notes, supplementary test data, and mathematical
#   observations. Color Research & Application, 30(1), 21–30. doi:10.1002/col
#

@testset "ColorDiff" begin
    abds = [
        ((50.0000,   2.6772, -79.7751), (50.0000,   0.0000, -82.7485),  2.0425),
        ((50.0000,   3.1571, -77.2803), (50.0000,   0.0000, -82.7485),  2.8615),
        ((50.0000,   2.8361, -74.0200), (50.0000,   0.0000, -82.7485),  3.4412),
        ((50.0000,  -1.3802, -84.2814), (50.0000,   0.0000, -82.7485),  1.0000),
        ((50.0000,  -1.1848, -84.8006), (50.0000,   0.0000, -82.7485),  1.0000),
        ((50.0000,  -0.9009, -85.5211), (50.0000,   0.0000, -82.7485),  1.0000),
        ((50.0000,   0.0000,   0.0000), (50.0000,  -1.0000,   2.0000),  2.3669),
        ((50.0000,  -1.0000,   2.0000), (50.0000,   0.0000,   0.0000),  2.3669),
        ((50.0000,   2.4900,  -0.0010), (50.0000,  -2.4900,   0.0009),  7.1792),
        ((50.0000,   2.4900,  -0.0010), (50.0000,  -2.4900,   0.0010),  7.1792),
        ((50.0000,   2.4900,  -0.0010), (50.0000,  -2.4900,   0.0011),  7.2195),
        ((50.0000,   2.4900,  -0.0010), (50.0000,  -2.4900,   0.0012),  7.2195),
        ((50.0000,  -0.0010,   2.4900), (50.0000,   0.0009,  -2.4900),  4.8045),
        ((50.0000,  -0.0010,   2.4900), (50.0000,   0.0010,  -2.4900),  4.8045),
        ((50.0000,  -0.0010,   2.4900), (50.0000,   0.0011,  -2.4900),  4.7461),
        ((50.0000,   2.5000,   0.0000), (50.0000,   0.0000,  -2.5000),  4.3065),
        ((50.0000,   2.5000,   0.0000), (73.0000,  25.0000, -18.0000), 27.1492),
        ((50.0000,   2.5000,   0.0000), (61.0000,  -5.0000,  29.0000), 22.8977),
        ((50.0000,   2.5000,   0.0000), (56.0000, -27.0000,  -3.0000), 31.9030),
        ((50.0000,   2.5000,   0.0000), (58.0000,  24.0000,  15.0000), 19.4535),
        ((50.0000,   2.5000,   0.0000), (50.0000,   3.1736,   0.5854),  1.0000),
        ((50.0000,   2.5000,   0.0000), (50.0000,   3.2972,   0.0000),  1.0000),
        ((50.0000,   2.5000,   0.0000), (50.0000,   1.8634,   0.5757),  1.0000),
        ((50.0000,   2.5000,   0.0000), (50.0000,   3.2592,   0.3350),  1.0000),
        ((60.2574, -34.0099,  36.2677), (60.4626, -34.1751,  39.4387),  1.2644),
        ((63.0109, -31.0961,  -5.8663), (62.8187, -29.7946,  -4.0864),  1.2630),
        ((61.2901,   3.7196,  -5.3901), (61.4292,   2.2480,  -4.9620),  1.8731),
        ((35.0831, -44.1164,   3.7933), (35.0232, -40.0716,   1.5901),  1.8645),
        ((22.7233,  20.0904, -46.6940), (23.0331,  14.9730, -42.5619),  2.0373),
        ((36.4612,  47.8580,  18.3852), (36.2715,  50.5065,  21.2231),  1.4146),
        ((90.8027,  -2.0831,   1.4410), (91.1528,  -1.6435,   0.0447),  1.4441),
        ((90.9257,  -0.5406,  -0.9208), (88.6381,  -0.8985,  -0.7239),  1.5381),
        (( 6.7747,  -0.2908,  -2.4247), ( 5.8714,  -0.0985,  -2.2286),  0.6377),
        ((2.0776,    0.0795,  -1.1350), ( 0.9033,  -0.0636,  -0.5514),  0.9082)]


    eps_cdiff = 0.00005

    @testset "CIEDE2000" begin
        metric = DE_2000()
        for (a, b, dexpect) in abds
            a64, b64 = Lab(a...), Lab(b...)
            @test colordiff(a64, b64; metric=metric) ≈ dexpect atol=eps_cdiff
            @test colordiff(b64, a64; metric=metric) ≈ dexpect atol=eps_cdiff
        end
    end

    jl_red    =    RGB{N0f8}(Colors.JULIA_LOGO_COLORS.red)
    jl_green  = RGB{Float32}(Colors.JULIA_LOGO_COLORS.green)
    jl_blue   = HSV{Float64}(Colors.JULIA_LOGO_COLORS.blue)
    jl_purple = Lab{Float32}(Colors.JULIA_LOGO_COLORS.purple)
    colors = (jl_red, jl_green, jl_blue, jl_purple)
    pairs = ((a, b) for a in colors for b in Iterators.filter(c -> c != a,colors))

    @testset "properties of metrics" begin
        metrics = (DE_2000(), DE_94(), DE_JPC79(), DE_CMC(), DE_BFD(),
                   DE_AB(), DE_DIN99(), DE_DIN99d(), DE_DIN99o())

        @testset "$metric" for metric in metrics
            # identity of indiscernibles
            @test all(c -> colordiff(c, c; metric=metric) == 0, colors)
            # positivity
            @test all(p -> colordiff(p[1], p[2]; metric=metric) > 0, pairs)
            # symmetry
            if metric isa DE_CMC # quasimetric
                # TODO: add test
            else
                @test all(p -> abs(colordiff(p[1], p[2]; metric=metric) -
                                   colordiff(p[2], p[1]; metric=metric)) < eps_cdiff, pairs)
            end
            # triangle inequality
            metric isa DE_CMC && continue # FIXME
            @test all(p -> colordiff(p[1],   p[2]; metric=metric) <=
                           colordiff(p[1], jl_red; metric=metric) +
                           colordiff(jl_red, p[2]; metric=metric), pairs)
        end
    end

    @testset "colordiff with grays" begin
        a, b = rand(100), rand(100)
        @test all(@. colordiff(a, b) == colordiff(Gray(a), b) == colordiff(a, Gray(b)) == colordiff(Gray(a), Gray(b)))
    end


    @testset "colordiff with transparent colors" begin
        @test colordiff(RGBA(1,0,0,1), RGB(1,0,0)) == 0
        @test colordiff(RGB(1,0,0), RGBA(1,0,0,1), metric=DE_AB()) == 0
        @test colordiff(RGBA(1,0,0,1), RGBA(1,0,0,1)) == 0
        @test_throws ArgumentError colordiff(RGBA(1,0,0,0.5), RGB(1,0,0))
        @test_throws ArgumentError colordiff(RGBA(1,0,0,0.5), RGBA(1,0,0,0.5))
    end
end
