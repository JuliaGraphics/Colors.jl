# Common Colorspaces
# ------------------

# The base type
abstract ColorValue
typealias ColourValue ColorValue


# Transparency support
immutable AlphaColorValue{T <: ColorValue}
    c::T
    alpha::Float64

    function AlphaColorValue(x1, x2, x3, alpha=1.0)
        new(T(x1, x2, x3), alpha)
    end
    AlphaColorValue(c::T, alpha=1.0) = new(c, alpha)
end


# sRGB (standard Red-Green-Blue)
immutable RGB <: ColorValue
    r::Float64 # Red in [0,1]
    g::Float64 # Green in [0,1]
    b::Float64 # Blue in [0,1]

    function RGB(r::Number, g::Number, b::Number)
        new(r, g, b)
    end

    RGB() = RGB(0, 0, 0)
end


# HSV (Hue-Saturation-Value)
immutable HSV <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    v::Float64 # Value in [0,1]

    function HSV(h::Number, s::Number, v::Number)
        new(h, s, v)
    end

    HSV() = HSV(0, 0, 0)
end


HSB(h, s, b) = HSV(h, s, b)


# HSL (Hue-Lightness-Saturation)
immutable HSL <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    l::Float64 # Lightness in [0,1]

    function HSL(h::Number, s::Number, l::Number)
        new(h, s, l)
    end

    HSL() = HSL(0, 0, 0)
end


HLS(h, l, s) = HSL(h, s, l)


# XYZ (CIE 1931)
immutable XYZ <: ColorValue
    x::Float64
    y::Float64
    z::Float64

    function XYZ(x::Number, y::Number, z::Number)
        new(x, y, z)
    end

    XYZ() = XYZ(0, 0, 0)
end


# LAB (CIELAB)
immutable LAB <: ColorValue
    l::Float64 # Luminance in approximately [0,100]
    a::Float64 # Red/Green
    b::Float64 # Blue/Yellow

    function LAB(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    LAB() = LAB(0, 0, 0)
end


# LCHab (Luminance-Chroma-Hue, Polar-LAB)
immutable LCHab <: ColorValue
    l::Float64 # Luminance in [0,100]
    c::Float64 # Chroma
    h::Float64 # Hue in [0,360]

    function LCHab(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHab() = LCHab(0, 0, 0)
end


# LUV (CIELUV)
immutable LUV <: ColorValue
    l::Float64 # Luminance
    u::Float64 # Red/Green
    v::Float64 # Blue/Yellow

    function LUV(l::Number, u::Number, v::Number)
        new(l, u, v)
    end

    LUV() = LUV(0, 0, 0)
end


# LCHuv (Luminance-Chroma-Hue, Polar-LUV)
immutable LCHuv <: ColorValue
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue

    function LCHuv(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHuv() = LCHuv(0, 0, 0)
end


# DIN99 (L99, a99, b99) - adaptation of CIELAB
immutable DIN99 <: ColorValue
    l::Float64 # L99
    a::Float64 # a99
    b::Float64 # b99

    function DIN99(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    DIN99() = DIN99(0, 0, 0)
end


# DIN99d (L99d, a99d, b99d) - Improvement on DIN99
immutable DIN99d <: ColorValue
    l::Float64 # L99d
    a::Float64 # a99d
    b::Float64 # b99d

    function DIN99d(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    DIN99d() = DIN99d(0, 0, 0)
end


# DIN99o (L99o, a99o, b99o) - adaptation of CIELAB
immutable DIN99o <: ColorValue
    l::Float64 # L99o
    a::Float64 # a99o
    b::Float64 # b99o

    function DIN99o(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    DIN99o() = DIN99o(0, 0, 0)
end


# LMS (Long Medium Short)
immutable LMS <: ColorValue
    l::Float64 # Long
    m::Float64 # Medium
    s::Float64 # Short

    function LMS(l::Number, m::Number, s::Number)
        new(l, m, s)
    end

    LMS() = LMS(0, 0, 0)
end


# 24 bit RGB (used by Cairo)
immutable RGB24 <: ColorValue
    color::Uint32

    RGB24(c::Unsigned) = new(c)
    RGB24() = RGB24(0)
end


# Versions with transparency
typealias RGBA AlphaColorValue{RGB}
typealias HSVA AlphaColorValue{HSV}
typealias HSLA AlphaColorValue{HSL}
typealias XYZA AlphaColorValue{XYZ}
typealias LABA AlphaColorValue{LAB}
typealias LCHabA AlphaColorValue{LCHab}
typealias LUVA AlphaColorValue{LUV}
typealias LCHuvA AlphaColorValue{LCHuv}
typealias DIN99A AlphaColorValue{DIN99}
typealias DIN99dA AlphaColorValue{DIN99d}
typealias DIN99oA AlphaColorValue{DIN99o}
typealias DIN99dA AlphaColorValue{DIN99d}
typealias LMSA AlphaColorValue{LMS}
typealias RGBA32 AlphaColorValue{RGB24}
