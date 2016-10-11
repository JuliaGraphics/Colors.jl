using Colors, FixedPointNumbers, JLD
using Base.Test
using ColorTypes: eltype_default

r8(x) = reinterpret(N0f8, x)

# Color parsing
const redN0f8 = parse(Colorant, "red")
@test colorant"red" == redN0f8
@test isa(redN0f8, RGB{N0f8})
@test redN0f8 == RGB(1,0,0)
const redF64 = convert(RGB{Float64}, redN0f8)
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

@test parse(Colorant, :red) === colorant"red"
@test parse(Colorant, colorant"red") === colorant"red"

@test hex(RGB(1,0.5,0)) == "FF8000"
@test hex(RGBA(1,0.5,0,0.25)) == "40FF8000"

fractional_types = (RGB, BGR, RGB1, RGB4)  # types that support Fractional

const red24 = reinterpret(RGB24, 0x00ff0000)
const red32 = reinterpret(ARGB32, 0xffff0000)
for T in (Float64, Float32, N0f8)
    c = RGB(one(T), zero(T), zero(T))
    @test eltype(c) == T
    c64 = convert(RGB{Float64}, c)
    @test typeof(c64) == RGB{Float64}
    @test c64 == redF64
    cr = convert(RGB{T}, redF64)
    @test cr == c
end
@test RGB(1,0,0) == redF64
@test RGB(convert(UInt8, 1),0,0) == redF64
@test RGB(convert(UInt8, 1),convert(UInt8, 0),convert(UInt8, 0)) == redF64
@test convert(RGB, red24) == redF64

@test convert(Gray{N0f8}, Gray{N0f8}(0.1)) == Gray{N0f8}(0.1)
@test convert(Gray{N0f8}, Gray(0.1))     == Gray{N0f8}(0.1)
@test convert(Gray{N0f8}, Gray24(0.1))   == Gray{N0f8}(0.1)
@test convert(Gray24, Gray{N0f8}(0.1))   == Gray24(0.1)

@test convert(RGB{N0f8}, Gray{N0f8}(0.1)) == RGB{N0f8}(0.1,0.1,0.1)
@test convert(RGB{N0f8}, Gray24(0.1))   == RGB{N0f8}(0.1,0.1,0.1)

for Cto in ColorTypes.parametric3
    for Cfrom in ColorTypes.parametric3
        for Tto in (Float32, Float64)
            for Tfrom in (Float32, Float64)
                c = convert(Cfrom{Tfrom}, redF64)
                @test typeof(c) == Cfrom{Tfrom}
                c1 = convert(Cto, c)
                @test eltype(c1) == Tfrom
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
    end
end
for Cto in ColorTypes.parametric3
    @test typeof(convert(Cto, red24)) == Cto{eltype_default(Cto)}
    @test typeof(convert(Cto{Float64}, red24)) == Cto{Float64}
end

# Test conversion from UFixed types
for Cto in ColorTypes.parametric3
    for Cfrom in fractional_types
        for Tto in (Float32, Float64)
            for Tfrom in (N0f8, N6f10, N4f12, N2f14, N0f16)
                c = convert(Cfrom{Tfrom}, redF64)
                @test typeof(c) == Cfrom{Tfrom}
                if !(eltype_default(Cto) <: FixedPoint)
                    c1 = convert(Cto, c)
                    @test eltype(c1) == eltype_default(Cto)
                end
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
    end
end

# Test conversion to UFixed types
for Cto in fractional_types
    for Cfrom in ColorTypes.parametric3
        for Tto in (N0f8, N6f10, N4f12, N2f14, N0f16)
            for Tfrom in (Float32, Float64)
                c = convert(Cfrom{Tfrom}, redF64)
                @test typeof(c) == Cfrom{Tfrom}
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
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
@test convert(HSVA{Float64}, red32) == HSVA{Float64}(360, 1, 1, 1)

if VERSION >= v"0.4.0-dev"
    @test_throws MethodError AlphaColor(RGB(1,0,0), r8(0xff))
else
    @test_throws ErrorException AlphaColor(RGB(1,0,0), r8(0xff))
end

# whitepoint conversions
@test isa(convert(XYZ, convert(Lab, redF64), Colors.WP_DEFAULT), XYZ{Float64})
@test isa(convert(XYZ{Float32}, convert(Lab, redF64), Colors.WP_DEFAULT), XYZ{Float32})
@test isa(convert(XYZ, convert(Luv, redF64), Colors.WP_DEFAULT), XYZ{Float64})
@test isa(convert(XYZ{Float32}, convert(Luv, redF64), Colors.WP_DEFAULT), XYZ{Float32})
@test isa(convert(Lab, convert(XYZ, redF64), Colors.WP_DEFAULT), Lab{Float64})
@test isa(convert(Lab{Float32}, convert(XYZ, redF64), Colors.WP_DEFAULT), Lab{Float32})
@test isa(convert(Luv, convert(XYZ, redF64), Colors.WP_DEFAULT), Luv{Float64})
@test isa(convert(Luv{Float32}, convert(XYZ, redF64), Colors.WP_DEFAULT), Luv{Float32})

