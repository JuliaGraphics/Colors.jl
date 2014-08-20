# Test ability to support different memory layouts
module ExtraColor

using Color
import Color.Fractional

immutable BGR{T<:Fractional} <: AbstractRGB{T}
    b::T
    g::T
    r::T

    BGR(r::Number, g::Number, b::Number) = new(b, g, r)
end
BGR(r::Integer, g::Integer, b::Integer) = BGR{Float64}(r, g, b)
BGR(r::Fractional, g::Fractional, b::Fractional) = (T = promote_type(typeof(r), typeof(g), typeof(b)); BGR{T}(r, g, b))

immutable ARGB{T<:Fractional} <: AbstractAlphaColorValue{RGB{T}, T}
    alpha::T
    c::RGB{T}
    
    ARGB(x1::T, x2::T, x3::T, alpha::T) = new(alpha, RGB{T}(x1, x2, x3))
    ARGB(c::RGB{T}, alpha::T) = new(alpha, c)
end
ARGB{T<:Fractional}(c::RGB{T}, alpha::T = one(T)) = ARGB{T}(c, alpha)

end

using Color

const redbgr = ExtraColor.BGR(1, 0, 0)
const redrgb = RGB(1, 0, 0)
@test convert(HSV, redbgr) == convert(HSV, redrgb)

ac = rgba(redrgb)
ac_argb = ExtraColor.ARGB(redrgb)
@test convert(Uint32, convert(ARGB32, ac)) == convert(Uint32, convert(ARGB32, ac_argb))

if ENDIAN_BOM == 0x04030201
    # little-endian
    const redbgr8 = ExtraColor.BGR(0xffuf8, 0x00uf8, 0x00uf8)
    acv = AlphaColorValue(redbgr8, 0xffuf8)
    @test convert(Uint32, argb32(redbgr8)) == reinterpret(Uint32, typeof(acv)[acv])[1]
end
