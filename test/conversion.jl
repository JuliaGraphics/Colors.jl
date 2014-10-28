using Color, FixedPointNumbers
using Base.Test

const red = color("red")
const red24 = RGB24(0x00ff0000)
for T in (Float64, Float32, Ufixed8)
    c = RGB(one(T), zero(T), zero(T))
    @test eltype(c) == T
    c64 = convert(RGB{Float64}, c)
    @test typeof(c64) == RGB{Float64}
    @test c64 == red
    cr = convert(RGB{T}, red)
    @test cr == c
end
@test RGB(1,0,0) == red
@test RGB(uint8(1),0,0) == red
@test RGB(uint8(1),uint8(0),uint8(0)) == red
@test convert(RGB, red24) == red

for Cto in Color.CVparametric
    for Cfrom in Color.CVparametric
        for Tto in (Float32, Float64)
            for Tfrom in (Float32, Float64)
                c = convert(Cfrom{Tfrom}, red)
                @test typeof(c) == Cfrom{Tfrom}
                c1 = convert(Cto, c)
                @test eltype(c1) == Tfrom
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
    end
end
for Cto in Color.CVparametric
    @test typeof(convert(Cto, red24)) == Cto{Float64}
    @test typeof(convert(Cto{Float32}, red24)) == Cto{Float32}
end

# Test conversion from Ufixed types
for Cto in Color.CVfloatingpoint
    for Cfrom in Color.CVfractional
        for Tto in (Float32, Float64)
            for Tfrom in (Ufixed8, Ufixed10, Ufixed12, Ufixed14, Ufixed16)
                c = convert(Cfrom{Tfrom}, red)
                @test typeof(c) == Cfrom{Tfrom}
                c1 = convert(Cto, c)
                @test eltype(c1) == Float64
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
    end
end

# Test conversion to Ufixed types
for Cto in Color.CVfractional
    for Cfrom in Color.CVfloatingpoint
        for Tto in (Ufixed8, Ufixed10, Ufixed12, Ufixed14, Ufixed16)
            for Tfrom in (Float32, Float64)
                c = convert(Cfrom{Tfrom}, red)
                @test typeof(c) == Cfrom{Tfrom}
                c2 = convert(Cto{Tto}, c)
                @test typeof(c2) == Cto{Tto}
            end
        end
    end
end

ac = rgba(red)

@test convert(RGB, ac) == RGB(1,0,0)
@test convert(RGB{Ufixed8}, ac) == RGB{Ufixed8}(1,0,0)
@test convert(RGBA{Ufixed8}, ac) == RGBA{Ufixed8}(1,0,0,1)
@test convert(HSVA, ac) == HSVA{Float64}(convert(HSV, red), 1.0)
@test convert(HSVA{Float32}, ac) == HSVA{Float32}(convert(HSV{Float32}, red), 1.0f0)
@test convert(RGBA, red) == ac

@test convert(ARGB32, ac) == ARGB32(0xffff0000)
@test convert(Uint32, convert(ARGB32, ac)) == 0xffff0000
@test convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8)) == RGB24(0x00ff0000)
@test convert(Uint32, convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8))) == 0x00ff0000
redhsv = convert(HSV, red)
@test convert(RGB24, redhsv) == RGB24(0x00ff0000)

@test_throws MethodError AlphaColorValue(RGB(1,0,0), 0xffuf8)

# Test vector space operations
import Base.full
full(T::ColorValue) = map(x->getfield(T, x), names(T)) #Allow test to access numeric elements
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

@test_approx_eq_eps HSL{Float64}(0.125,0.5,0.0)+HSL{Float64}(0.2,0.7,0.4) HSL{Float64}(0.2000361824889771,0.7000000631323785,0.279999991890043) 91eps()
@test_approx_eq_eps 3HSL{Float64}(0.125,0.5,0.03) HSL{Float64}(0.17819347263565605,0.3941314428230693,0.029133626691685854) 91eps()

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

