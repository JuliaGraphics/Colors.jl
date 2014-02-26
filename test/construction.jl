using Color
using Base.Test

c = color("red")
ac = RGBA(c)
@test convert(Uint32, convert(RGBA32, ac)) == 0xffff0000
