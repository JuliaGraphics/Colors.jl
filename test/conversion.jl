using Color, FixedPoint
using Base.Test

const red = color("red")
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

for Cto in Color.CVparametric
    for Cfrom in Color.CVparametric
        for Tto in (Float32, Float64)
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
@test convert(Uint32, convert(RGBA32, ac)) == 0xffff0000
