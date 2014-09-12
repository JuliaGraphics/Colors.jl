using Color, FixedPointNumbers, Base.Test

const red = color("red")
const red24 = RGB24(0x00ff0000)

for CV in Color.CVparametric
    @test eltype(CV{Float32}) == Float32
    @test eltype(CV(1,0,0)) == Float64
    @test colortype(CV(1,0,0)) == CV
    @test colortype(CV) == CV
    @test colortype(CV{Float32}) == CV
end
for (ACV,CV) in ((RGBA, RGB), (HSVA, HSV), (HSLA, HSL),
                 (XYZA, XYZ), (xyYA, xyY), (LabA, Lab),
                 (LCHabA, LCHab), (LuvA, Luv),
                 (LCHuvA, LCHuv), (DIN99A, DIN99),
                 (DIN99dA, DIN99d), (DIN99oA, DIN99o),
                 (LMSA, LMS))
    @test eltype(ACV{Float32}) == Float32
    @test colortype(ACV) == CV
    @test colortype(ACV{Float32}) == CV
    @test colortype(ACV{Float64}(1,0,0,1)) == CV
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
