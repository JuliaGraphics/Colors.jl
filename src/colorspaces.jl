# Common Colorspaces
# ------------------

# The base type
abstract ColorValue{T}
typealias ColourValue{T} ColorValue{T}
abstract AbstractRGB{T} <: ColorValue{T} # allow different memory layouts of RGB

eltype{T}(::ColorValue{T}) = T

# Transparency support
abstract AbstractAlphaColorValue{C <: ColorValue, T <: Number}  # allow different memory layouts of AlphaColorValues
immutable AlphaColorValue{C <: ColorValue, T <: Number} <: AbstractAlphaColorValue{C, T}
    c::C
    alpha::T

    function AlphaColorValue(x1::T, x2::T, x3::T, alpha::T)
        new(C(x1, x2, x3), alpha)
    end
    AlphaColorValue(c::C, alpha::T) = new(c, alpha)
end
AlphaColorValue{T<:Fractional}(c::ColorValue{T}, alpha::T = one(T)) = AlphaColorValue{typeof(c),T}(c, alpha)

# sRGB (standard Red-Green-Blue)
immutable RGB{T<:Fractional} <: AbstractRGB{T}
    r::T # Red [0,1]
    g::T # Green [0,1]
    b::T # Blue [0,1]

    function RGB(r::Number, g::Number, b::Number)
        new(r, g, b)
    end

end
RGB{T<:Fractional}(r::T, g::T, b::T) = RGB{T}(r, g, b)
RGB(r, g, b) = (T = promote_type(typeof(r), typeof(g), typeof(b)); RGB{T}(r, g, b))
RGB(r::Integer, g::Integer, b::Integer) = RGB{Float64}(r, g, b)
RGB() = RGB(0.0, 0.0, 0.0)

typemin{T}(::Type{RGB{T}}) = RGB{T}(zero(T), zero(T), zero(T))
typemax{T}(::Type{RGB{T}}) = RGB{T}(one(T),  one(T),  one(T))

# HSV (Hue-Saturation-Value)
immutable HSV{T<:FloatingPoint} <: ColorValue{T}
    h::T # Hue in [0,360]
    s::T # Saturation in [0,1]
    v::T # Value in [0,1]

    function HSV(h::Number, s::Number, v::Number)
        new(h, s, v)
    end

end
HSV{T<:FloatingPoint}(h::T, s::T, v::T) = HSV{T}(h, s, v)
HSV(h, s, v) = HSV{Float64}(h, s, v)
HSV() = HSV(0.0, 0.0, 0.0)


HSB(h, s, b) = HSV(h, s, b)


# HSL (Hue-Lightness-Saturation)
immutable HSL{T<:FloatingPoint} <: ColorValue{T}
    h::T # Hue in [0,360]
    s::T # Saturation in [0,1]
    l::T # Lightness in [0,1]

    function HSL(h::Number, s::Number, l::Number)
        new(h, s, l)
    end
end
HSL{T<:FloatingPoint}(h::T, s::T, l::T) = HSL{T}(h, s, l)
HSL(h, s, l) = HSL{Float64}(h, s, l)
HSL() = HSL(0.0, 0.0, 0.0)


HLS(h, l, s) = HSL(h, s, l)


# XYZ (CIE 1931)
immutable XYZ{T<:Fractional} <: ColorValue{T}
    x::T
    y::T
    z::T

    function XYZ(x::Number, y::Number, z::Number)
        new(x, y, z)
    end
end
XYZ{T<:Fractional}(x::T, y::T, z::T) = XYZ{T}(x, y, z)
XYZ(x, y, z) = (T = promote_type(typeof(x), typeof(y), typeof(z)); XYZ{T}(x, y, z))
XYZ() = XYZ(0.0, 0.0, 0.0)

# CIE 1931 xyY (chromaticity + luminance) space
immutable xyY{T<:FloatingPoint} <: ColorValue{T}
    x::T
    y::T
    Y::T

    function xyY(x::Number, y::Number, Y::Number)
        new(x, y, Y)
    end
