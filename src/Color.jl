
module Color

import Base.convert, Base.hex, Base.@deprecate
import Iterators

export ColorValue, color,
       ColourValue, colour,
       weighted_color_mean, hex,
       RGB, HSV, HSL, XYZ, LAB, LUV, LCHab, LCHuv, LMS,
       protanopic, deuteranopic, tritanopic,
       cie_color_match, colordiff, distinguishable_colors


abstract ColorValue
typealias ColourValue ColorValue


# Common Colorspaces
# ------------------


# sRGB (standard Red-Green-Blue)
type RGB <: ColorValue
    r::Float64 # Red in [0,1]
    g::Float64 # Green in [0,1]
    b::Float64 # Blue in [0,1]

    function RGB(r::Number, g::Number, b::Number)
        new(r, g, b)
    end

    RGB() = RGB(0, 0, 0)
end

copy(c::RGB) = RGB(c.r, c.g, b)


# HSV (Hue-Saturation-Value)
type HSV <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    v::Float64 # Value in [0,1]

    function HSV(h::Number, s::Number, v::Number)
        new(h, s, n)
    end

    HSV() = HSV(0, 0, 0)
end

copy(c::HSV) = HSV(c.h, c.s, v)

HSB(h, s, b) = HSV(h, s, b)


# HSL (Hue-Lightness-Saturation)
type HSL <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    l::Float64 # Lightness in [0,1]

    function HSL(h::Number, s::Number, l::Number)
        new(h, s, l)
    end

    HSL() = HSL(0, 0, 0)
end

copy(c::HSL) = HSL(c.h, c.s, c.l)

HLS(h, l, s) = HSL(h, s, l)


# XYZ (CIE 1931)
type XYZ <: ColorValue
    x::Float64
    y::Float64
    z::Float64

    function XYZ(x::Number, y::Number, z::Number)
        new(x, y, z)
    end

    XYZ() = XYZ(0, 0, 0)
end

copy(c::XYZ) = XYZ(c.x, c.y, z)


