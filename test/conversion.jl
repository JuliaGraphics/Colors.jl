using Colors, FixedPointNumbers, Compat, JLD
using Base.Test
import ColorTypes: eltype_default

# Color parsing
const redU8 = parse(Color, "red")
@test Color"red" == redU8
@test isa(redU8, RGB{U8})
@test redU8 == RGB(1,0,0)
const redF64 = convert(RGB{Float64}, redU8)
@test parse(RGB{Float64}, "red") === RGB{Float64}(1,0,0)
@test isa(parse(HSV, "blue"), HSV)
@test parse(Color, "rgb(55,217,127)") === RGB{U8}(0x37uf8,0xd9uf8,0x7fuf8)
@test Color"rgb(55,217,127)" === RGB{U8}(0x37uf8,0xd9uf8,0x7fuf8)
@test parse(Color, "rgba(55,217,127,0.5)") === RGBA{U8}(0x37uf8,0xd9uf8,0x7fuf8,0.5)
@test parse(Color, "rgb(55,217,127)") === RGB{U8}(0x37uf8,0xd9uf8,0x7fuf8)
@test parse(Color, "rgba(55,217,127,0.5)") === RGBA{U8}(0x37uf8,0xd9uf8,0x7fuf8,0.5)
@test parse(Color, "hsl(120, 100%, 50%)") === HSL{Float32}(120,1.0,.5)
@test Color"hsl(120, 100%, 50%)" === HSL{Float32}(120,1.0,.5)
@test parse(RGB{U8}, "hsl(120, 100%, 50%)") === convert(RGB{U8}, HSL{Float32}(120,1.0,.5))
@test_throws ErrorException  parse(Color, "hsl(120, 100, 50)")
@test parse(Color, "#D0FF58") === RGB(0xD0uf8,0xFFuf8,0x58uf8)

@test hex(RGB(1,0.5,0)) == "FF8000"
@test hex(RGBA(1,0.5,0,0.25)) == "40FF8000"

fractional_types = (RGB, BGR, RGB1, RGB4)  # types that support Fractional

const red24 = RGB24(0x00ff0000)
const red32 = ARGB32(0xffff0000)
for T in (Float64, Float32, Ufixed8)
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

# Test conversion from Ufixed types
for Cto in ColorTypes.parametric3
    for Cfrom in fractional_types
        for Tto in (Float32, Float64)
            for Tfrom in (Ufixed8, Ufixed10, Ufixed12, Ufixed14, Ufixed16)
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

# Test conversion to Ufixed types
for Cto in fractional_types
    for Cfrom in ColorTypes.parametric3
        for Tto in (Ufixed8, Ufixed10, Ufixed12, Ufixed14, Ufixed16)
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
@test convert(RGB{Ufixed8}, ac) == RGB{Ufixed8}(1,0,0)
@test convert(RGBA{Ufixed8}, ac) == RGBA{Ufixed8}(1,0,0,1)
@test convert(HSVA, ac) == HSVA{Float64}(convert(HSV, redF64), 1.0)
@test convert(HSVA{Float32}, ac) == HSVA{Float32}(convert(HSV{Float32}, redF64), 1.0f0)
@test convert(RGBA, redF64) == ac

@test convert(ARGB32, ac) == ARGB32(0xffff0000)
@test convert(Uint32, convert(ARGB32, ac)) == 0xffff0000
@test convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8)) == RGB24(0x00ff0000)
@test convert(Uint32, convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8))) == 0x00ff0000
redhsv = convert(HSV, redF64)
@test convert(RGB24, redhsv) == RGB24(0x00ff0000)

@test convert(RGB{Ufixed8}, red24) == RGB{Ufixed8}(1,0,0)
@test convert(RGBA{Ufixed8}, red32) == RGBA{Ufixed8}(1,0,0,1)
@test convert(HSVA{Float64}, red32) == HSVA{Float64}(360, 1, 1, 1)

if VERSION >= v"0.4.0-dev"
    @test_throws MethodError AlphaColor(RGB(1,0,0), 0xffuf8)
else
    @test_throws ErrorException AlphaColor(RGB(1,0,0), 0xffuf8)
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
full(T::OpaqueColor) = map(x->getfield(T, x), fieldnames(T)) #Allow test to access numeric elements
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
@test_approx_eq_eps DIN99o{Float64}(0.125,0.5,0.0)+DIN99o{Float64}(0.2,0.7,0.4) DIN99o{Float64}(0.3249177178200238,1.1851041291240045,0.39613501908850973) 91eps()
@test_approx_eq_eps 3DIN99o{Float64}(0.125,0.5,0.03) DIN99o{Float64}(0.3748457441768566,1.4684725814274917,0.08810835488564604) 91eps()

@test_approx_eq_eps DIN99{Float64}(0.125,0.5,0.0)+DIN99{Float64}(0.2,0.7,0.4) DIN99{Float64}(0.3247634199662825,1.1845967897238356,0.3960040943105819) 91eps()
@test_approx_eq_eps 3DIN99{Float64}(0.125,0.5,0.03) DIN99{Float64}(0.37455660462520735,1.467408770792347,0.08804452624754316) 91eps()

