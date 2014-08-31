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

ac = rgba(red)
@test convert(ARGB32, ac) == ARGB32(0xffff0000)
@test convert(Uint32, convert(ARGB32, ac)) == 0xffff0000
@test convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8)) == RGB24(0x00ff0000)
@test convert(Uint32, convert(RGB24, RGB(0xffuf8,0x00uf8,0x00uf8))) == 0x00ff0000

@test_throws MethodError AlphaColorValue(RGB(1,0,0), 0xffuf8)
