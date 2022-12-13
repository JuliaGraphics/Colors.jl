using Colors, FixedPointNumbers
using Test
using ColorTypes: eltype_default, parametric3

struct C3{T} <: Color{T,3}
    c1::T; c2::T; c3::T;
end
struct C4{T} <: Color{T,4}
    c1::T; c2::T; c3::T; c4::T;
end
function ColorTypes._convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c) where {Cdest<:AbstractRGB,Odest,Osrc<:C4}
    Cdest(c.c1 + c.c4, c.c2 + c.c4, c.c3 + c.c4)
end
function ColorTypes._convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c) where {Cdest<:C4,Odest,Osrc<:AbstractRGB}
    r, g, b = red(c), green(c), blue(c)
    c4 = min(r, g, b)
    Cdest(r - c4, g - c4, b - c4, c4)
end

@testset "Conversion" begin
    r8(x) = reinterpret(N0f8, x)

    # srgb_compand / invert_srgb_compand
    @test Colors.srgb_compand(0.5) ≈ 0.7353569830524494 atol=eps()
    @test Colors.invert_srgb_compand(0.7353569830524494) ≈ 0.5 atol=eps()
    @test Colors.invert_srgb_compand(0.735357f0) ≈ 0.5f0 atol=eps(Float32)

    fractional_types = (RGB, BGR, XRGB, RGBX)  # types that support Fractional

    redF64 = RGB{Float64}(1,0,0)
    redF32 = RGB{Float32}(1,0,0)
    red24 = reinterpret(RGB24, 0x00ff0000)
    red32 = reinterpret(ARGB32, 0xffff0000)
    @testset "type check: RGB, RGB{$T}" for T in (Float64, Float32, N0f8)
        c = RGB(one(T), zero(T), zero(T))
        @test eltype(c) == T
        @test convert(RGB{Float64}, c) === redF64
        @test convert(RGB{T}, redF64) == c
    end
    @test RGB(1,0,0) == redF64
    @test RGB(UInt8(1), 0, 0) == redF64
    @test RGB(UInt8(1), UInt8(0), UInt8(0)) == redF64 # != colorant"#010000"
    @test convert(RGB, red24) == redF64

    @testset "type check: RGB24-->$Cto" for Cto in parametric3
        @test typeof(convert(Cto, red24)) == Cto{eltype_default(Cto)}
        @test typeof(convert(Cto{Float64}, red24)) == Cto{Float64}
    end

    @testset "type check: C{Float}-->C{Float}" for Cfrom in parametric3, Tfrom in (Float32, Float64)
        c = convert(Cfrom{Tfrom}, redF64)
        @test typeof(c) == Cfrom{Tfrom}
        @testset "$Cfrom{$Tfrom}-->$Cto" for Cto in parametric3
            c1 = convert(Cto, c)
            @test eltype(c1) == Tfrom
        end
        @testset "$Cfrom{$Tfrom}-->$Cto{$Tto}" for Cto in parametric3, Tto in (Float32, Float64)
            c2 = convert(Cto{Tto}, c)
            @test typeof(c2) == Cto{Tto}
        end
    end

    normed_types = (N0f8, N6f10, N4f12, N2f14, N0f16)
    # Test conversion from Normed types
    @testset "type check: C{Normed}-->C{Float}" for Cfrom in fractional_types, Tfrom in normed_types
        c = convert(Cfrom{Tfrom}, redF64)
        @test typeof(c) == Cfrom{Tfrom}
        @testset "$Cfrom{$Tfrom}-->$Cto" for Cto in parametric3
            eltype_default(Cto) <: FixedPoint && continue
            c1 = convert(Cto, c)
            @test eltype(c1) == eltype_default(Cto)
        end
        @testset "$Cfrom{$Tfrom}-->$Cto{$Tto}" for Cto in parametric3, Tto in (Float32, Float64)
            c2 = convert(Cto{Tto}, c)
            @test typeof(c2) == Cto{Tto}
        end
    end

    # Test conversion to Normed types
    @testset "type check: C{Float}-->C{Normed}" for Cfrom in parametric3, Tfrom in (Float32, Float64)
        c = convert(Cfrom{Tfrom}, redF64)
        @test typeof(c) == Cfrom{Tfrom}
        @testset "$Cfrom{$Tfrom}-->$Cto{$Tto}" for Cto in fractional_types, Tto in normed_types
            c2 = convert(Cto{Tto}, c)
            @test typeof(c2) == Cto{Tto}
        end
    end

    ac = RGBA(redF64)

    @test convert(RGB, ac) == RGB(1,0,0)
    @test convert(RGB{N0f8}, ac) == RGB{N0f8}(1,0,0)
    @test convert(RGBA{N0f8}, ac) == RGBA{N0f8}(1,0,0,1)
    @test convert(HSVA, ac) == HSVA{Float64}(convert(HSV, redF64), 1.0)
    @test convert(HSVA{Float32}, ac) == HSVA{Float32}(convert(HSV{Float32}, redF64), 1.0f0)
    @test convert(RGBA, redF64) == ac

    @test convert(ARGB32, ac) == reinterpret(ARGB32, 0xffff0000)
    @test convert(ARGB32, RGB(1,0,0)) == reinterpret(ARGB32, 0xffff0000)
    ac32 = convert(ARGB32, RGB(1,0,0), 0.5)
    @test ac32 == reinterpret(ARGB32, 0x80ff0000)
    @test convert(ARGB32, ac32) === ac32
    @test convert(ARGB32, BGRA(1,0,0,0.5)) == reinterpret(ARGB32, 0x80ff0000)
    @test reinterpret(UInt32, convert(ARGB32, ac)) == 0xffff0000
    @test convert(RGB24, RGB(r8(0xff),r8(0x00),r8(0x00))) == reinterpret(RGB24, 0x00ff0000)
    @test reinterpret(UInt32, convert(RGB24, RGB(r8(0xff),r8(0x00),r8(0x00)))) == 0x00ff0000
    redhsv = convert(HSV, redF64)
    @test convert(RGB24, red24) === red24
    @test convert(RGB24, redhsv) == reinterpret(RGB24, 0x00ff0000)
    @test_throws ArgumentError convert(RGB24,  RGB(0, 1.1, 0))
    @test_throws ArgumentError convert(ARGB32, RGBA(0, 1.1, 0, 0.8))
    @test_throws ArgumentError convert(ARGB32, RGBA(0, 0.8, 0, 1.1))

    @test convert(RGB{N0f8}, red24) == RGB{N0f8}(1,0,0)
    @test convert(RGBA{N0f8}, red32) == RGBA{N0f8}(1,0,0,1)
    @test convert(HSVA{Float64}, red32) == HSVA{Float64}(0, 1, 1, 1)

    # whitepoint conversions
    @test isa(convert(XYZ, convert(Lab, redF64), Colors.WP_DEFAULT), XYZ{Float64})
    @test isa(convert(XYZ{Float32}, convert(Lab, redF64), Colors.WP_DEFAULT), XYZ{Float32})
    @test isa(convert(XYZ, convert(Luv, redF64), Colors.WP_DEFAULT), XYZ{Float64})
    @test isa(convert(XYZ{Float32}, convert(Luv, redF64), Colors.WP_DEFAULT), XYZ{Float32})
    @test isa(convert(Lab, convert(XYZ, redF64), Colors.WP_DEFAULT), Lab{Float64})
    @test isa(convert(Lab{Float32}, convert(XYZ, redF64), Colors.WP_DEFAULT), Lab{Float32})
    @test isa(convert(Luv, convert(XYZ, redF64), Colors.WP_DEFAULT), Luv{Float64})
    @test isa(convert(Luv{Float32}, convert(XYZ, redF64), Colors.WP_DEFAULT), Luv{Float32})

    #59
    @test Colors.xyz_to_uv(XYZ{Float64}(0.0, 0.0, 0.0)) === (0.0, 0.0)
    @test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 0.0)) === (0.0, 0.6)
    @test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 1.0)) === (0.0, 0.5)
    @test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 1.0)) === (1.0, 0.0)
    @test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 0.0)) === (4.0, 0.0)

    # ColorTypes.jl issue #40
    @test convert(HSL, RGB{N0f8}(0.678, 0.847, 0.902)) ≈ HSL{Float32}(194.73685f0,0.5327105f0,0.7901961f0) atol=100eps(Float32)

    # YIQ
    @test convert(YIQ, RGB(1,0,0)) == YIQ{Float32}(0.299, 0.595716, 0.211456)
    @test convert(YIQ, RGB(0,1,0)) == YIQ{Float32}(0.587, -0.274453, -0.522591)
    @test convert(YIQ, RGB(0,0,1)) == YIQ{Float32}(0.114, -0.321263, 0.311135)
    @test convert(RGB, YIQ(1.0,0.0,0.0)) == RGB(1,1,1)
    v = 0.5957
    @test convert(RGB, YIQ(0.0,1.0,0.0)) == RGB(0.9563*v,0,0)
    v = -0.5226
    @test convert(RGB, YIQ(0.0,0.0,-1.0)) == RGB(0,-0.6474*v,0)

    # Gray
    @test convert(Gray{N0f8}, Gray{N0f8}(0.1)) == Gray{N0f8}(0.1)
    @test convert(Gray{N0f8}, Gray(0.1))     == Gray{N0f8}(0.1)
    @test convert(Gray{N0f8}, Gray24(0.1))   == Gray{N0f8}(0.1)
    @test convert(Gray24, Gray{N0f8}(0.1))   == Gray24(0.1)

    @test convert(RGB{N0f8}, Gray{N0f8}(0.1)) == RGB{N0f8}(0.1,0.1,0.1)
    @test convert(RGB{N0f8}, Gray24(0.1))   == RGB{N0f8}(0.1,0.1,0.1)

    grayN0f16 = Gray{N0f16}(0.8)
    @test convert(RGB, grayN0f16) == RGB{N0f16}(0.8,0.8,0.8)
    @test convert(RGB{Float32}, grayN0f16) == RGB{Float32}(0.8,0.8,0.8)

    @testset "$C-->Gray" for C in parametric3
        c = convert(C, RGB(1,1,1))
        g1 = convert(Gray, c)
        @test isa(g1, Gray)
        @test gray(g1) ≈ 1 atol=0.01
        g2 = convert(Gray{Float64}, c)
        @test typeof(g2) == Gray{Float64}
        @test gray(g2) ≈ 1 atol=0.01
    end
    # Issue #377
    @test convert(Gray, RGB24(1,0,0)) === convert(Gray, RGB(1,0,0)) === Gray{N0f8}(0.298)
    @test convert(Gray24, RGB(1,0,0)) === Gray24(0.298)
    # Check for roundoff error
    for N in (N0f8, N0f16, N0f32)
        @test convert(Gray{N}, RGB{N}(1,1,1)) === Gray{N}(1)
    end
    @test gray(convert(Gray{N0f64}, RGB{N0f64}(1,1,1))) ≈ 1.0

    # Images issue #382
    @test convert(Gray, RGBA(1,1,1,1)) == Gray(N0f8(1))

    # https://github.com/timholy/Images.jl/pull/445#issuecomment-189866806
    @test convert(Gray, RGB{N0f8}(0.145,0.145,0.145)) == Gray{N0f8}(0.145)


    # More AbstractRGB
    r4 = RGBX(1,0,0)
    @test convert(RGB, r4) == RGB(1,0,0)
    @test convert(RGB{N0f8}, r4) == RGB{N0f8}(1,0,0)
    @test convert(RGBX{N0f8}, r4) == RGBX{N0f8}(1,0,0)
    @test convert(RGBX{Float32}, r4) == RGBX{Float32}(1,0,0)
    @test convert(BGR{Float32}, r4) == BGR{Float32}(1,0,0)

    # Issue #257
    c = RGB{Float16}(0.9473,0.962,0.9766)
    convert(HSI, c)
    hsi = convert(HSI, c)
    @test hsi.i > 0.96 && hsi.h ≈ 210

    # {HSV, HSL, HSI} --> RGB (issue #379)
    @testset "HSx --> RGB" begin
        @test convert(RGB, HSV{Float32}( 780, 1, 1)) === RGB{Float32}(1,1,0)
        @test convert(RGB, HSV{Float32}(   0, 1, 1)) === RGB{Float32}(1,0,0)
        @test convert(RGB, HSV{Float32}(-780, 1, 1)) === RGB{Float32}(1,0,1)
        @test convert(RGB, HSV{Float32}(30,  2, .5)) === RGB{Float32}(.5,.25,0)
        @test convert(RGB, HSV{Float32}(30, .5, -1)) === RGB{Float32}(0,0,0)
        @test convert(RGB{Float64}, HSV{BigFloat}(-360120, 2, 1)) === RGB{Float64}(0,0,1)

        @test convert(RGB, HSL{Float32}( 780, 1, .5)) === RGB{Float32}(1,1,0)
        @test convert(RGB, HSL{Float32}(   0, 1, .5)) === RGB{Float32}(1,0,0)
        @test convert(RGB, HSL{Float32}(-780, 1, .5)) === RGB{Float32}(1,0,1)
        @test convert(RGB, HSL{Float32}(30,  2, .25)) === RGB{Float32}(.5,.25,0)
        @test convert(RGB, HSL{Float32}(30, .5,  -1)) === RGB{Float32}(0,0,0)
        @test convert(RGB{Float64}, HSL{BigFloat}(-360120, 2, .5)) === RGB{Float64}(0,0,1)

        @test convert(RGB, HSI{Float32}( 780, .5, .5)) ≈ RGB{Float32}(.625,.625,.25)
        @test convert(RGB, HSI{Float32}(   0, .5, .5)) ≈ RGB{Float32}(1,.25,.25)
        @test convert(RGB, HSI{Float32}(-780, .5, .5)) ≈ RGB{Float32}(.625,.25,.625)
        @test convert(RGB, HSI{Float32}(30,  2, .25)) ≈ RGB{Float32}(.5,.25,0)
        @test convert(RGB, HSI{Float32}(30, .5,  -1)) ≈ RGB{Float32}(0,0,0)
        @test convert(RGB{Float64}, HSI{BigFloat}(-360120, .5, .5)) ≈ RGB{Float64}(.25,.25,1)
    end

    @testset "custom types" begin
        # issue #465
        @test_throws ErrorException convert(RGB,   C3{Float32}(1, 2, 3))
        @test_throws ErrorException convert(RGB24, C3{Float64}(1, 2, 3))
        @test_throws ErrorException convert(Lab,   C3{Float16}(1, 2, 3))

        @test @inferred(convert(RGB,   C4{Float32}(0.1, 0.2, 0.3, 0.4))) ≈ RGB{Float32}(0.5, 0.6, 0.7)
        @test @inferred(convert(RGB24, C4{Float64}(0.1, 0.2, 0.3, 0.4))) ≈ RGB24(0.5, 0.6, 0.7)
        @test @inferred(convert(ALab,  C4{Float16}(0.1, 0.2, 0.3, 0.4))) ≈ ALab{Float16}(62.12, -2.86, -16.25, 1.0)

        @test @inferred(convert(C4, RGB{Float32}(0.5, 0.6, 0.7))) ≈ C4{Float32}(0.0, 0.1, 0.2, 0.5)
        @test @inferred(convert(C4{N0f8}, ARGB32(0.5, 0.6, 0.7))) ≈ C4{N0f16}(0.0, 0.1, 0.2, 0.5)
        @test @inferred(convert(C4, Lab{Float16}(62.12, -2.86, -16.25))) ≈ C4{Float16}(0.0, 0.1, 0.2, 0.5)
    end

    # Test accuracy of conversion
    include("test_conversions.jl")

    # Since `colordiff`(e.g. `DE_2000`) involves a color space conversion, it is
    # not suitable for evaluating the conversion itself. On the other hand,
    # since the tolerance varies from component to component, a homogeneous
    # error evaluation function (e.g. a simple sum of differences) is also not
    # appropriate. Therefore, a series of `diffnorm`, which returns the
    # normalized Euclidean distance, is defined as follows. They are just for
    # testing purposes as the cyclicity of hue is ignored.
    sqd(a, b, s=1.0) = ((float(a) - float(b))/s)^2
    function diffnorm(a::T, b::T) where {T<:Color3} # RGB,XYZ,xyY,LMS
        sqrt(sqd(comp1(a), comp1(b)) + sqd(comp2(a), comp2(b)) + sqd(comp3(a),comp3(b)))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:Union{HSV,HSL,HSI}}
        sqrt(sqd(a.h, b.h, 360) + sqd(a.s, b.s) + sqd(comp3(a), comp3(b)))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:Union{Lab,Luv}}
        sqrt(sqd(a.l, b.l, 100) + sqd(comp2(a), comp2(b), 200) + sqd(comp3(a), comp3(b), 200))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:Union{LCHab,LCHuv}}
        sqrt(sqd(a.l, b.l, 100) + sqd(a.c, b.c, 100) + sqd(a.h, b.h, 360))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:Union{DIN99,DIN99d,DIN99o}} # csconv has no DIN99 case
        sqrt(sqd(a.l, b.l, 100) + sqd(a.a, b.a, 100) + sqd(a.b, b.b, 100))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:YIQ}
        sqrt(sqd(a.y, b.y) + sqd(a.i, b.i, 1.2) + sqd(a.q, b.q, 1.2))/sqrt(3)
    end
    function diffnorm(a::T, b::T) where {T<:YCbCr}
        sqrt(sqd(a.y, b.y, 219) + sqd(a.cb, b.cb, 224) + sqd(a.cr, b.cr, 224))/sqrt(3)
    end

    for C in ColorTypes.parametric3
        y = convert(C, RGB(1.0,1.0,0.0))
        b = convert(C, RGB(0.1,0.1,0.2))
        diffnorm(y, b) < 0.5 && @warn("`diffnorm` for $C may be broken")
    end

    function convcompare(from, to, tol; showfailure::Bool=false)
        errmax = 0.0
        for i in eachindex(from)
            t = to[i]
            f = convert(typeof(t), from[i])
            diff = diffnorm(t, f)
            if showfailure && diff>tol
                original = from[i]
                @show original f t diff
            end
            errmax = max(errmax, diff)
        end
        errmax > tol && @warn("Error on conversions from $(eltype(from)) to $(eltype(to)), relative error = $errmax")
        errmax <= tol
    end

    @testset "accuracy test: $Cfrom-->$Cto" for Cto in keys(csconv), Cfrom in keys(csconv)
        f = csconv[Cfrom]
        t = csconv[Cto]
        @test convcompare(f, t, 2e-3, showfailure=false)
    end
end