end
xyY{T<:FloatingPoint}(x::T, y::T, Y::T) = xyY{T}(x, y, Y)
xyY(x, y, Y) = xyY{Float64}(x, y, Y)
xyY() = xyY(0.0,0.0,0.0)


# Lab (CIELAB)
immutable Lab{T<:FloatingPoint} <: ColorValue{T}
    l::T # Luminance in approximately [0,100]
    a::T # Red/Green
    b::T # Blue/Yellow

    function Lab(l::Number, a::Number, b::Number)
        new(l, a, b)
    end
end
Lab{T<:FloatingPoint}(l::T, a::T, b::T) = Lab{T}(l, a, b)
Lab(l, a, b) = Lab{Float64}(l, a, b)
Lab() = Lab(0.0, 0.0, 0.0)

typealias LAB Lab


# LCHab (Luminance-Chroma-Hue, Polar-Lab)
immutable LCHab{T<:FloatingPoint} <: ColorValue{T}
    l::T # Luminance in [0,100]
    c::T # Chroma
    h::T # Hue in [0,360]

    function LCHab(l::Number, c::Number, h::Number)
        new(l, c, h)
    end
end
LCHab{T<:FloatingPoint}(l::T, c::T, h::T) = LCHab{T}(l, c, h)
LCHab(l, c, h) = LCHab{Float64}(l, c, h)
LCHab() = LCHab(0.0, 0.0, 0.0)


# Luv (CIELUV)
immutable Luv{T<:FloatingPoint} <: ColorValue{T}
    l::T # Luminance
    u::T # Red/Green
    v::T # Blue/Yellow

    function Luv(l::Number, u::Number, v::Number)
        new(l, u, v)
    end
end
Luv{T<:FloatingPoint}(l::T, u::T, v::T) = Luv{T}(l, u, v)
Luv(l, u, v) = Luv{Float64}(l, u, v)
Luv() = Luv(0.0, 0.0, 0.0)

typealias LUV Luv


# LCHuv (Luminance-Chroma-Hue, Polar-Luv)
immutable LCHuv{T<:FloatingPoint} <: ColorValue{T}
    l::T # Luminance
    c::T # Chroma
    h::T # Hue

    function LCHuv(l::Number, c::Number, h::Number)
        new(l, c, h)
    end
end
LCHuv{T<:FloatingPoint}(l::T, c::T, h::T) = LCHuv{T}(l, c, h)
LCHuv(l, c, h) = LCHuv{Float64}(l, c, h)
LCHuv() = LCHuv(0.0, 0.0, 0.0)


# DIN99 (L99, a99, b99) - adaptation of CIELAB
immutable DIN99{T<:FloatingPoint} <: ColorValue{T}
    l::T # L99
    a::T # a99
    b::T # b99

    function DIN99(l::Number, a::Number, b::Number)
        new(l, a, b)
    end
end
DIN99{T<:FloatingPoint}(l::T, a::T, b::T) = DIN99{T}(l, a, b)
DIN99(l, a, b) = DIN99{Float64}(l, a, b)
DIN99() = DIN99(0.0, 0.0, 0.0)


# DIN99d (L99d, a99d, b99d) - Improvement on DIN99
immutable DIN99d{T<:FloatingPoint} <: ColorValue{T}
    l::T # L99d
    a::T # a99d
    b::T # b99d

    function DIN99d(l::Number, a::Number, b::Number)
        new(l, a, b)
    end
end
DIN99d{T<:FloatingPoint}(l::T, a::T, b::T) = DIN99d{T}(l, a, b)
DIN99d(l, a, b) = DIN99{Float64}(l, a, b)
DIN99d() = DIN99d(0.0, 0.0, 0.0)