@test_approx_eq_eps HSL{Float64}(0.125,0.5,0.0)+HSL{Float64}(0.2,0.7,0.4) HSL{Float64}(0.20003618248898006,0.7000000631323785,0.39999995233870655) 91eps()
@test_approx_eq_eps 3HSL{Float64}(0.125,0.5,0.03) HSL{Float64}(0.17819347263565585,0.3941314428230695,0.07391855489379041) 91eps()

@test_approx_eq_eps HSV{Float64}(0.125,0.5,0.0)+HSV{Float64}(0.2,0.7,0.4) HSV{Float64}(0.20002334068804029,0.7000000071033119,0.3999999666630183) 91eps()
@test_approx_eq_eps 3HSV{Float64}(0.125,0.5,0.03) HSV{Float64}(0.15547682101166416,0.42727995497106286,0.07819689447804021) 91eps()

@test_approx_eq_eps LCHab{Float64}(0.125,0.5,0.0)+LCHab{Float64}(0.2,0.7,0.4) LCHab{Float64}(0.3249999999999993,1.1999928922680212,0.23333346495867205) 91eps()
@test_approx_eq_eps 3LCHab{Float64}(0.125,0.5,0.03) LCHab{Float64}(0.375,1.4999999999999816,0.03000000000047518) 91eps()

@test_approx_eq_eps LCHuv{Float64}(0.125,0.5,0.0)+LCHuv{Float64}(0.2,0.7,0.4) LCHuv{Float64}(0.32500000000000007,1.200147006104681,0.2329439337672688) 91eps()
@test_approx_eq_eps 3LCHuv{Float64}(0.125,0.5,0.03) LCHuv{Float64}(0.375,1.5000000000000007,0.03000000000000911) 91eps()

@test_approx_eq_eps LMS{Float64}(0.125,0.5,0.0)+LMS{Float64}(0.2,0.7,0.4) LMS{Float64}(0.32500000000000007,1.2000000000000002,0.4000000000000001) 91eps()
@test_approx_eq_eps 3LMS{Float64}(0.125,0.5,0.03) LMS{Float64}(0.37499999999999994,1.4999999999999998,0.09000000000000001) 91eps()

@test_approx_eq_eps Lab{Float64}(0.125,0.5,0.0)+Lab{Float64}(0.2,0.7,0.4) Lab{Float64}(0.3249999999999993,1.2000000000000066,0.40000000000000036) 91eps()
@test_approx_eq_eps 3Lab{Float64}(0.125,0.5,0.03) Lab{Float64}(0.375,1.4999999999999876,0.09000000000001229) 91eps()

@test_approx_eq_eps Luv{Float64}(0.125,0.5,0.0)+Luv{Float64}(0.2,0.7,0.4) Luv{Float64}(0.32500000000000007,1.2112171964760525,0.3551312140957904) 91eps()
@test_approx_eq_eps 3Luv{Float64}(0.125,0.5,0.03) Luv{Float64}(0.375,1.4999999999999998,0.09000000000000033) 91eps()

@test_approx_eq_eps XYZ{Float64}(0.125,0.5,0.0)+XYZ{Float64}(0.2,0.7,0.4) XYZ{Float64}(0.325,1.2,0.4) 91eps()
@test_approx_eq_eps 3XYZ{Float64}(0.125,0.5,0.03) XYZ{Float64}(0.375,1.5,0.09) 91eps()

@test_approx_eq_eps xyY{Float64}(0.125,0.5,0.0)+xyY{Float64}(0.2,0.7,0.4) xyY{Float64}(0.2,0.7,0.4) 91eps()
@test_approx_eq_eps 3xyY{Float64}(0.125,0.5,0.03) xyY{Float64}(0.125,0.5,0.09) 91eps()

#59
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 0.0, 0.0)) === (0.0, 0.0)
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 0.0)) === (0.0, 0.6)
@test Colors.xyz_to_uv(XYZ{Float64}(0.0, 1.0, 1.0)) === (0.0, 0.5)
@test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 1.0)) === (1.0, 0.0)
@test Colors.xyz_to_uv(XYZ{Float64}(1.0, 0.0, 0.0)) === (4.0, 0.0)

@test 1.0LCHuv(0.0, 0.0, 0.0) === LCHuv(0.0, 0.0, 0.0)

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
c = Gray{Ufixed16}(0.8)
@test convert(RGB, c) == RGB{Ufixed16}(0.8,0.8,0.8)
@test convert(RGB{Float32}, c) == RGB{Float32}(0.8,0.8,0.8)

# More AbstractRGB
r4 = RGB4(1,0,0)
@test convert(RGB, r4) == RGB(1,0,0)
@test convert(RGB{Ufixed8}, r4) == RGB{Ufixed8}(1,0,0)
@test convert(RGB4{Ufixed8}, r4) == RGB4{Ufixed8}(1,0,0)
@test convert(RGB4{Float32}, r4) == RGB4{Float32}(1,0,0)
@test convert(BGR{Float32}, r4) == BGR{Float32}(1,0,0)

# Test accuracy of conversion
csconv = jldopen("test_conversions.jld") do file
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
