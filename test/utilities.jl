using Colors, FixedPointNumbers, Test
using InteractiveUtils # for `subtypes`

@testset "Utilities" begin
    @test Colors.cbrt01(0.6) ≈ cbrt(big"0.6") atol=eps(1.0)
    @test Colors.cbrt01(0.6f0) === cbrt(0.6f0)

    # issue #351
    xs = max.(rand(1000), 1e-4)
    @noinline l_pow_x_y() = for x in xs; x^2.4 end
    @noinline l_pow12_5() = for x in xs; Colors.pow12_5(x) end
    l_pow_x_y(); t_pow_x_y = @elapsed l_pow_x_y()
    l_pow12_5(); t_pow12_5 = @elapsed l_pow12_5()
    if t_pow12_5 > t_pow_x_y
        @warn "Optimization technique in `pow12_5` may have the opposite effect."
    end
    @noinline l_exp_y_log_x() = for x in xs; exp(1/2.4 * log(x)) end
    @noinline l_pow5_12() = for x in xs; Colors.pow5_12(x) end
    l_exp_y_log_x(); t_exp_y_log_x = @elapsed l_exp_y_log_x()
    l_pow5_12(); t_pow5_12 = @elapsed l_pow5_12()
    if t_pow5_12 > t_exp_y_log_x
        @warn "Optimization technique in `pow5_12` may have the opposite effect."
    end

    @test Colors.pow5_12(0.6) ≈ Colors.pow5_12(big"0.6") atol=1e-6
    @test Colors.pow5_12(0.6f0) ≈ Colors.pow5_12(big"0.6") atol=1e-6
    @test Colors.pow5_12(0.6N0f16) ≈ Colors.pow5_12(big"0.6") atol=1e-6
    @test Colors.pow12_5(0.6) ≈ Colors.pow12_5(big"0.6") atol=1e-6
    @test Colors.pow12_5(0.6N0f16) ≈ Colors.pow12_5(big"0.6") atol=1e-6

    @testset "hex" begin
        base_hex = @test_logs (:warn, r"Base\.hex\(c\) has been moved") Base.hex(RGB(1,0.5,0))
        @test base_hex == hex(RGB(1,0.5,0))

        @test hex(RGB(1,0.5,0)) == "FF8000"
        rgba = @test_logs (:warn, r"will soon be changed") hex(RGBA(1,0.5,0,0.25))
        @test rgba == "40FF8000" # TODO: change it to "FF800040"
        @test hex(ARGB(1,0.5,0,0.25)) == "40FF8000"
        @test hex(HSV(30,1.0,1.0)) == "FF8000"

        @test hex(RGB(1,0.5,0), :AUTO) == "FF8000"
        @test hex(RGBA(1,0.5,0,0.25), :AUTO) == "FF800040"
        @test hex(ARGB(1,0.5,0,0.25), :AUTO) == "40FF8000"
        @test hex(HSV(30,1.0,1.0), :AUTO) == "FF8000"
        @test hex(RGB(1,0.5,0), :SomethingUnknown) == "FF8000"

        @test hex(RGB(1,0.5,0), :S) == "FF8000"
        @test hex(RGBA(1,0.5,0,0.25), :S) == "FF800040"
        @test hex(ARGB(1,0.5,0,0.25), :S) == "40FF8000"
        @test hex(RGB(1,0.533,0), :S) == "F80"
        @test hex(RGBA(1,0.533,0,0.267), :S) == "F804"
        @test hex(ARGB(1,0.533,0,0.267), :S) == "4F80"

        @test hex(RGB(1,0.5,0), :s) == "ff8000"
        @test hex(RGBA(1,0.5,0,0.25), :s) == "ff800040"
        @test hex(ARGB(1,0.5,0,0.25), :s) == "40ff8000"
        @test hex(RGB(1,0.533,0), :s) == "f80"
        @test hex(RGBA(1,0.533,0,0.267), :s) == "f804"
        @test hex(ARGB(1,0.533,0,0.267), :s) == "4f80"

        @test hex(RGB(1,0.5,0), :RGB) == "F80"
        @test hex(RGBA(1,0.5,0,0.25), :RGB) == "F80"
        @test hex(ARGB(1,0.5,0,0.25), :RGB) == "F80"
        @test hex(HSV(30,1.0,1.0), :RGB) == "F80"

        @test hex(RGB(1,0.5,0), :rgb) == "f80"
        @test hex(RGBA(1,0.5,0,0.25), :rgb) == "f80"
        @test hex(ARGB(1,0.5,0,0.25), :rgb) == "f80"
        @test hex(HSV(30,1.0,1.0), :rgb) == "f80"

        @test hex(RGB(1,0.5,0), :ARGB) == "FF80"
        @test hex(RGBA(1,0.5,0,0.25), :ARGB) == "4F80"
        @test hex(ARGB(1,0.5,0,0.25), :ARGB) == "4F80"
        @test hex(HSV(30,1.0,1.0), :ARGB) == "FF80"

        @test hex(RGB(1,0.5,0), :argb) == "ff80"
        @test hex(RGBA(1,0.5,0,0.25), :argb) == "4f80"
        @test hex(ARGB(1,0.5,0,0.25), :argb) == "4f80"
        @test hex(HSV(30,1.0,1.0), :argb) == "ff80"

        @test hex(RGB(1,0.5,0), :RGBA) == "F80F"
        @test hex(RGBA(1,0.5,0,0.25), :RGBA) == "F804"
        @test hex(ARGB(1,0.5,0,0.25), :RGBA) == "F804"
        @test hex(HSV(30,1.0,1.0), :RGBA) == "F80F"

        @test hex(RGB(1,0.5,0), :rgba) == "f80f"
        @test hex(RGBA(1,0.5,0,0.25), :rgba) == "f804"
        @test hex(ARGB(1,0.5,0,0.25), :rgba) == "f804"
        @test hex(HSV(30,1.0,1.0), :rgba) == "f80f"

        @test hex(RGB(1,0.5,0), :rrggbb) == "ff8000"
        @test hex(RGBA(1,0.5,0,0.25), :rrggbb) == "ff8000"
        @test hex(ARGB(1,0.5,0,0.25), :rrggbb) == "ff8000"
        @test hex(HSV(30,1.0,1.0), :rrggbb) == "ff8000"

        @test hex(RGB(1,0.5,0), :RRGGBB) == "FF8000"
        @test hex(RGBA(1,0.5,0,0.25), :RRGGBB) == "FF8000"
        @test hex(ARGB(1,0.5,0,0.25), :RRGGBB) == "FF8000"
        @test hex(HSV(30,1.0,1.0), :RRGGBB) == "FF8000"

        @test hex(RGB(1,0.5,0), :rrggbb) == "ff8000"
        @test hex(RGBA(1,0.5,0,0.25), :rrggbb) == "ff8000"
        @test hex(ARGB(1,0.5,0,0.25), :rrggbb) == "ff8000"
        @test hex(HSV(30,1.0,1.0), :rrggbb) == "ff8000"

        @test hex(RGB(1,0.5,0), :AARRGGBB) == "FFFF8000"
        @test hex(RGBA(1,0.5,0,0.25), :AARRGGBB) == "40FF8000"
        @test hex(ARGB(1,0.5,0,0.25), :AARRGGBB) == "40FF8000"
        @test hex(HSV(30,1.0,1.0), :AARRGGBB) == "FFFF8000"

        @test hex(RGB(1,0.5,0), :aarrggbb) == "ffff8000"
        @test hex(RGBA(1,0.5,0,0.25), :aarrggbb) == "40ff8000"
        @test hex(ARGB(1,0.5,0,0.25), :aarrggbb) == "40ff8000"
        @test hex(HSV(30,1.0,1.0), :aarrggbb) == "ffff8000"

        @test hex(RGB(1,0.5,0), :RRGGBBAA) == "FF8000FF"
        @test hex(RGBA(1,0.5,0,0.25), :RRGGBBAA) == "FF800040"
        @test hex(ARGB(1,0.5,0,0.25), :RRGGBBAA) == "FF800040"
        @test hex(HSV(30,1.0,1.0), :RRGGBBAA) == "FF8000FF"

        @test hex(RGB(1,0.5,0), :rrggbbaa) == "ff8000ff"
        @test hex(RGBA(1,0.5,0,0.25), :rrggbbaa) == "ff800040"
        @test hex(ARGB(1,0.5,0,0.25), :rrggbbaa) == "ff800040"
        @test hex(HSV(30,1.0,1.0), :rrggbbaa) == "ff8000ff"

        @test hex(Gray(0.5)) == "808080"
        @test hex(AGray(1.0, 0.5), :aarrggbb) == "80ffffff"
        @test hex(Gray{Bool}(1)) == "FFFFFF"

        # clamping
        @test hex(RGB(2.0,-1.0,0.5)) == "FF0080"
        @test hex(ARGB(2.0,-1.0,0.5,-10), :rrggbbaa) == "ff008000"
        @test hex(AHSV(30,1.0,1.0,-10), :RRGGBBAA) == "FF800000"
        @test hex(Gray(2.0)) == "FFFFFF"
        @test hex(AGray(1.0, -0.5), :rrggbbaa) == "ffffff00"
    end

    @testset "normalize_hue" begin
        function test_normalize_hue(h::T) where T<:AbstractFloat
            hn, he = normalize_hue(h), T(mod(h, BigFloat(360)))
            !signbit(hn) & (hn <= 360) || return false
            hn ≈ he || (hn == 360 && he == 0) || (hn == 0 && he == 360)
        end

        hues = -1500:1:1500
        @test all(h -> test_normalize_hue(Float64(h)), hues)
        @test all(h -> test_normalize_hue(prevfloat(Float64(h))), hues)
        @test all(h -> test_normalize_hue(nextfloat(Float64(h))), hues)

        @test all(h -> test_normalize_hue(Float32(h)), hues)
        @test all(h -> test_normalize_hue(prevfloat(Float32(h))), hues)
        @test all(h -> test_normalize_hue(nextfloat(Float32(h))), hues)

        @test all(h -> test_normalize_hue(Float16(h)), hues)
        @test all(h -> test_normalize_hue(prevfloat(Float16(h))), hues)
        @test all(h -> test_normalize_hue(nextfloat(Float16(h))), hues)

        @test normalize_hue(HSV{Float64}( 876.5, 0.4, 0.3)) === HSV{Float64}(156.5, 0.4, 0.3)
        @test normalize_hue(HSL{Float32}( 87.65, 0.4, 0.3)) === HSL{Float32}(87.65, 0.4, 0.3)
        @test normalize_hue(HSI{Float16}(-876.5, 0.4, 0.3)) === HSI{Float16}(203.5, 0.4, 0.3)

        @test normalize_hue(AHSV{Float32}(360.5, 0.4, 0.3, 0.2)) === AHSV{Float32}(0.5, 0.4, 0.3, 0.2)
        @test normalize_hue(HSLA{Float64}(360.5, 0.4, 0.3, 0.2)) === HSLA{Float64}(0.5, 0.4, 0.3, 0.2)

        @test normalize_hue(LCHab{Float64}(30, 40,  5.6e7)) === LCHab{Float64}(30, 40, 200)
        @test normalize_hue(LCHuv{Float32}(30, 40, -5.6e7)) === LCHuv{Float32}(30, 40, 160)

        @test normalize_hue(ALCHab{Float32}(30, 40, -0.5, 0.6)) === ALCHab{Float32}(30, 40, 359.5, 0.6)
        @test normalize_hue(LCHuvA{Float64}(30, 40, -0.5, 0.6)) === LCHuvA{Float64}(30, 40, 359.5, 0.6)
    end

    # test utility function weighted_color_mean
    parametric2 = [GrayA,AGray32,AGray]
    parametric3 = ColorTypes.parametric3
    parametric4A = setdiff(subtypes(ColorAlpha),[GrayA])
    parametricA4 = setdiff(subtypes(AlphaColor),[AGray32,AGray])
    colortypes = vcat(parametric3,parametric4A,parametricA4)
    colorElementTypes = [Float16,Float32,Float64,BigFloat,N0f8,N6f10,N4f12,N2f14,N0f16]

    @testset "weighted_color_mean" begin
        for T in colorElementTypes
            c1 = Gray{T}(1)
            c2 = Gray{T}(0)
            @test weighted_color_mean(0.5,c1,c2) == Gray{T}(0.5)
        end
        gray_b1 = Gray{Bool}(1)
        gray_b0 = Gray{Bool}(0)
        @test @inferred(weighted_color_mean(0, gray_b1, gray_b0)) === gray_b0
        @test @inferred(weighted_color_mean(1, gray_b1, gray_b0)) === gray_b1
        @test @inferred(weighted_color_mean(0.5, gray_b1, gray_b1)) === gray_b1
        @test_throws InexactError weighted_color_mean(0.5, gray_b1, gray_b0)
        @test_throws DomainError weighted_color_mean(-1, gray_b1, gray_b0)

        for C in parametric2
            for T in colorElementTypes
                c1 = C(T(0), T(1))
                c2 = C(T(1), T(0))
                cx = C(T(0.5), T(0.5))
                @test @inferred(weighted_color_mean(0.5, c1, c2)) == cx
            end
        end

        for C in colortypes
            for T in (Float16,Float32,Float64,BigFloat)
                if C<:Color
                    c1 = C(T(1), T(1), T(0))
                    c2 = C(T(0), T(1), T(1))
                    cx = C(T(0.5), T(1.0), T(0.5))
                    @test @inferred(weighted_color_mean(0.5, c1, c2)) == cx
                else
                    c1 = C(T(1), T(1), T(0), T(0))
                    c2 = C(T(0), T(1), T(0), T(1))
                    cx = C(T(0.5), T(1.0), T(0.0), T(0.5))
                    @test @inferred(weighted_color_mean(0.5, c1, c2)) == cx
                end
            end
        end

        @test_throws DomainError weighted_color_mean(-0.01, RGB(1,1,0), RGB(0,1,1))
        @test_throws DomainError weighted_color_mean( 1.01, RGB(1,1,0), RGB(0,1,1))

        # promotion
        @test weighted_color_mean(0.5, RGB{N0f8}(1,1,0), RGB{Float32}(0,1,1)) === RGB{Float32}(0.5,1,0.5)
        @test_throws ArgumentError weighted_color_mean(0.5, RGB24(1,1,0), RGB{Float32}(0,1,1))

        @test weighted_color_mean(0.5, HSV(-360.0,1,0), HSV(180.0,0,1)) === HSV{Float64}(270,0.5,0.5)
        alchab1 = ALCHab{Float32}(0,100,-360,1)
        alchab2 = ALCHab{Float32}(100,0,-180,0)
        @test weighted_color_mean(0.5, alchab1, alchab2) === ALCHab{Float32}(50,50,90,0.5)
        lchuva1 = LCHuvA{Float16}(0,100, 90,1)
        lchuva2 = LCHuvA{Float16}(100,0,810,0)
        @test weighted_color_mean(0.5, lchuva1, lchuva2) === LCHuvA{Float16}(50,50,90,0.5)
    end

    # test utility function range
    # range uses weighted_color_mean which is extensively tested.
    # Therefore it suffices to test the function using gray colors.
    for T in colorElementTypes
        c1 = Gray(T(1))
        c2 = Gray(T(0))
        linc1c2 = range(c1,stop=c2,length=43)
        @test length(linc1c2) == 43
        @test linc1c2[1] == c1
        @test linc1c2[end] == c2
        @test linc1c2[22] == Gray(T(0.5))
        @test typeof(linc1c2) == Array{Gray{T},1}
        if VERSION >= v"1.1"
            @test range(c1,c2,length=43) == range(c1,stop=c2,length=43)
        end
    end
end
