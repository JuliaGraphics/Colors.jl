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

iob = IOBuffer()
c = RGB{Ufixed8}(0.32218,0.14983,0.87819)
show(iob, c)
@test takebuf_string(iob) == "RGB{Ufixed8}(0.322,0.149,0.878)"
c = RGB{Ufixed16}(0.32218,0.14983,0.87819)
show(iob, c)
@test takebuf_string(iob) == "RGB{Ufixed16}(0.32218,0.14983,0.87819)"
c = AlphaColorValue(RGB{Ufixed8}(0.32218,0.14983,0.87819),Ufixed8(0.99241))
show(iob, c)
@test takebuf_string(iob) == "RGBA{Ufixed8}(0.322,0.149,0.878,0.992)"
