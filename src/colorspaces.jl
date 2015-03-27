# Common Colorspaces
# ------------------

# The base type
abstract ColorValue{T}
typealias ColourValue{T} ColorValue{T}
abstract AbstractRGB{T} <: ColorValue{T} # allow different memory layouts of RGB
abstract AbstractAlphaColorValue{C <: ColorValue, T <: Real}  # allow different memory layouts of AlphaColorValues

eltype{T}(::ColorValue{T}) = T
eltype{T}(::Type{ColorValue{T}}) = T
eltype{CV<:ColorValue}(::Type{CV}) = eltype(super(CV))

# colortype is defined at the end of this file

# Transparency support
immutable AlphaColorValue{C <: ColorValue, T <: Fractional} <: AbstractAlphaColorValue{C, T}
    c::C
    alpha::T

    function AlphaColorValue(x1::Real, x2::Real, x3::Real, alpha::Real = 1.0)
        new(C(x1, x2, x3), alpha)
    end
    AlphaColorValue(c::ColorValue, alpha::Real) = new(c, alpha)
end
AlphaColorValue{T<:Fractional}(c::ColorValue{T}, alpha::T = one(T)) = AlphaColorValue{typeof(c),T}(c, alpha)

eltype{C<:ColorValue,T}(::AbstractAlphaColorValue{C,T}) = T
eltype{CV<:AbstractAlphaColorValue}(::Type{CV}) = _eltype(CV, super(CV))
_eltype{CV1<:AbstractAlphaColorValue, CV2<:AbstractAlphaColorValue}(::Type{CV1}, ::Type{CV2}) = _eltype(CV2, super(CV2)) 
_eltype{CV<:ColorValue,T}(::Type{AbstractAlphaColorValue{CV,T}}, ::Type{Any}) =  T

colortype{C}(::AbstractAlphaColorValue{C}) = colortype(C)
colortype{AC<:AbstractAlphaColorValue}(::Type{AC}) = _colortype(AC, super(AC))
_colortype{CV1<:AbstractAlphaColorValue, CV2<:AbstractAlphaColorValue}(::Type{CV1}, ::Type{CV2}) = _colortype(CV2, super(CV2))
_colortype{CV<:ColorValue,T}(::Type{AbstractAlphaColorValue{CV,T}}, ::Type{Any}) =  colortype(CV)

# sRGB (standard Red-Green-Blue)
immutable RGB{T<:Fractional} <: AbstractRGB{T}
    r::T # Red [0,1]
    g::T # Green [0,1]
    b::T # Blue [0,1]

    function RGB(r::Real, g::Real, b::Real)
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

    function HSV(h::Real, s::Real, v::Real)
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

    function HSL(h::Real, s::Real, l::Real)
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

    function XYZ(x::Real, y::Real, z::Real)
        new(x, y, z)
    end
end
XYZ{T<:Fractional}(x::T, y::T, z::T) = XYZ{T}(x, y, z)
XYZ(x, y, z) = (T = promote_type(typeof(x), typeof(y), typeof(z)); XYZ{T}(x, y, z))
XYZ(x::Integer, y::Integer, z::Integer) = XYZ{Float64}(x, y, z)
XYZ() = XYZ(0.0, 0.0, 0.0)

# CIE 1931 xyY (chromaticity + luminance) space
immutable xyY{T<:FloatingPoint} <: ColorValue{T}
    x::T
    y::T
    Y::T

    function xyY(x::Real, y::Real, Y::Real)
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

    function Lab(l::Real, a::Real, b::Real)
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

    function LCHab(l::Real, c::Real, h::Real)
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

    function Luv(l::Real, u::Real, v::Real)
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

    function LCHuv(l::Real, c::Real, h::Real)
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

    function DIN99(l::Real, a::Real, b::Real)
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

    function DIN99d(l::Real, a::Real, b::Real)
        new(l, a, b)
    end
end
DIN99d{T<:FloatingPoint}(l::T, a::T, b::T) = DIN99d{T}(l, a, b)
DIN99d(l, a, b) = DIN99d{Float64}(l, a, b)
DIN99d() = DIN99d(0.0, 0.0, 0.0)


# DIN99o (L99o, a99o, b99o) - adaptation of CIELAB
immutable DIN99o{T<:FloatingPoint} <: ColorValue{T}
    l::T # L99o
    a::T # a99o
    b::T # b99o

    function DIN99o(l::Real, a::Real, b::Real)
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

    function LMS(l::Real, m::Real, s::Real)
        new(l, m, s)
    end
end
LMS{T<:FloatingPoint}(l::T, m::T, s::T) = LMS{T}(l, m, s)
LMS(l, m, s) = LMS{Float64}(l, m, s)
LMS() = LMS(0.0, 0.0, 0.0)


# 24 bit RGB and 32 bit ARGB (used by Cairo)
# It would be nice to make this a subtype of AbstractRGB, but it doesn't have operations like c.r defined.
immutable RGB24 <: ColorValue{Uint8}
    color::Uint32
