module Color

import Base: convert, hex, isless, writemime, linspace
import Base.Graphics: set_source, set_source_rgb, GraphicsContext

export ColorValue, color,
       ColourValue, colour,
       AlphaColorValue,
       weighted_color_mean, hex,
       RGB, HSV, HSL, XYZ, LAB, LUV, LCHab, LCHuv, DIN99, LMS, RGB24,
       RGBA, HSVA, HSLA, XYZA, LABA, LUVA, LCHabA, LCHuvA, DIN99A, LMSA, RGBA32,
       protanopic, deuteranopic, tritanopic,
       cie_color_match, colordiff, colordiff_din99, distinguishable_colors,
       MSC, sequential_palette, diverging_palette, colormap


abstract ColorValue
typealias ColourValue ColorValue

immutable AlphaColorValue{T <: ColorValue}
    c::T
    alpha::Float64

    function AlphaColorValue(x1, x2, x3, alpha=1.0)
        new(T(x1, x2, x3), alpha)
    end
    AlphaColorValue(c::T, alpha=1.0) = new(c, alpha)
end

# Delete once 0.2 is no longer supported:
if !isdefined(:rad2deg)
  const rad2deg = radians2degrees
  const deg2rad = degrees2radians
end


# Common Colorspaces
# ------------------


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