# Test vector space operations
import Base.full
full(T::Color) = map(x->getfield(T, x), fieldnames(T)) #Allow test to access numeric elements
# Generated from:
#=
julia> for t in subtypes(ColorValue)
          isleaftype(t) || isleaftype(t{Float64}) || continue

          try
              println("@test_approx_eq_eps ", t(0.125, 0.5, 0), "+", t(0.2, 0.7, 0.4), " ", t(0.125, 0.5, 0) + t(0.2, 0.7, 0.4), " 91eps()")
              println("@test_approx_eq_eps 3", t(0.125, 0.5, 0.03), " ", 3t(0.125, 0.5, 0.03), " 91eps()\n")
          catch    continue
          end
       end
=#

@test_approx_eq_eps LMS{Float64}(0.125,0.5,0.0)+LMS{Float64}(0.2,0.7,0.4) LMS{Float64}(0.32500000000000007,1.2000000000000002,0.4000000000000001) 91eps()
@test_approx_eq_eps 3LMS{Float64}(0.125,0.5,0.03) LMS{Float64}(0.37499999999999994,1.4999999999999998,0.09000000000000001) 91eps()

@test_approx_eq_eps XYZ{Float64}(0.125,0.5,0.0)+XYZ{Float64}(0.2,0.7,0.4) XYZ{Float64}(0.325,1.2,0.4) 91eps()
@test_approx_eq_eps 3XYZ{Float64}(0.125,0.5,0.03) XYZ{Float64}(0.375,1.5,0.09) 91eps()

#59
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 0.0, 0.0)) === (0.0, 0.0)
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 0.0)) === (0.0, 0.6)
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 1.0)) === (0.0, 0.5)
@test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 1.0)) === (1.0, 0.0)
@test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 0.0)) === (4.0, 0.0)

# ColorTypes.jl issue #40
@test_approx_eq_eps convert(HSL, RGB{N0f8}(0.678, 0.847, 0.902)) HSL{Float32}(194.73685f0,0.5327105f0,0.7901961f0) 100eps(Float32)

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
c = Gray{N0f16}(0.8)
@test convert(RGB, c) == RGB{N0f16}(0.8,0.8,0.8)
@test convert(RGB{Float32}, c) == RGB{Float32}(0.8,0.8,0.8)

# More AbstractRGB
r4 = RGB4(1,0,0)
@test convert(RGB, r4) == RGB(1,0,0)
@test convert(RGB{N0f8}, r4) == RGB{N0f8}(1,0,0)
@test convert(RGB4{N0f8}, r4) == RGB4{N0f8}(1,0,0)
@test convert(RGB4{Float32}, r4) == RGB4{Float32}(1,0,0)
@test convert(BGR{Float32}, r4) == BGR{Float32}(1,0,0)

# Test accuracy of conversion
csconv = jldopen(joinpath(dirname(@__FILE__), "test_conversions.jld")) do file
    read(file, "csconv")
end

function convcompare(from, to, eps; showfailure::Bool=false)
    errmax = 0.0
    for i = 1:length(from)
        t = to[i]
        f = convert(typeof(t), from[i])
        diff = abs(comp1(t)-comp1(f)) + abs(comp2(t)-comp2(f)) + abs(comp3(t)-comp3(f))
        mag = abs(comp1(t)+comp1(f)) + abs(comp2(t)+comp2(f)) + abs(comp3(t)+comp3(f))
        if showfailure && diff>eps*mag
            original = from[i]
            @show original f t
        end
        errmax = max(errmax, diff/mag)
    end
    errmax > eps && warn("Error on conversions from ", eltype(from), " to ", eltype(to), ", relative error = ", errmax)
    errmax <= eps
end

for i = 1:length(csconv)
    f, t = csconv[i]
    if !convcompare(f, t, 1e-3)
        println("  index $i")
    end
end

# Images issue #382
@test convert(Gray, RGBA(1,1,1,1)) == Gray(N0f8(1))

# https://github.com/timholy/Images.jl/pull/445#issuecomment-189866806
@test convert(Gray, RGB{N0f8}(0.145,0.145,0.145)) == Gray{N0f8}(0.145)

# Issue #257
c = RGB{Float16}(0.9473,0.962,0.9766)
hsi = convert(HSI, c)
@test hsi.i > 0.96 && hsi.h ≈ 210