# DIN99o (L99o, a99o, b99o) - adaptation of CIELAB
immutable DIN99o{T<:FloatingPoint} <: ColorValue{T}
    l::T # L99o
    a::T # a99o
    b::T # b99o

    function DIN99o(l::Number, a::Number, b::Number)
        new(l, a, b)
    end
end
DIN99o{T<:FloatingPoint}(l::T, a::T, b::T) = DIN99o{T}(l, a, b)
DIN99o(l, a, b) = DIN99o{Float64}(l, a, b)
DIN99o() = DIN99o(0.0, 0.0, 0.0)


# LMS (Long Medium Short)
immutable LMS{T<:FloatingPoint} <: ColorValue{T}
    l::T # Long
    m::T # Medium
    s::T # Short

    function LMS(l::Number, m::Number, s::Number)
        new(l, m, s)
    end
end
LMS{T<:FloatingPoint}(l::T, m::T, s::T) = LMS{T}(l, m, s)
LMS(l, m, s) = LMS{Float64}(l, m, s)
LMS() = LMS(0.0, 0.0, 0.0)


# 24 bit RGB (used by Cairo)
immutable RGB24 <: ColorValue{Uint8}
    color::Uint32

    RGB24(c::Unsigned) = new(c)
    RGB24() = RGB24(0)
end

AlphaColorValue(c::RGB24, alpha::Uint8 = 0xff) = AlphaColorValue{typeof(c),Uint8}(c, alpha)

# Versions with transparency
typealias RGBA{T} AlphaColorValue{RGB{T},T}
typealias HSVA{T} AlphaColorValue{HSV{T},T}
typealias HSLA{T} AlphaColorValue{HSL{T},T}
typealias XYZA{T} AlphaColorValue{XYZ{T},T}
typealias xyYA{T} AlphaColorValue{xyY{T},T}
typealias LabA{T} AlphaColorValue{Lab{T},T}
typealias LCHabA{T} AlphaColorValue{LCHab{T},T}
typealias LuvA{T} AlphaColorValue{Luv{T},T}
typealias LCHuvA{T} AlphaColorValue{LCHuv{T},T}
typealias DIN99A{T} AlphaColorValue{DIN99{T},T}
typealias DIN99dA{T} AlphaColorValue{DIN99d{T},T}
typealias DIN99oA{T} AlphaColorValue{DIN99o{T},T}
typealias LMSA{T} AlphaColorValue{LMS{T},T}
typealias RGBA32 AlphaColorValue{RGB24,Uint8}

rgba{T}(c::ColorValue{T}) = AlphaColorValue(convert(RGB{T},c))
hsva{T}(c::ColorValue{T}) = AlphaColorValue(convert(HSV{T},c))
hsla{T}(c::ColorValue{T}) = AlphaColorValue(convert(HSL{T},c))
xyza{T}(c::ColorValue{T}) = AlphaColorValue(convert(XYZ{T},c))
xyYa{T}(c::ColorValue{T}) = AlphaColorValue(convert(xyY{T},c))
laba{T}(c::ColorValue{T}) = AlphaColorValue(convert(Lab{T},c))
lchaba{T}(c::ColorValue{T}) = AlphaColorValue(convert(LCH{T},c))
luva{T}(c::ColorValue{T}) = AlphaColorValue(convert(Luv{T},c))
lchuva{T}(c::ColorValue{T}) = AlphaColorValue(convert(LCHuv{T},c))
din99a{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99{T},c))
din99da{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99d{T},c))
din99oa{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99o{T},c))
lmsa{T}(c::ColorValue{T}) = AlphaColorValue(convert(LMS{T},c))
rgba32{T}(c::ColorValue{T}) = AlphaColorValue(convert(RGB24,c))

const CVconcrete = (HSV, HSL, XYZ, xyY, Lab, Luv, LCHab, LCHuv, DIN99, DIN99d, DIN99o, LMS)
const CVparametric = tuple(RGB, CVconcrete...)

for CV in CVparametric
    @eval eltype{T}(::Type{$CV{T}}) = T
end