immutable DIN99 <: ColorValue
    l::Float64 # L99
    a::Float64 # a99
    b::Float64 # b99

    function DIN99(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    DIN99() = DIN99(0, 0, 0)
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
typealias LMSA AlphaColorValue{LMS}
typealias RGBA32 AlphaColorValue{RGB24}

# Conversions
# -----------

# no-op conversions
for CV in (RGB, HSV, HSL, XYZ, LAB, LUV, LCHab, LCHuv, DIN99, LMS, RGB24)
    @eval begin
        convert(::Type{$CV}, c::$CV) = c
    end
end

function convert{T,U}(::Type{AlphaColorValue{T}}, c::AlphaColorValue{U})
    AlphaColorValue{T}(convert(T, c.c), c.alpha)
end

# Everything to RGB
# -----------------

function convert(::Type{RGB}, c::HSV)
    h = c.h / 60
    i = floor(h)
    f = h - i
    if int(i) & 1 == 0
        f = 1 - f
    end
    m = c.v * (1 - c.s)
    n = c.v * (1 - c.s * f)
    i = int(i)
    if i == 6 || i == 0; RGB(c.v, n, m)
    elseif i == 1;       RGB(n, c.v, m)
    elseif i == 2;       RGB(m, c.v, n)
    elseif i == 3;       RGB(m, n, c.v)
    elseif i == 4;       RGB(n, m, c.v)
    else;                RGB(c.v, m, n)
    end
end

function convert(::Type{RGB}, c::HSL)
    function qtrans(u::Float64, v::Float64, hue::Float64)
        if     hue > 360; hue -= 360
        elseif hue < 0;   hue += 360
        end

        if     hue < 60;  u + (v - u) * hue / 60
        elseif hue < 180; v
        elseif hue < 240; u + (v - u) * (240 - hue) / 60
        else;             u
        end
    end

    v = c.l <= 0.5 ? c.l * (1 + c.s) : c.l + c.s - (c.l * c.s)
    u = 2 * c.l - v

    if c.s == 0; RGB(c.l, c.l, c.l)
    else;        RGB(qtrans(u, v, c.h + 120),
                     qtrans(u, v, c.h),
                     qtrans(u, v, c.h - 120))
    end
end

const M_XYZ_RGB = [ 3.2404542 -1.5371385 -0.4985314
                   -0.9692660  1.8760108  0.0415560
                    0.0556434 -0.2040259  1.0572252 ]


function correct_gamut(c::RGB)
    RGB(min(1.0, max(0.0, c.r)),
        min(1.0, max(0.0, c.g)),
        min(1.0, max(0.0, c.b)))
end


function srgb_compand(v::Float64)
    v <= 0.0031308 ? 12.92v : 1.055v^(1/2.4) - 0.055
end

function convert(::Type{RGB}, c::XYZ)
    ans = M_XYZ_RGB * [c.x, c.y, c.z]
    correct_gamut(RGB(srgb_compand(ans[1]),
                      srgb_compand(ans[2]),
                      srgb_compand(ans[3])))
end

convert(::Type{RGB}, c::LAB)   = convert(RGB, convert(XYZ, c))
convert(::Type{RGB}, c::LCHab) = convert(RGB, convert(LAB, c))
convert(::Type{RGB}, c::LUV)   = convert(RGB, convert(XYZ, c))
convert(::Type{RGB}, c::LCHuv) = convert(RGB, convert(LUV, c))
convert(::Type{RGB}, c::DIN99) = convert(RGB, convert(XYZ, c))
convert(::Type{RGB}, c::LMS)   = convert(RGB, convert(XYZ, c))

convert(::Type{RGB}, c::RGB24) = RGB((c.color&0x00ff0000>>>16)/255, ((c.color&0x0000ff00)>>>8)/255, (c.color&0x000000ff)/255)

# Everything to HSV
# -----------------

function convert(::Type{HSV}, c::RGB)
    c_min = min([c.r, c.g, c.b])
    c_max = max([c.r, c.g, c.b])
    if c_min == c_max
        return HSV(0.0, 0.0, c_max)
    end

    if c_min == c.r
        f = c.g - c.b
        i = 3.
    elseif c_min == c.g
        f = c.b - c.r
        i = 5.
    else
        f = c.r - c.g
        i = 1.
    end

    HSV(60 * (i - f / (c_max - c_min)),
        (c_max - c_min) / c_max,
        c_max)
end


convert(::Type{HSV}, c::ColorValue) = convert(HSV, convert(RGB, c))


# Everything to HSL
# -----------------

function convert(::Type{HSL}, c::RGB)
    c_min = min(c.r, c.g, c.b)
    c_max = max(c.r, c.g, c.b)
    l = (c_max - c_min) / 2

    if c_max == c_min
        return HSL(0.0, 0.0, l)
    end

    if l < 0.5; s = (c_max - c_min) / (c_max + c_min)
    else;       s = (c_max - c_min) / (2.0 - c_max - c_min)
    end

    if c_max == c.r
        h = (c.g - c.b) / (c_max - c_min)
    elseif c_max == c.g
        h = 2.0 + (c.b - c.r) / (c_max - c_min)
    else
        h = 4.0 + (c.r - c.g) / (c_max - c_min)
    end

    h *= 60
    if h < 0
        h += 360
    elseif h > 360
        h -= 360
    end

    HSL(h,s,l)
end


convert(::Type{HSL}, c::ColorValue) = convert(HSL, convert(RGB, c))


# Everything to XYZ
# -----------------

function invert_rgb_compand(v::Float64)
    v <= 0.04045 ? v/12.92 : ((v+0.055) /1.055)^2.4
end

const M_RGB_XYZ =
    [ 0.4124564  0.3575761  0.1804375
      0.2126729  0.7151522  0.0721750
      0.0193339  0.1191920  0.9503041 ]

function convert(::Type{XYZ}, c::RGB)
    v = [invert_rgb_compand(c.r),
         invert_rgb_compand(c.g),
         invert_rgb_compand(c.b)]
    ans = M_RGB_XYZ * v
    XYZ(ans[1], ans[2], ans[3])
end

convert(::Type{XYZ}, c::HSV) = convert(XYZ, convert(RGB, c))
convert(::Type{XYZ}, c::HSL) = convert(XYZ, convert(RGB, c))

const xyz_epsilon = 216. / 24389.
const xyz_kappa   = 24389. / 27.

function convert(::Type{XYZ}, c::LAB, wp::XYZ)
    fy = (c.l + 16) / 116
    fx = c.a / 500 + fy
    fz = fy - c.b / 200

    fx3 = fx^3
    fz3 = fz^3

    x = fx3 > xyz_epsilon ? fx3 : (116fx - 16) / xyz_kappa
    y = c.l > xyz_kappa * xyz_epsilon ? ((c. l+ 16) / 116)^3 : c.l / xyz_kappa
    z = fz3 > xyz_epsilon ? fz3 : (116fz - 16) / xyz_kappa

    XYZ(x*wp.x, y*wp.y, z*wp.z)
end

convert(::Type{XYZ}, c::LAB)   = convert(XYZ, c, WP_DEFAULT)
convert(::Type{XYZ}, c::LCHab) = convert(XYZ, convert(LAB, c))
convert(::Type{XYZ}, c::DIN99) = convert(XYZ, convert(LAB, c))

function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    u = (4. * c.x) / d
    v = (9. * c.y) / d
    return (u,v)
end

function convert(::Type{XYZ}, c::LUV, wp::XYZ)
    (u_wp, v_wp) = xyz_to_uv(wp)

    a = (52 * c.l / (c.u + 13 * c.l * u_wp) - 1) / 3
    y = c.l > xyz_kappa * xyz_epsilon ? ((c.l + 16) / 116)^3 : c.l / xyz_kappa
    b = -5y
    d = y * (39 * c.l / (c.v + 13 * c.l * v_wp) - 5)
    x = (d - b) / (a + (1./3.))
    z = a * x + b

    XYZ(x, y, z)
end

convert(::Type{XYZ}, c::LUV)   = convert(XYZ, c, WP_DEFAULT)
convert(::Type{XYZ}, c::LCHuv) = convert(XYZ, convert(LUV, c))

function convert(::Type{XYZ}, c::LMS)
    ans = CAT02_INV * [c.l, c.m, c.s]
    XYZ(ans[1], ans[2], ans[3])
end


# Everything to LAB
# -----------------

convert(::Type{LAB}, c::RGB) = convert(LAB, convert(XYZ, c))
convert(::Type{LAB}, c::HSV) = convert(LAB, convert(RGB, c))
convert(::Type{LAB}, c::HSL) = convert(LAB, convert(RGB, c))

function convert(::Type{LAB}, c::XYZ, wp::XYZ)
    function f(v::Float64)
        v > xyz_epsilon ? cbrt(v) : (xyz_kappa * v + 16) / 116
    end

    fx, fy, fz = f(c.x / wp.x), f(c.y / wp.y), f(c.z / wp.z)
    LAB(116fy - 16, 500(fx - fy), 200(fy - fz))
end

convert(::Type{LAB}, c::XYZ) = convert(LAB, c, WP_DEFAULT)

function convert(::Type{LAB}, c::LCHab)
    hr = deg2rad(c.h)
    LAB(c.l, c.c * cos(hr), c.c * sin(hr))
end

function convert(::Type{LAB}, c::DIN99)

    # FIXME: right now we assume the adjustment parameters are always 1.
    kch = 1
    ke = 1

    # Calculate Chroma (C99) in the DIN99 space
    cc = sqrt(c.a^2 + c.b^2)

    # NOTE: This is calculated in degrees, against the standard, to save
    # computation steps later.
    if (c.a > 0 && c.b >= 0)
        h = atand(c.b/c.a)
    elseif (c.a == 0 && c.b > 0)
        h = 90
    elseif (c.a < 0)
        h = 180+atand(c.b/c.a)
    elseif (c.a == 0 && c.b < 0)
        h = 270
    elseif (c.a > 0 && c.b <= 0)
        h = 360 + atand(c.b/c.a)
    else
        h = 0
    end

    # Temporary variable for chroma
    g = (e^(0.045*cc*kch*ke)-1)/0.045

    # Temporary redness
    ee = g*cosd(h)

    # Temporary yellowness
    f = g*sind(h)

    # CIELAB a*b*
    # FIXME: hard-code the constants.
    ciea = ee*cosd(16) - (f/0.7)*sind(16)
    cieb = ee*sind(16) + (f/0.7)*cosd(16)

    # CIELAB L*
    ciel = (e^(c.l*ke/105.51)-1)/0.0158

    LAB(ciel, ciea, cieb)
end

convert(::Type{LAB}, c::ColorValue) = convert(LAB, convert(XYZ, c))


# Everything to LUV
# -----------------

convert(::Type{LUV}, c::RGB) = convert(LUV, convert(XYZ, c))
convert(::Type{LUV}, c::HSV) = convert(LUV, convert(RGB, c))
convert(::Type{LUV}, c::HSL) = convert(LUV, convert(RGB, c))

function convert(::Type{LUV}, c::XYZ, wp::XYZ)
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y

    l = y > xyz_epsilon ? 116 * cbrt(y) - 16 : xyz_kappa * y
    u = 13 * l * (u_ - u_wp)
    v = 13 * l * (v_ - v_wp)

    LUV(l, u, v)
end

convert(::Type{LUV}, c::XYZ) = convert(LUV, c, WP_DEFAULT)

function convert(::Type{LUV}, c::LCHuv)
    hr = deg2rad(c.h)
    LUV(c.l, c.c * cos(hr), c.c * sin(hr))
end

convert(::Type{LUV}, c::ColorValue) = convert(LUV, convert(XYZ, c))


# Everything to LCHuv
# -------------------

function convert(::Type{LCHuv}, c::LUV)
    h = rad2deg(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv(c.l, sqrt(c.u^2 + c.v^2), h)
end

convert(::Type{LCHuv}, c::ColorValue) = convert(LCHuv, convert(LUV, c))


# Everything to LCHab
# -------------------

function convert(::Type{LCHab}, c::LAB)
    h = rad2deg(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab(c.l, sqrt(c.a^2 + c.b^2), h)
end

convert(::Type{LCHab}, c::ColorValue) = convert(LCHab, convert(LAB, c))


# Everything to DIN99
# -------------------

function convert(::Type{DIN99}, c::LAB)
    # FIXME: right now we assume the adjustment parameters are always 1.
    kch = 1
    ke = 1

    # Calculate DIN99 L
    l99 = (1/ke)*105.51*log(1+0.0158*c.l)

    # Temporary value for redness and yellowness
    # FIXME: hard-code the constants
    ee = c.a*cosd(16) + c.b*sind(16)
    f = -0.7*c.a*sind(16) + 0.7*c.b*cosd(16)

    # Temporary value for chroma
    g = sqrt(ee^2 + f^2)

    # Hue angle
    # Calculated in degrees, against the specification.
    if (ee > 0 && f >= 0)
        h = atand(f/ee)
    elseif (ee == 0 && f > 0)
        h = 90
    elseif (ee < 0)
        h = 180+atand(f/ee)
    elseif (ee == 0 && f < 0)
        h = 270
    elseif (ee > 0 && f <= 0)
        h = 360 + atand(f/ee)
    else
        h = 0
    end

    # DIN99 chroma
    cc = log(1+0.045*g)/(0.045*kch*ke)

    # DIN99 chromaticities
    a99, b99 = cc*cosd(h), cc*sind(h)

    DIN99(l99, a99, b99)

end

convert(::Type{DIN99}, c::ColorValue) = convert(DIN99, convert(LAB, c))


# Everything to LMS
# -----------------

# Chromatic adaptation from CIECAM97s
const CAT97s = [ 0.8562  0.3372 -0.1934
                -0.8360  1.8327  0.0033
                 0.0357 -0.0469  1.0112 ]

const CAT97s_INV = inv(CAT97s)

# Chromatic adaptation from CIECAM02
const CAT02 = [ 0.7328 0.4296 -0.1624
               -0.7036 1.6975  0.0061
                0.0030 0.0136  0.9834 ]

const CAT02_INV = inv(CAT02)

function convert(::Type{LMS}, c::XYZ)
    ans = CAT02 * [c.x, c.y, c.z]
    LMS(ans[1], ans[2], ans[3])
end

convert(::Type{LMS}, c::ColorValue) = convert(LMS, convert(XYZ, c))


# Everything to RGB24
# -------------------

convert(::Type{RGB24}, c::RGB) = RGB24(iround(Uint32, 255*c.r)<<16 +
    iround(Uint32, 255*c.g)<<8 + iround(Uint32, 255*c.b))

convert(::Type{RGB24}, c::ColorValue) = convert(RGB24, convert(RGB, c))


# To Uint32
# ----------------

convert(::Type{Uint32}, c::RGB24) = c.color

convert(::Type{Uint32}, ac::RGBA32) = convert(Uint32, ac.c) | iround(Uint32, 255*ac.alpha)<<24


# Miscellaneous
# -------------

# An arbitrary ordering for unique sorting.
isless(a::RGB, b::RGB) = (a.r, a.g, a.b) < (b.r, b.g, b.b)
isless(a::ColorValue, b::ColorValue) = convert(RGB, a) < convert(RGB, b)


# Linear-interpolation in [a, b] where x is in [0,1],
# or coerced to be if not.
function lerp(x::Float64, a::Float64, b::Float64)
    a + (b - a) * max(min(x, 1.0), 0.0)
end


# Print a color as a RGB hex triple.
function hex(c::RGB)
    @sprintf("%02X%02X%02X",
             int(lerp(c.r, 0.0, 255.0)),
             int(lerp(c.g, 0.0, 255.0)),
             int(lerp(c.b, 0.0, 255.0)))
end

hex(c::ColorValue) = hex(convert(RGB, c))

# set source color as a ColorValue
function set_source(gc::GraphicsContext, c::ColorValue)
    rgb = convert(RGB, c)
    set_source_rgb(gc, rgb.r, rgb.g, rgb.b)
end

# CIE Color Matching
# ------------------

include("cie_color_matching.jl")

# Evaluate the CIE standard observer color match function.
#
# Args:
#   wavelen: Wavelength of stimulus in nanometers.
#
# Returns:
#   XYZ value of perceived color.
#
function cie_color_match(wavelen::Real)
    a = floor(wavelen)
    ac = 380 <= a <= 780 ? cie_color_match_table[a - 380 + 1,:] : [0,0,0]

    if wavelen != a
        b = ceil(wavelen)
        bc = 380 <= b <= 780 ? cie_color_match_table[b - 380 + 1,:] : [0,0,0]
        p = wavelen - a
        ac = p * bc + (1.0 - p) * ac
    end
    XYZ(ac[1], ac[2], ac[3])
end


# CIE Standard white-points
# -------------------------

const WP_A   = XYZ(1.09850, 1.00000, 0.35585)
const WP_B   = XYZ(0.99072, 1.00000, 0.85223)
const WP_C   = XYZ(0.98074, 1.00000, 1.18232)
const WP_D50 = XYZ(0.96422, 1.00000, 0.82521)
const WP_D55 = XYZ(0.95682, 1.00000, 0.92149)
const WP_D65 = XYZ(0.95047, 1.00000, 1.08883)
const WP_D75 = XYZ(0.94972, 1.00000, 1.22638)
const WP_E   = XYZ(1.00000, 1.00000, 1.00000)
const WP_F2  = XYZ(0.99186, 1.00000, 0.67393)
const WP_F7  = XYZ(0.95041, 1.00000, 1.08747)
const WP_F11 = XYZ(1.00962, 1.00000, 0.64350)
const WP_DEFAULT = WP_D65


# Chromatic Adaptation / Whitebalancing
# -------------------------------------

# Whitebalance a color.
#
# Input a source (adopted) and destination (reference) white. E.g., if you have
# a photo taken under florencent lighting that you then want to appear correct
# under regular sunlight, you might do something like
# `whitebalance(c, WP_F2, WP_D65)`.
#
# Args:
#   c: An observed color.
#   src_white: Adopted or source white.
#   ref_white: Reference or destination white.
#
# Returns:
#   A whitebalanced color.
#
function whitebalance{T <: ColorValue}(c::T, src_white::ColorValue, ref_white::ColorValue)
    c_lms = convert(LMS, c)
    src_lms = convert(LMS, src_white)
    dest_lms = convert(LMS, dest_white)

    # This is sort of simplistic, it set's the degree of adaptation term in
    # CAT02 to 0.
    ans = LMS(c.l * dest_wp.l / src_wp.l,
              c.m * dest_wp.m / src_wp.m,
              c.s * dest_wp.s / src_wp.s)

    convert(T, ans)
end


# Simulation of Colorblindness
# ----------------------------

# This method is due to:
# Brettel, H., Viénot, F., & Mollon, J. D. (1997).  Computerized simulation of
# color appearance for dichromats. Josa A, 14(10), 2647–2655.
#
# These functions add to Brettel's method a parameter p in [0, 1] giving the
# degree of photopigment loss. At p = 1, the complete loss of a particular
# photopigment is simulated, where 0 < p < 1 represents partial loss.


# This is supposed to be "the brightest possible metamer of an equal-energy
# stimulus". I'm punting a bit and just calling that RGB white.
const default_brettel_neutral = convert(LMS, RGB(1, 1, 1))


# Helper function for Brettel conversions.
function brettel_abc(neutral::LMS, anchor::LMS)
    a = neutral.m * anchor.s - neutral.s * anchor.m
    b = neutral.s * anchor.l - neutral.l * anchor.s
    c = neutral.l * anchor.m - neutral.m * anchor.l
    (a, b, c)
end


# Convert a color to simulate protanopic color blindness (lack of the
# long-wavelength photopigment).
function protanopic{T <: ColorValue}(q::T, p::Float64, neutral::LMS)
    q = convert(LMS, q)
    anchor_wavelen = q.s / q.m < neutral.s / neutral.m ? 575 : 475
    anchor = cie_color_match(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS((1.0 - p) * q.l + p * (-(b*q.m + c*q.s)/a),
            q.m,
            q.s)
    convert(T, q)
end


# Convert a color to simulate deuteranopic color blindness (lack of the
# middle-wavelength photopigment.)
function deuteranopic{T <: ColorValue}(q::T, p::Float64, neutral::LMS)
    q = convert(LMS, q)
    anchor_wavelen = q.s / q.l < neutral.s / neutral.l ? 575 : 475
    anchor = cie_color_match(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS(q.l,
            (1.0 - p) * q.m + p * (-(a*q.l + c*q.s)/b),
            q.s)
    convert(T, q)
end


# Convert a color to simulato tritanopic color blindness (lack of the
# short-wavelength photogiment)
function tritanopic{T <: ColorValue}(q::T, p::Float64, neutral::LMS)
    q = convert(LMS, q)
    anchor_wavelen = q.m / q.l < neutral.m / neutral.l ? 660 : 485
    anchor = cie_color_match(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS(q.l,
            q.m,
            (1.0 - p) * q.l + p * (-(a*q.l + b*q.m)/c))
    convert(T, q)
end


protanopic(c::ColorValue, p::Float64)   = protanopic(c, p, default_brettel_neutral)
deuteranopic(c::ColorValue, p::Float64) = deuteranopic(c, p, default_brettel_neutral)
tritanopic(c::ColorValue, p::Float64)   = tritanopic(c, p, default_brettel_neutral)

protanopic(c::ColorValue)   = protanopic(c, 1.0)
deuteranopic(c::ColorValue) = deuteranopic(c, 1.0)
tritanopic(c::ColorValue)   = tritanopic(c, 1.0)


# Color Parsing
# -------------

include("color_names.jl")

const col_pat_hex1 = r"(#|0x)([[:xdigit:]])([[:xdigit:]])([[:xdigit:]])"
const col_pat_hex2 = r"(#|0x)([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})"
const col_pat_rgb  = r"rgb\((\d+%?),(\d+%?),(\d+%?)\)"
const col_pat_hsl  = r"hsl\((\d+%?),(\d+%?),(\d+%?)\)"

# Parse a number used in the "rgb()" or "hsl()" color.
function parse_rgb_hsl_num(num::String)
    if num[end] == '%'
        return parseint(num[1:end-1], 10) / 100
    else
        return parseint(num, 10) / 255
    end
end


# Parse a color description.
#
# This parses subset of HTML/CSS color specifications. In particular, everything
# is supported but: "hsla()", "rgba()" (since there is no notion of transparency
# in this library) "currentColor", and "transparent".
#
# It does support named colors (though it uses X11 named colors, which are
# slightly different than W3C named colors in some cases), "rgb()", "hsl()",
# "#RGB", and "#RRGGBB' syntax.
#
# Args:
#   desc: A color name or description.
#
# Returns:
#   An RGB color, unless "hsl()" was used, in which case an HSL color.
#
function color(desc::String)
    desc_ = replace(desc, " ", "")
    mat = match(col_pat_hex2, desc_)
    if mat != nothing
        return RGB(parseint(mat.captures[2], 16) / 255,
                   parseint(mat.captures[3], 16) / 255,
                   parseint(mat.captures[4], 16) / 255)
    end

    mat = match(col_pat_hex1, desc_)
    if mat != nothing
        return RGB((16 * parseint(mat.captures[2], 16)) / 255,
                   (16 * parseint(mat.captures[3], 16)) / 255,
                   (16 * parseint(mat.captures[4], 16)) / 255)
    end

    mat = match(col_pat_rgb, desc_)
    if mat != nothing
        return RGB(parse_rgb_hsl_num(mat.captures[1]),
                   parse_rgb_hsl_num(mat.captures[2]),
                   parse_rgb_hsl_num(mat.captures[3]))
    end

    mat = match(col_pat_hsl, desc_)
    if mat != nothing
        return HSL(parse_rgb_hsl_num(mat.captures[1]),
                   parse_rgb_hsl_num(mat.captures[2]),
                   parse_rgb_hsl_num(mat.captures[3]))
    end

    desc_ = lowercase(desc_)
    if !haskey(color_names, desc_)
        error("Unknown color: ", desc)
    end

    c = color_names[desc_]
    return RGB(c[1] / 255, c[2] / 255, c[3] / 255)
end


color(c::ColorValue) = c


# Color Difference Metrics
# ------------------------

# Evaluate the CIEDE2000 color difference formula, implemented according to:
#   Klaus Witt, CIE Color Difference Metrics, Colorimetry: Understanding the CIE
#   System. 2007
#
# Args:
#   a, b: Any two colors.
#
# Returns:
#   The CIEDE2000 color difference metric evaluated between a and b.
#
function colordiff(ai::ColorValue, bi::ColorValue)
    a = convert(LAB, ai)
    b = convert(LAB, bi)

    ac, bc = sqrt(a.a^2 + a.b^2), sqrt(b.a^2 + b.b^2)
    mc = (ac + bc)/2
    g = (1 - sqrt(mc^7 / (mc^7 + 25^7))) / 2
    a = LAB(a.l, a.a * (1 + g), a.b)
    b = LAB(b.l, b.a * (1 + g), b.b)

    a = convert(LCHab, a)
    b = convert(LCHab, b)

    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    ml, mc = (a.l + b.l) / 2, (a.c + b.c) / 2
    if a.c * b.c == 0
        mh = a.h + b.h
    elseif abs(b.h - a.h) > 180
        if a.h + b.h < 360
            mh = (a.h + b.h + 360) / 2
        else
            mh = (a.h + b.h - 360) / 2
        end
    else
        mh = (a.h + b.h) / 2
    end

    # lightness weight
    mls = (ml - 50)^2
    sl = 1.0 + 0.015 * mls / sqrt(20 + mls)

    # chroma weight
    sc = 1 + 0.045mc

    # hue weight
    t = 1 - 0.17 * cosd(mh - 30) +
            0.24 * cosd(2mh) +
            0.32 * cosd(3mh + 6) -
            0.20 * cosd(4mh - 63)
    sh = 1 + 0.015 * mc * t

    # rotation term
    dtheta = 30 * exp(-((mh - 275)/25)^2)
    cr = 2 * sqrt(mc^7 / (mc^7 + 25^7))
    tr = -sind(2*dtheta) * cr

    sqrt((dl/sl)^2 + (dc/sc)^2 + (dh/sh)^2 +
         tr * (dc/sc) * (dh/sh))
end

# Evaluate the DIN99 color difference formula, implemented according to the
# DIN 6176 specification.
#
# Args:
#   a, b: Any two colors.
#
# Returns:
#   The DIN99 color difference metric evaluated between a and b.
function colordiff_din99(ai::ColorValue, bi::ColorValue)

    a = convert(DIN99, ai)
    b = convert(DIN99, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# Color Scale Generation
# ----------------------

# Generate n maximally distinguishable colors.
#
# This uses a greedy brute-force approach to choose n colors that are maximally
# distinguishable. Given seed color(s), and a set of possible hue, chroma, and
# lightness values (in LCHab space), it repeatedly chooses the next color as the
# one that maximizes the minimum pairwise distance to any of the colors already
# in the palette.
#
# Args:
#   n: Number of colors to generate.
#   seed: Initial color(s) included in the palette.
#   transform: Transform applied to colors before measuring distance.
#   lchoices: Possible lightness values.
#   cchoices: Possible chroma values.
#   hchoices: Possible hue values.
#
# Returns:
#   A Vector{ColorValue} of length n.
#
function distinguishable_colors{T<:ColorValue}(n::Integer,
                            seed::Vector{T};
                            transform::Function = identity,
                            lchoices::Vector{Float64} = linspace(0, 100, 15),
                            cchoices::Vector{Float64} = linspace(0, 100, 15),
                            hchoices::Vector{Float64} = linspace(0, 340, 20))
    if n <= length(seed)
        return seed[1:n]
    end

    # Candidate colors
    N = length(lchoices)*length(cchoices)*length(hchoices)
    candidate = Array(T, N)
    j = 0
    for h in hchoices, c in cchoices, l in lchoices
        candidate[j+=1] = LCHab(l, c, h)
    end

    # Transformed colors
    tc = transform(candidate[1])
    candidate_t = Array(typeof(tc), N)
    candidate_t[1] = tc
    for i = 2:N
        candidate_t[i] = transform(candidate[i])
    end

    # Start with the seed colors
    colors = Array(T, n)
    copy!(colors, seed)

    # Minimum distances of the current color to each previously selected color.
    ds = infs(Float64, N)
    for i = 1:length(seed)
        ts = transform(seed[i])
        for k = 1:N
            ds[k] = min(ds[k], colordiff(ts, candidate_t[k]))
        end
    end

    for i in length(seed)+1:n
        j = indmax(ds)
        colors[i] = candidate[j]
        tc = candidate_t[j]
        for k = 1:N
            d = colordiff(tc, candidate_t[k])
            ds[k] = min(ds[k], d)
        end
    end

    colors
end

distinguishable_colors(n::Integer, seed::ColorValue; kwargs...) = distinguishable_colors(n, [seed]; kwargs...)
distinguishable_colors(n::Integer; kwargs...) = distinguishable_colors(n, Array(RGB,0); kwargs...)

@deprecate distinguishable_colors(n::Integer,
                                transform::Function,
                                seed::ColorValue,
                                ls::Vector{Float64},
                                cs::Vector{Float64},
                                hs::Vector{Float64})    distinguishable_colors(n, [seed], transform = transform, lchoices = ls, cchoices = cs, hchoices = hs)


# Color ramp generation
# ---------------------

# weighted_color_mean(w1, c1, c2) gives a mean color "w1*c1 + (1-w1)*c2".
for (T,a,b,c) in ((:RGB,:r,:g,:b), (:HSV,:h,:s,:v), (:HSL,:h,:s,:l),
                  (:XYZ,:x,:y,:z), (:LAB,:l,:a,:b), (:LCHab,:l,:c,:h),
                  (:LUV,:l,:u,:v), (:LCHuv,:l,:c,:h), (:LMS,:l,:m,:s))
    @eval weighted_color_mean(w1::Real, c1::$T, c2::$T) =
      let w2 = w1 >= 0 && w1 <= 1 ? 1 - w1 : throw(DomainError())
          $T(c1.($(Expr(:quote, a))) * w1 + c2.($(Expr(:quote, a))) * w2,
             c1.($(Expr(:quote, b))) * w1 + c2.($(Expr(:quote, b))) * w2,
             c1.($(Expr(:quote, c))) * w1 + c2.($(Expr(:quote, c))) * w2)
      end
end
weighted_color_mean(w1::Real, c1::RGB24, c2::RGB24) =
    convert(RGB24, weighted_color_mean(w1, convert(RGB, c1), convert(RGB, c2)))

# return a linear ramp of n colors from c1 to c2, inclusive
function linspace{T<:ColorValue}(c1::T, c2::T, n=100)
    a = Array(T, int(n))
    if n == 1
        a[1] = c1
        return a
    end
    n -= 1
    for i = 0:n
        a[i+1] = weighted_color_mean((n-i)/n, c1, c2)
    end
    a
end



# Colormaps & related functions
# ---------------------


# MSC - Most Saturated Color for given hue h
# ---------------------
# Calculates the most saturated color for any given hue by
# finding the corresponding corner in LCHuv space

function MSC(h)

    #Corners of RGB cube
    const h0 = 12.173988685914473 #convert(LCHuv,RGB(1,0,0)).h
    const h1 = 85.872748860776770 #convert(LCHuv,RGB(1,1,0)).h
    const h2 = 127.72355046632740 #convert(LCHuv,RGB(0,1,0)).h
    const h3 = 192.17397321802082 #convert(LCHuv,RGB(0,1,1)).h
    const h4 = 265.87273498040290 #convert(LCHuv,RGB(0,0,1)).h
    const h5 = 307.72354567594960 #convert(LCHuv,RGB(1,0,1)).h

    p=0 #variable
    o=0 #min
    t=0 #max

    #Selecting edge of RGB cube; R=1 G=2 B=3
    if h0 <= h < h1
        p=2; o=3; t=1
    elseif h1 <= h < h2
        p=1; o=3; t=2
    elseif h2 <= h < h3
        p=3; o=1; t=2
    elseif h3 <= h < h4
        p=2; o=1; t=3
    elseif h4 <= h < h5
        p=1; o=2; t=3
    elseif h5 <= h || h < h0
        p=3; o=2; t=1
    end

    alpha=-sind(h)
    beta=cosd(h)

    #un &vn are calculated based on reference white (D65)
    #X=0.95047; Y=1.0000; Z=1.08883
    const un=0.19783982482140777 #4.0X/(X+15.0Y+3.0Z)
    const vn=0.46833630293240970 #9.0Y/(X+15.0Y+3.0Z)

    #sRGB matrix
    const M=[0.4124564  0.3575761  0.1804375;
             0.2126729  0.7151522  0.0721750;
             0.0193339  0.1191920  0.9503041]'
    g=2.4

    m_tx=M[t,1]
    m_ty=M[t,2]
    m_tz=M[t,3]
    m_px=M[p,1]
    m_py=M[p,2]
    m_pz=M[p,3]

    f1=(4alpha*m_px+9beta*m_py)
    a1=(4alpha*m_tx+9beta*m_ty)
    f2=(m_px+15m_py+3m_pz)
    a2=(m_tx+15m_ty+3m_tz)

    cp=((alpha*un+beta*vn)*a2-a1)/(f1-(alpha*un+beta*vn)*f2)

    #gamma inversion
#    cp = cp <= 0.003 ? 12.92cp : 1.055cp^(1.0/g)-0.05
    cp = 1.055cp^(1.0/g)-0.05

    col=zeros(3)
    col[p]=clamp(cp,0.0,1.0)
    col[o]=0.0
    col[t]=1.0

    convert(LCHuv, RGB(col[1],col[2],col[3]))
end

# Maximum saturation for given lightness and hue
# ----------------------
# Maximally saturated color for a specific hue and lightness
# is found by looking for the edge of LCHuv space.

function MSC(h,l)
    pmid=MSC(h)

    if l <= pmid.l
        pend=LCHuv(0,0,0)
    elseif l > pmid.l
        pend=LCHuv(100,0,0)
    end

    a=(pend.l-l)/(pend.l-pmid.l)
    a*(pmid.c-pend.c)+pend.c
end

#Double quadratic Beziere curve
function Beziere(t,p0,p2,q0,q1,q2)
    function B(t,a,b,c)
    a*(1.0-t)^2.0+2.0*b*(1.0-t)*t+c*t^2.0
    end

    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    elseif t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end

    NaN
end

#Inverse double quadratic Beziere curve
function invBeziere(t,p0,p2,q0,q1,q2)
    function invB(t,a,b,c)
        (a-b+sqrt(b^2.0-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    end

    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    elseif t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end

    NaN
end

# Small definitions to make color computations more clear

+(x::LCHuv, y::LCHuv) = LCHuv(x.l+y.l,x.c+y.c,x.h+y.h)
*(x::Real, y::LCHuv) = LCHuv(x*y.l,x*y.c,x*y.h)


# Sequential palette
# ----------------------
# Sequential_palette implements the color palette creation technique by
# Wijffelaars, M., et al. (2008)
# http://magnaview.nl/documents/MagnaView-M_Wijffelaars-Generating_color_palettes_using_intuitive_parameters.pdf
#
# Colormaps are formed using Beziere curves in LCHuv colorspace
# with some constant hue. In addition, start and end points can be given
# that are then blended to the original hue smoothly.
#
# The arguments are:
# N        - number of colors
# h        - the main hue [0,360]
# c        - the overall lightness contrast [0,1]
# s        - saturation [0,1]
# b        - brightness [0,1]
# w        - cold/warm parameter, i.e. the strength of the starting color [0,1]
# d        - depth of the ending color [0,1]
# wcolor   - starting color (warmness)
# dcolor   - ending color (depth)
# logscale - true/false for toggling logspacing

function sequential_palette(h,
                            N::Int=100;
                            c=0.88,
                            s=0.6,
                            b=0.75,
                            w=0.15,
                            d=0.0,
                            wcolor=RGB(1,1,0),
                            dcolor=RGB(0,0,1),
                            logscale=false)

    function MixHue(a,h0,h1)
        M=mod(180.0+h1-h0, 360)-180.0
        mod(h0+a*M, 360)
    end

    pstart=convert(LCHuv, wcolor)
    p1=MSC(h)
#    p0=LCHuv(0,0,h) #original end point
    pend=convert(LCHuv, dcolor)

    #multi-hue start point
    p2l=100*(1.-w)+w*pstart.l
    p2h=MixHue(w,h,pstart.h)
    p2c=min(MSC(p2h,p2l), w*s*pstart.c)
    p2=LCHuv(p2l,p2c,p2h)

    #multi-hue ending point
    p0l=20.0*d
    p0h=MixHue(d,h,pend.h)
    p0c=min(MSC(p0h,p0l), d*s*pend.c)
    p0=LCHuv(p0l,p0c,p0h)

    q0=(1.0-s)*p0+s*p1
    q2=(1.0-s)*p2+s*p1
    q1=0.5*(q0+q2)

    pal = RGB[]

    if logscale
        absc = logspace(-2.,0.,N)
    else
        absc = linspace(0.,1.,N)
    end

    for t in absc
        u=1.0-t

        #Change grid to favor light colors and to be uniform along the curve
        u = (125.0-125.0*0.2^((1.0-c)*b+u*c))
        u = invBeziere(u,p0.l,p2.l,q0.l,q1.l,q2.l)

        #Get color components from Beziere curves
        ll = Beziere(u, p0.l, p2.l, q0.l, q1.l, q2.l)
        cc = Beziere(u, p0.c, p2.c, q0.c, q1.c, q2.c)
        hh = Beziere(u, p0.h, p2.h, q0.h, q1.h, q2.h)

        push!(pal, convert(RGB, LCHuv(ll,cc,hh)))
    end

    pal
end

# Diverging palettes
# ----------------------
# Create diverging palettes by combining 2 sequential palettes
#
# The arguments are:
# N        - number of colors
# h1       - the main hue of the left side [0,360]
# h2       - the main hue of the right side [0,360]
# c        - the overall lightness contrast [0,1]
# s        - saturation [0,1]
# b        - brightness [0,1]
# w        - cold/warm parameter, i.e. the strength of the starting color [0,1]
# d1       - depth of the ending color in the left side [0,1]
# d2       - depth of the ending color in the right side [0,1]
# wcolor   - starting color (warmness)
# dcolor1  - ending color of the left side (depth)
# dcolor2  - ending color of the right side (depth)
# logscale - true/false for toggling logspacing

function diverging_palette(h1,
                           h2,
                           N::Int=100;
                           mid=0.5,
                           c=0.88,
                           s=0.6,
                           b=0.75,
                           w=0.15,
                           d1=0.0,
                           d2=0.0,
                           wcolor=RGB(1,1,0),
                           dcolor1=RGB(1,0,0),
                           dcolor2=RGB(0,0,1),
                           logscale=false)

    if isodd(N)
        n=N-1
    else
        n=N
    end
    N1 = int(max(ceil(mid*n), 1))
    N2 = int(max(n-N1, 1))

    pal1 = sequential_palette(h1, N1+1, w=w, d=d1, c=c, s=s, b=b, wcolor=wcolor, dcolor=dcolor1, logscale=logscale)
    pal1 = flipud(pal1)

    pal2 = sequential_palette(h2, N2+1, w=w, d=d2, c=c, s=s, b=b, wcolor=wcolor, dcolor=dcolor2, logscale=logscale)

    if isodd(N)
        midcol = weighted_color_mean(0.5, pal1[end], pal2[1])
        return [pal1[1:end-1], midcol, pal2[2:end]]
    else
        return [pal1[1:end-1], pal2[2:end]]
    end
end


# Colormap
# ----------------------
# Main function to handle different predefined colormaps

function colormap(cname::String, N::Int=100; mid=0.5, logscale=false, kvs...)

    cname = lowercase(cname)
    if haskey(colormaps_sequential, cname)
        vals = colormaps_sequential[cname]

        #XXX: fix me
        #setindex does not work for tuples with mixed types
        #-> change into array(Any)
        p=Array(Any,8)
        for i in 1:8
            p[i] = vals[i]
        end

        for (k,v) in kvs
            ind = findfirst([:h, :w, :d, :c, :s, :b, :wcolor, :dcolor], k)
            if ind > 0
                p[ind] = v
            end
            #Better way to write this, but does not work?
            #if k in [:h, :w, :d, :c, :s, :b, :wcolor, :dcolor]
            #    @eval $k = $v
            #end
        end

        return sequential_palette(p[1], N, w=p[2], d=p[3], c=p[4], s=p[5], b=p[6], wcolor=p[7], dcolor=p[8], logscale=logscale)

    elseif haskey(colormaps_diverging, cname)
        vals = colormaps_diverging[cname]

        p=Array(Any,11)
        for i in 1:11
            p[i] = vals[i]
        end

        for (k,v) in kvs
            ind = findfirst([:h, :h2, :w, :d1, :d2, :c, :s, :b, :wcolor, :dcolor1, :dcolor2], k)
            if ind > 0
                p[ind] = v
            end
        end

        return diverging_palette(p[1], p[2], N, w=p[3], d1=p[4], d2=p[5], c=p[6], s=p[7], b=p[8], wcolor=p[9], dcolor1=p[10], dcolor2=p[11], mid=mid, logscale=logscale)

    else
        error("Unknown colormap: ", cname)
    end

end



# Displaying color swatches
# -------------------------

function writemime(io::IO, ::MIME"image/svg+xml", c::ColorValue)
    write(io,
        """
        <?xml version"1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="25mm" height="25mm" viewBox="0 0 1 1">
             <rect width="1" height="1"
                   fill="#$(hex(c))" stroke="none"/>
        </svg>
        """)
end


function writemime{T <: ColorValue}(io::IO, ::MIME"image/svg+xml", cs::Array{T})
    n = length(cs)
    width=15
    pad=1
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(n*width)mm" height="25mm"
             shape-rendering="crispEdges">
        """)

    for (i, c) in enumerate(cs)
        write(io,
            """
            <rect x="$((i-1)*width)mm" width="$(width - pad)mm" height="100%"
                  fill="#$(hex(c))" stroke="none" />
            """)
    end

    write(io, "</svg>")
end



end # module
