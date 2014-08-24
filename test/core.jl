using Color, FixedPointNumbers, Base.Test

const red = color("red")
const red24 = RGB24(0x00ff0000)

for CV in Color.CVparametric
    @test eltype(CV{Float32}) == Float32
    @test eltype(CV(1,0,0)) == Float64
end
for CV in (RGBA, HSVA, HSLA, XYZA, xyYA, LabA,
           LCHabA, LuvA, LCHuvA, DIN99A, DIN99dA, DIN99oA, LMSA)
    @test eltype(CV{Float32}) == Float32
end
for f in (rgba, hsva, hsla, xyza, xyYa, laba,
          lchaba, luva, lchuva, din99a, din99da, din99oa, lmsa)
    @test eltype(f(red)) == Float64
end
@test eltype(RGB24) == Uint8
@test eltype(ARGB32) == Uint8
