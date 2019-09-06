
using Colors

@testset "din99" begin
    # Test data from the DIN 6176 specification
    testdata = [
        ((50,  10,  10), (61.43,   9.70,   3.76)),
        ((50,  50,  50), (61.43,  28.64,  11.11)),
        ((50, -10,  10), (61.43,  -5.57,   7.03)),
        ((50, -50,  50), (61.43, -17.22,  21.75)),
        ((50, -10, -10), (61.43,  -9.70,  -3.76)),
        ((50, -50, -50), (61.43, -28.64, -11.11)),
        ((50,  10, -10), (61.43,   5.57,  -7.03)),
        ((50,  50, -50), (61.43,  17.22, -21.75)),
        (( 0,   0,   0), ( 0,      0,      0)),
        ((100,  0,   0), (100,     0,      0))]

    # A high error threshold has been chosen because converting from DIN99
    # to CIELAB with only two decimal places of accuracy yields fairly inaccurate
    # results due to the exponentiation.
    conveps = 0.05
    diffeps = 0.01
    let a, b, metric
        for (i, (a, b)) in enumerate(testdata)
            converted = convert(DIN99, Lab(a...))
            test = DIN99(b...)

            @test (abs(converted.l - test.l) < conveps)
            @test (abs(converted.a - test.a) < conveps)
            @test (abs(converted.b - test.b) < conveps)

            converted = convert(Lab, DIN99(b...))
            test = Lab(a...)

            @test (abs(converted.l - test.l) < conveps)
            @test (abs(converted.a - test.a) < conveps)
            @test (abs(converted.b - test.b) < conveps)

            # This is not a real test of the color difference metric, but at least
            # makes sure it isn't doing anything really crazy.
            metric = DE_DIN99()
            @test (abs(colordiff(convert(DIN99, Lab(a...)), DIN99(b...); metric=metric)) < diffeps)
        end
    end

    # From #256
    for c in (RGB(1, 0.5, 0),)
        @test colordiff(convert(RGB,convert(DIN99d, c)), c) < 1e-3
    end
    for c in (RGBA(1,0.5,0,0.4),)
        cc = convert(RGBA,convert(DIN99dA, c))
        @test colordiff(color(cc), color(c)) < 1e-3
        @test cc.alpha ≈ c.alpha atol=1e-3
    end
end  # @testset
