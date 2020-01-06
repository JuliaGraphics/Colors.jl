using Colors, FixedPointNumbers, Test, InteractiveUtils

@testset "Utilities" begin

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
    end

    # test utility function weighted_color_mean
    parametric2 = [GrayA,AGray32,AGray]
    parametric3 = ColorTypes.parametric3
    parametric4A = setdiff(subtypes(ColorAlpha),[GrayA])
    parametricA4 = setdiff(subtypes(AlphaColor),[AGray32,AGray])
    colortypes = vcat(parametric3,parametric4A,parametricA4)
    colorElementTypes = [Float16,Float32,Float64,BigFloat,N0f8,N6f10,N4f12,N2f14,N0f16]

    for T in colorElementTypes
        c1 = Gray{T}(1)
        c2 = Gray{T}(0)
        @test weighted_color_mean(0.5,c1,c2) == Gray{T}(0.5)
    end

    for C in parametric2
        for T in colorElementTypes
            C == AGray32 && (T=N0f8)
        c1 = C(T(0),T(1))
            c2 = C(T(1),T(0))
        @test weighted_color_mean(0.5,c1,c2) == C(T(1)-T(0.5),T(0.5))
        end
    end

    for C in colortypes
        for T in (Float16,Float32,Float64,BigFloat)
        if C<:Color
                c1 = C(T(1),T(1),T(0))
                c2 = C(T(0),T(1),T(1))
            @test weighted_color_mean(0.5,c1,c2) == C(T(0.5),T(0.5)+T(1)-T(0.5),T(1)-T(0.5))
        else
                C == ARGB32 && (T=N0f8)
                c1 = C(T(1),T(1),T(0),T(1))
                c2 = C(T(0),T(1),T(1),T(0))
            @test weighted_color_mean(0.5,c1,c2) == C(T(0.5),T(0.5)+T(1)-T(0.5),T(1)-T(0.5),T(0.5))
        end
        end
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