end
RGB24() = RGB24(0)
RGB24(r::Uint8, g::Uint8, b::Uint8) = RGB24(convert(UInt32, r)<<16 | convert(UInt32, g)<<8 | convert(UInt32, b))
RGB24(r::Ufixed8, g::Ufixed8, b::Ufixed8) = RGB24(reinterpret(r), reinterpret(g), reinterpret(b))

immutable ARGB32 <: AbstractAlphaColorValue{RGB24, Uint8}
    color::Uint32
end
ARGB32() = ARGB32(0)
ARGB32(r::Uint8, g::Uint8, b::Uint8, alpha::Uint8) = ARGB32(convert(UInt32, alpha)<<24 | convert(UInt32, r)<<16 | convert(UInt32, g)<<8 | convert(UInt32, b))
ARGB32(r::Ufixed8, g::Ufixed8, b::Ufixed8, alpha::Ufixed8) = ARGB32(reinterpret(r), reinterpret(g), reinterpret(b), reinterpret(alpha))

AlphaColorValue(c::RGB24, alpha::Uint8 = 0xff) = AlphaColorValue{typeof(c),Uint8}(c, alpha)

eltype(::RGB24) = Uint8
eltype(::Type{RGB24}) = Uint8
eltype(::ARGB32) = Uint8
eltype(::Type{ARGB32}) = Uint8

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

rgba{T}(c::ColorValue{T}) = AlphaColorValue(convert(RGB{T},c))
hsva{T}(c::ColorValue{T}) = AlphaColorValue(convert(HSV{T},c))
hsla{T}(c::ColorValue{T}) = AlphaColorValue(convert(HSL{T},c))
xyza{T}(c::ColorValue{T}) = AlphaColorValue(convert(XYZ{T},c))
xyYa{T}(c::ColorValue{T}) = AlphaColorValue(convert(xyY{T},c))
laba{T}(c::ColorValue{T}) = AlphaColorValue(convert(Lab{T},c))
lchaba{T}(c::ColorValue{T}) = AlphaColorValue(convert(LCHab{T},c))
luva{T}(c::ColorValue{T}) = AlphaColorValue(convert(Luv{T},c))
lchuva{T}(c::ColorValue{T}) = AlphaColorValue(convert(LCHuv{T},c))
din99a{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99{T},c))
din99da{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99d{T},c))
din99oa{T}(c::ColorValue{T}) = AlphaColorValue(convert(DIN99o{T},c))
lmsa{T}(c::ColorValue{T}) = AlphaColorValue(convert(LMS{T},c))
argb32{T}(c::ColorValue{T}) = ARGB32(convert(RGB24,c).color | 0xff000000)

const CVconcrete = (HSV, HSL, XYZ, xyY, Lab, Luv, LCHab, LCHuv, DIN99, DIN99d, DIN99o, LMS)
const CVparametric = tuple(RGB, CVconcrete...)
const CVfractional = (RGB, XYZ)
const CVfloatingpoint = (HSV, HSL, xyY, Lab, Luv, LCHab, LCHuv, DIN99, DIN99d, DIN99o, LMS)
const CVAlpha = (RGBA, HSVA, HSLA, XYZA, xyYA, LabA, LCHabA, LuvA, LCHuvA, DIN99A, DIN99dA, DIN99oA, LMSA)

for CV in CVparametric
    @eval begin
        colortype(::$CV) = $CV
        colortype(::Type{$CV}) = $CV
        colortype{T}(::Type{$CV{T}}) = $CV
    end
end

colortype(::Type{RGBA}) = RGB
colortype(::Type{HSVA}) = HSV
colortype(::Type{HSLA}) = HSL
colortype(::Type{XYZA}) = XYZ
colortype(::Type{xyYA}) = xyY
colortype(::Type{LabA}) = Lab
colortype(::Type{LCHabA}) = LCHab
colortype(::Type{LuvA}) = Luv
colortype(::Type{LCHuvA}) = LCHuv
colortype(::Type{DIN99A}) = DIN99
colortype(::Type{DIN99dA}) = DIN99d
colortype(::Type{DIN99oA}) = DIN99o
colortype(::Type{LMSA}) = LMS

# Vector space operations
import Base: +, *

#XYZ is a linear vector space
+{T<:Number}(a::XYZ{T}, b::XYZ{T}) = XYZ(a.x+b.x, a.y+b.y, a.z+b.z)
*(c::Number, a::XYZ) = XYZ(c*a.x, c*a.y, c*a.z)

#Most color spaces are nonlinear, so do the arithmetic in XYZ and convert back
+{T<:ColorValue}(a::T, b::T) = convert(T, convert(XYZ, a) + convert(XYZ, b))
*{T<:ColorValue}(c::Number, a::T) = convert(T, c * convert(XYZ, a))