# LAB (CIELAB)
type LAB <: ColorValue
    l::Float64 # Luminance in [0,1]
    a::Float64 # Red/Green in [-1,1]
    b::Float64 # Blue/Yellow in [-1,1]

    function LAB(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    LAB() = LAB(0, 0, 0)
end

copy(c::LAB) = LAB(c.l, c.a, c.b)


# LCHab (Luminance-Chroma-Hue, Polar-LAB)
type LCHab <: ColorValue
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue

    function LCHab(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHab() = LCHab(0, 0, 0)
end

copy(c::LCHab) = LCHab(c.l, c.c, c.h)


# LUV (CIELUV)
type LUV <: ColorValue
    l::Float64 # Luminance in [0,1]
    u::Float64 # Red/Green in [-1,1]
    v::Float64 # Blue/Yellow in [-1,1]

    function LUV(l::Number, u::Number, v::Number)
        new(l, u, v)
    end

    LUV() = LUV(0, 0, 0)
end

copy(c::LUV) = LUV(c.l, c.u, c.v)


# LCHuv (Luminance-Chroma-Hue, Polar-LUV)
type LCHuv <: ColorValue
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue

    function LCHuv(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHuv() = LCHuv(0, 0, 0)
end

copy(c::LCHuv) = LUV(c.l, c.c, c.h)


# LMS (Long Medium Short)
type LMS <: ColorValue
    l::Float64 # Long
    m::Float64 # Medium
    s::Float64 # Short

    function LMS(l::Number, m::Number, s::Number)
        new(l, m, s)
    end

    LMS() = LMS(0, 0, 0)
end

copy(c::LMS) = LMS(c.l, c.m, c.s)


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
    c.r = min(1.0, max(0.0, c.r))
    c.g = min(1.0, max(0.0, c.g))
    c.b = min(1.0, max(0.0, c.b))
    c
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
convert(::Type{RGB}, c::LMS)   = convert(RGB, convert(XYZ, c))


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
    c_min = min([c.r, c.g, c.b])
    c_max = max([c.r, c.g, c.b])
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
    hr = degrees2radians(c.h)
    LAB(c.l, c.c * cos(hr), c.c * sin(hr))
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
    hr = degrees2radians(c.h)
    LUV(c.l, c.c * cos(hr), c.c * sin(hr))
end

convert(::Type{LUV}, c::ColorValue) = convert(LUV, convert(XYZ, c))


# Everything to LCHuv
# -------------------

function convert(::Type{LCHuv}, c::LUV)
    h = radians2degrees(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv(c.l, sqrt(c.u^2 + c.v^2), h)
end

convert(::Type{LCHuv}, c::ColorValue) = convert(LCHuv, convert(LUV, c))


# Everything to LCHab
# -------------------

function convert(::Type{LCHab}, c::LAB)
    h = radians2degrees(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab(c.l, sqrt(c.a^2 + c.b^2), h)
end

convert(::Type{LCHab}, c::ColorValue) = convert(LCHab, convert(LAB, c))


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


# Simulation of ColorValueblindness
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


# ColorValue Parsing
# -------------

include("x11_color_names.jl")

const col_pat_hex1 = r"(#|0x)([[:xdigit:]])([[:xdigit:]])([[:xdigit:]])"
const col_pat_hex2 = r"(#|0x)([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})"
const col_pat_rgb  = r"rgb\((\d+%?),(\d+%?),(\d+%?)\)"
const col_pat_hsl  = r"hsl\((\d+%?),(\d+%?),(\d+%?)\)"

# Parse a number used in the "rgb()" or "hsl()" color.
function parse_rgb_hsl_num(num::String)
    if num[end] == '%'
        return parse_int(num[1:end-1], 10) / 100
    else
        return parse_int(num, 10) / 255
    end
end


# Parse a color description.
#
# This parses subset of HTML/CSS color specifications. In particular, everything
# is supported but: "hsla()", "rgba()" (since there is no notion of transparency
# in this library) "currentColorValue", and "transparent".
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
        return RGB(parse_int(mat.captures[2], 16) / 255,
                   parse_int(mat.captures[3], 16) / 255,
                   parse_int(mat.captures[4], 16) / 255)
    end

    mat = match(col_pat_hex1, desc_)
    if mat != nothing
        return RGB((16 * parse_int(mat.captures[2], 16)) / 255,
                   (16 * parse_int(mat.captures[3], 16)) / 255,
                   (16 * parse_int(mat.captures[4], 16)) / 255)
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
    if !has(x11_color_names, desc_)
        error("Unknown color: ", desc)
    end

    c = x11_color_names[desc_]
    return RGB(c[1] / 255, c[2] / 255, c[3] / 255)
end


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
function colordiff(a::ColorValue, b::ColorValue)
    a = convert(LAB, a)
    b = convert(LAB, b)

    ac, bc = sqrt(a.a^2 + a.b^2), sqrt(b.a^2 + b.b^2)
    mc = (ac + bc)/2
    g = (1 - sqrt(mc^7 / (mc^7 + 25^7))) / 2
    a.a *= 1 + g
    b.a *= 1 + g

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


# Color Scale Generation
# ----------------------

# Generate n maximally distinguishable colors.
#
# This uses a greedy brute-force approach to choose n colors that are maximally
# distinguishable. Given a seed color, and a set of possible hue, chroma, and
# lightness values (in LCHab space), it repeatedly chooses the next color as the
# one that maximizes the minimum pairwise distance to any of the colors already
# in the palette.
#
# Args:
#   n: Number of colors to generate.
#   transform: Transform applied to colors before measuring distance.
#   seed: Initial color included in the palette.
#   ls: Possible lightness values.
#   cs: Possible chroma values.
#   hs: Possible hue values.
#
# Returns:
#   A Vector{ColorValue} of length n.
#
function distinguishable_colors(n::Integer,
                                transform::Function,
                                seed::ColorValue,
                                ls::Vector{Float64},
                                cs::Vector{Float64},
                                hs::Vector{Float64})

    # Distances of the current color to each previously selected color.
    ds = zeros(Float64, n)
    colors = Array(ColorValue, n)
    trans_colors = Array(ColorValue, n)

    colors[1] = seed
    trans_colors[1] = transform(seed)

    for i in 2:n
        d_best = 0
        for (l, c, h) in Iterators.product(ls, cs, hs)
            candidate = LCHab(l, c, h)
            trans_candidate = transform(candidate)
            for j in 1:(i-1)
                ds[j] = min(colordiff(trans_candidate, trans_colors[j]),
                            colordiff(candidate, colors[j]))
            end
            d = min(ds[1:(i-1)])

            if d > d_best
                d_best = d
                colors[i] = candidate
                trans_colors[i] = trans_candidate
            end
        end
    end

    colors
end


# Deprecated Functions
# --------------------

export hex2rgb, rgb2hex, hsl2rgb, hsv2rgb, name2rgb

# e.g., 0xff0000 -> (1.,0.,0.)
function hex2rgb( hextriplet::Integer )
    s = 1. / 0xff
    r = s * ((hextriplet >> 16) & 0xff)
    g = s * ((hextriplet >>  8) & 0xff)
    b = s * ((hextriplet >>  0) & 0xff)
    return (r, g, b)
end

# e.g., (1.,0.,0.) -> 0xff0000
function rgb2hex(r, g, b)
    (uint32(iround(0xff * r)) << 16) |
    (uint32(iround(0xff * g)) <<  8) |
    (uint32(iround(0xff * b)) <<  0)
end

function hcm2rgb(h, c, m)
    x = c*(1. - abs(mod(6h,2) - 1.))
    r1,g1,b1 = 0.,0.,0.
    if h < 1/6
        r1,g1,b1 = c,x,0.
    elseif h < 2/6
        r1,g1,b1 = x,c,0.
    elseif h < 3/6
        r1,g1,b1 = 0.,c,x
    elseif h < 4/6
        r1,g1,b1 = 0.,x,c
    elseif h < 5/6
        r1,g1,b1 = x,0.,c
    elseif h < 1
        r1,g1,b1 = c,0.,x
    end
    (r1+m, g1+m, b1+m)
end

function hsl2rgb(h, s, l)
    c = s*(1. - abs(2l - 1.))
    m = l - 0.5*c
    hcm2rgb(h, c, m)
end

function hsv2rgb(h, s, v)
    c = s*v
    m = v - c
    hcm2rgb(h, c, m)
end

# e.g., "red" -> (1.,0.,0.)
function name2rgb( name::String )
    ir,ig,ib = _jl_color_names[name]
    (ir/255., ig/255., ib/255.)
end

const _jl_color_names = [
    "y" => (255, 255, 0),
    "m" => (255, 0, 255),
    "c" => (0, 255, 255),
    "r" => (255, 0, 0),
    "g" => (0, 255, 0),
    "b" => (0, 0, 255),
    "w" => (255, 255, 255),
    "k" => (0, 0, 0),

    # http://www.w3.org/TR/SVG/types.html#ColorKeywords
    "aliceblue" => (240, 248, 255),
    "antiquewhite" => (250, 235, 215),
    "aqua" => ( 0, 255, 255),
    "aquamarine" => (127, 255, 212),
    "azure" => (240, 255, 255),
    "beige" => (245, 245, 220),
    "bisque" => (255, 228, 196),
    "black" => ( 0, 0, 0),
    "blanchedalmond" => (255, 235, 205),
    "blue" => ( 0, 0, 255),
    "blueviolet" => (138, 43, 226),
    "brown" => (165, 42, 42),
    "burlywood" => (222, 184, 135),
    "cadetblue" => ( 95, 158, 160),
    "chartreuse" => (127, 255, 0),
    "chocolate" => (210, 105, 30),
    "coral" => (255, 127, 80),
    "cornflowerblue" => (100, 149, 237),
    "cornsilk" => (255, 248, 220),
    "crimson" => (220, 20, 60),
    "cyan" => ( 0, 255, 255),
    "darkblue" => ( 0, 0, 139),
    "darkcyan" => ( 0, 139, 139),
    "darkgoldenrod" => (184, 134, 11),
    "darkgray" => (169, 169, 169),
    "darkgreen" => ( 0, 100, 0),
    "darkgrey" => (169, 169, 169),
    "darkkhaki" => (189, 183, 107),
    "darkmagenta" => (139, 0, 139),
    "darkolivegreen" => ( 85, 107, 47),
    "darkorange" => (255, 140, 0),
    "darkorchid" => (153, 50, 204),
    "darkred" => (139, 0, 0),
    "darksalmon" => (233, 150, 122),
    "darkseagreen" => (143, 188, 143),
    "darkslateblue" => ( 72, 61, 139),
    "darkslategray" => ( 47, 79, 79),
    "darkslategrey" => ( 47, 79, 79),
    "darkturquoise" => ( 0, 206, 209),
    "darkviolet" => (148, 0, 211),
    "deeppink" => (255, 20, 147),
    "deepskyblue" => ( 0, 191, 255),
    "dimgray" => (105, 105, 105),
    "dimgrey" => (105, 105, 105),
    "dodgerblue" => ( 30, 144, 255),
    "firebrick" => (178, 34, 34),
    "floralwhite" => (255, 250, 240),
    "forestgreen" => ( 34, 139, 34),
    "fuchsia" => (255, 0, 255),
    "gainsboro" => (220, 220, 220),
    "ghostwhite" => (248, 248, 255),
    "gold" => (255, 215, 0),
    "goldenrod" => (218, 165, 32),
    "gray" => (128, 128, 128),
    "grey" => (128, 128, 128),
    "green" => ( 0, 128, 0),
    "greenyellow" => (173, 255, 47),
    "honeydew" => (240, 255, 240),
    "hotpink" => (255, 105, 180),
    "indianred" => (205, 92, 92),
    "indigo" => ( 75, 0, 130),
    "ivory" => (255, 255, 240),
    "khaki" => (240, 230, 140),
    "lavender" => (230, 230, 250),
    "lavenderblush" => (255, 240, 245),
    "lawngreen" => (124, 252, 0),
    "lemonchiffon" => (255, 250, 205),
    "lightblue" => (173, 216, 230),
    "lightcoral" => (240, 128, 128),
    "lightcyan" => (224, 255, 255),
    "lightgoldenrodyellow" => (250, 250, 210),
    "lightgray" => (211, 211, 211),
    "lightgreen" => (144, 238, 144),
    "lightgrey" => (211, 211, 211),
    "lightpink" => (255, 182, 193),
    "lightsalmon" => (255, 160, 122),
    "lightseagreen" => ( 32, 178, 170),
    "lightskyblue" => (135, 206, 250),
    "lightslategray" => (119, 136, 153),
    "lightslategrey" => (119, 136, 153),
    "lightsteelblue" => (176, 196, 222),
    "lightyellow" => (255, 255, 224),
    "lime" => ( 0, 255, 0),
    "limegreen" => ( 50, 205, 50),
    "linen" => (250, 240, 230),
    "magenta" => (255, 0, 255),
    "maroon" => (128, 0, 0),
    "mediumaquamarine" => (102, 205, 170),
    "mediumblue" => ( 0, 0, 205),
    "mediumorchid" => (186, 85, 211),
    "mediumpurple" => (147, 112, 219),
    "mediumseagreen" => ( 60, 179, 113),
    "mediumslateblue" => (123, 104, 238),
    "mediumspringgreen" => ( 0, 250, 154),
    "mediumturquoise" => ( 72, 209, 204),
    "mediumvioletred" => (199, 21, 133),
    "midnightblue" => ( 25, 25, 112),
    "mintcream" => (245, 255, 250),
    "mistyrose" => (255, 228, 225),
    "moccasin" => (255, 228, 181),
    "navajowhite" => (255, 222, 173),
    "navy" => ( 0, 0, 128),
    "oldlace" => (253, 245, 230),
    "olive" => (128, 128, 0),
    "olivedrab" => (107, 142, 35),
    "orange" => (255, 165, 0),
    "orangered" => (255, 69, 0),
    "orchid" => (218, 112, 214),
    "palegoldenrod" => (238, 232, 170),
    "palegreen" => (152, 251, 152),
    "paleturquoise" => (175, 238, 238),
    "palevioletred" => (219, 112, 147),
    "papayawhip" => (255, 239, 213),
    "peachpuff" => (255, 218, 185),
    "peru" => (205, 133, 63),
    "pink" => (255, 192, 203),
    "plum" => (221, 160, 221),
    "powderblue" => (176, 224, 230),
    "purple" => (128, 0, 128),
    "red" => (255, 0, 0),
    "rosybrown" => (188, 143, 143),
    "royalblue" => ( 65, 105, 225),
    "saddlebrown" => (139, 69, 19),
    "salmon" => (250, 128, 114),
    "sandybrown" => (244, 164, 96),
    "seagreen" => ( 46, 139, 87),
    "seashell" => (255, 245, 238),
    "sienna" => (160, 82, 45),
    "silver" => (192, 192, 192),
    "skyblue" => (135, 206, 235),
    "slateblue" => (106, 90, 205),
    "slategray" => (112, 128, 144),
    "slategrey" => (112, 128, 144),
    "snow" => (255, 250, 250),
    "springgreen" => ( 0, 255, 127),
    "steelblue" => ( 70, 130, 180),
    "tan" => (210, 180, 140),
    "teal" => ( 0, 128, 128),
    "thistle" => (216, 191, 216),
    "tomato" => (255, 99, 71),
    "turquoise" => ( 64, 224, 208),
    "violet" => (238, 130, 238),
    "wheat" => (245, 222, 179),
    "white" => (255, 255, 255),
    "whitesmoke" => (245, 245, 245),
    "yellow" => (255, 255, 0),
    "yellowgreen" => (154, 205, 50),
]


end # module
