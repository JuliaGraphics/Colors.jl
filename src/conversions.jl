# Conversions
# -----------

# convert(C, c) might be called as convert(RGB, c) or convert(RGB{Float32}, c)
# This is handled in ColorTypes, which calls functions
#     _convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c)
#     _convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c, alpha)
# Here are the argument types:
# - Cdest may be any concrete Color{T,N} type. For parametric Color types
#   it _always_ has the desired element type (e.g., Float32), so it's
#   safe to dispatch on Cdest{T}.
# - Odest and Osrc are Color subtypes, i.e., things like RGB
#   or HSV. They have no element type.
# - c is the Colorant object you wish to convert.
# - alpha, if present, is a user-supplied alpha value (to be used in
#   place of any default alpha or alpha present in c).
#
# The motivation for this arrangement is that Julia doesn't (yet) support
# "triangular dispatch", e.g.,
#     convert{T,C}(::Type{C{T}}, c)
# The various arguments of _convert therefore "peel off" element types
# (or guarantee them) so that comparisons may be made via
# dispatch. The alternative design is
#    for C in parametric_colors
#       @eval convert{T}(::Type{$C{T}}, c) = ...
#       @eval convert(   ::Type{$C},    c) = convert($C{eltype(c)}, c)
#       ...
#    end
# but this requires a fair amount of codegen (especially for all
# the various alpha variants) and can break if not all C support
# the same eltypes.
#
# Note that ColorTypes handles the cases where Odest == Osrc, or they
# are both subtypes of AbstractRGB.  Therefore, here we only have to
# deal with conversions between different spaces.


function ColorTypes._convert{Cdest<:TransparentColor,Odest,Osrc}(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, p, alpha)
    # Convert the base color
    c = cnvt(color_type(Cdest), color(p))
    # Append the alpha
    ColorTypes._convert(Cdest, Odest, Odest, c, alpha)
end
function ColorTypes._convert{Cdest<:TransparentColor,Odest,Osrc}(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, p)
    c = cnvt(color_type(Cdest), color(p))
    ColorTypes._convert(Cdest, Odest, Odest, c, alpha(p))
end

ColorTypes._convert{Cdest<:Color,Odest,Osrc}(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c) = cnvt(Cdest, c)


# Fallback to catch undefined operations
cnvt{C<:Color}(::Type{C}, c::TransparentColor) = cnvt(C, color(c))
cnvt{C}(::Type{C}, c) = convert(C, c)

# Conversions from grayscale
# --------------------------
cnvt{C<:Color3}(::Type{C}, g::AbstractGray)  = cnvt(C, convert(RGB{eltype(C)}, g))


macro mul3x3(T, M, c1, c2, c3)
    esc(quote
        @inbounds ret = $T($M[1,1]*$c1 + $M[1,2]*$c2 + $M[1,3]*$c3,
                           $M[2,1]*$c1 + $M[2,2]*$c2 + $M[2,3]*$c3,
                           $M[3,1]*$c1 + $M[3,2]*$c2 + $M[3,3]*$c3)
        ret
        end)
end

# Everything to RGB
# -----------------

correct_gamut{CV<:AbstractRGB}(c::CV) = CV(clamp01(red(c)), clamp01(green(c)), clamp01(blue(c)))
clamp01{T<:Fractional}(v::T) = ifelse(v < zero(T), zero(T), ifelse(v > one(T), one(T), v))

function srgb_compand(v)
    v <= 0.0031308 ? 12.92v : 1.055v^(1/2.4) - 0.055
end

cnvt{CV<:AbstractRGB}(::Type{CV}, c::AbstractRGB) = CV(red(c), green(c), blue(c))

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::HSV)
    h = c.h / 60
    i = floor(Int, h)
    f = h - i
    if i & 1 == 0
        f = 1 - f
    end
    m = c.v * (1 - c.s)
    n = c.v * (1 - c.s * f)
    if i == 6 || i == 0; CV(c.v, n, m)
    elseif i == 1;       CV(n, c.v, m)
    elseif i == 2;       CV(m, c.v, n)
    elseif i == 3;       CV(m, n, c.v)
    elseif i == 4;       CV(n, m, c.v)
    else;                CV(c.v, m, n)
    end
end

function qtrans(u, v, hue)
    if     hue > 360; hue -= 360
    elseif hue < 0;   hue += 360
    end

    if     hue < 60;  u + (v - u) * hue / 60
    elseif hue < 180; v
    elseif hue < 240; u + (v - u) * (240 - hue) / 60
    else;             u
    end
end

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::HSL)
    v = c.l <= 0.5 ? c.l * (1 + c.s) : c.l + c.s - (c.l * c.s)
    u = 2 * c.l - v

    if c.s == 0; CV(c.l, c.l, c.l)
    else;        CV(qtrans(u, v, c.h + 120),
                    qtrans(u, v, c.h),
                    qtrans(u, v, c.h - 120))
    end
end

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::HSI)
    h, s, i = c.h, c.s, c.i
    while(h > 360) h -= 360 end
    while(h < 0) h += 360 end
    is = i*s
    if h < 120
        cosr = cosd(h) / cosd(60-h)
        CV(i+is*cosr, i+is*(1-cosr), i-is)
    elseif h < 240
        cosr = cosd(h-120) / cosd(180-h)
        CV(i-is, i+is*cosr, i+is*(1-cosr))
    else
        cosr = cosd(h-240) / cosd(300-h)
        CV(i+is*(1-cosr), i-is, i+is*cosr)
    end
end

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::XYZ)
    r =  3.2404542*c.x - 1.5371385*c.y - 0.4985314*c.z
    g = -0.9692660*c.x + 1.8760108*c.y + 0.0415560*c.z
    b =  0.0556434*c.x - 0.2040259*c.y + 1.0572252*c.z
    CV(clamp01(srgb_compand(r)),
       clamp01(srgb_compand(g)),
       clamp01(srgb_compand(b)))
end

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::YIQ)
    cc = correct_gamut(c)
    CV(clamp01(cc.y+0.9563*cc.i+0.6210*cc.q),
       clamp01(cc.y-0.2721*cc.i-0.6474*cc.q),
       clamp01(cc.y-1.1070*cc.i+1.7046*cc.q))
end

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::YCbCr)
    cc = correct_gamut(c)
    ny = cc.y - 16
    ncb = cc.cb - 128
    ncr = cc.cr - 128
    CV(clamp01(0.004567ny - 1.39135e-7ncb + 0.0062586ncr),
       clamp01(0.004567ny - 0.00153646ncb - 0.0031884ncr),
       clamp01(0.004567ny + 0.00791058ncb - 2.79201e-7ncr))
end

cnvt{CV<:AbstractRGB}(::Type{CV}, c::LCHab)  = cnvt(CV, convert(Lab{eltype(c)}, c))
cnvt{CV<:AbstractRGB}(::Type{CV}, c::LCHuv)  = cnvt(CV, convert(Luv{eltype(c)}, c))
cnvt{CV<:AbstractRGB}(::Type{CV}, c::Color3)    = cnvt(CV, convert(XYZ{eltype(c)}, c))

cnvt{CV<:AbstractRGB{N0f8}}(::Type{CV}, c::RGB24) = CV(N0f8(c.color&0x00ff0000>>>16,0), N0f8(c.color&0x0000ff00>>>8,0), N0f8(c.color&0x000000ff,0))
cnvt{CV<:AbstractRGB}(::Type{CV}, c::RGB24) = CV((c.color&0x00ff0000>>>16)/255, ((c.color&0x0000ff00)>>>8)/255, (c.color&0x000000ff)/255)

function cnvt{CV<:AbstractRGB}(::Type{CV}, c::AbstractGray)
    g = convert(eltype(CV), gray(c))
    CV(g, g, g)
end


# Everything to HSV
# -----------------

function cnvt{T}(::Type{HSV{T}}, c::AbstractRGB)
    c_min = Float64(min(red(c), green(c), blue(c)))
    c_max = Float64(max(red(c), green(c), blue(c)))
    if c_min == c_max
        return HSV{T}(zero(T), zero(T), c_max)
    end

    if c_min == red(c)
        f = Float64(green(c)) - Float64(blue(c))
        i = 3
    elseif c_min == green(c)
        f = Float64(blue(c)) - Float64(red(c))
        i = 5
    else
        f = Float64(red(c)) - Float64(green(c))
        i = 1
    end

    HSV{T}(60 * (i - f / (c_max - c_min)),
        (c_max - c_min) / c_max,
        c_max)
end


cnvt{T}(::Type{HSV{T}}, c::Color3) = cnvt(HSV{T}, convert(RGB{T}, c))


# Everything to HSL
# -----------------

function cnvt{T}(::Type{HSL{T}}, c::AbstractRGB)
    r, g, b = T(red(c)), T(green(c)), T(blue(c))
    c_min = min(r, g, b)
    c_max = max(r, g, b)
    l = (c_max + c_min) / 2

    if c_max == c_min
        return HSL(zero(T), zero(T), l)
    end

    if l < 0.5; s = (c_max - c_min) / (c_max + c_min)
    else;       s = (c_max - c_min) / (convert(T, 2) - c_max - c_min)
    end

    if c_max == red(c)
        h = (g - b) / (c_max - c_min)
    elseif c_max == green(c)
        h = convert(T, 2) + (b - r) / (c_max - c_min)
    else
        h = convert(T, 4) + (r - g) / (c_max - c_min)
    end

    h *= 60
    if h < 0
        h += 360
    elseif h > 360
        h -= 360
    end

    HSL{T}(h,s,l)
end


cnvt{T}(::Type{HSL{T}}, c::Color3) = cnvt(HSL{T}, convert(RGB{T}, c))


# Everything to HSI
# -----------------

function cnvt{T}(::Type{HSI{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    r, g, b = red(rgb), green(rgb), blue(rgb)
    isum = r+g+b
    i = isum/3
    m = min(r, g, b)
    s = i > 0 ? 1-m/i : 1-one(i)/one(i) # the latter is a type-stable 0
    val = (r-(g+b)/2)/sqrt(((r-g)^2 + (r-b)^2 + (g-b)^2)/2)
    val = clamp(val, -one(val), one(val))
    h = acosd(val)
    if b > g
        h = 360-h
    end
    HSI{T}(h, s, i)
end

cnvt{T}(::Type{HSI{T}}, c::Color3) = cnvt(HSI{T}, convert(RGB{T}, c))

# Everything to XYZ
# -----------------

function invert_rgb_compand(v)
    v <= 0.04045 ? v/12.92 : ((v+0.055) /1.055)^2.4
end

function cnvt{T}(::Type{XYZ{T}}, c::AbstractRGB)
    r, g, b = invert_rgb_compand(red(c)), invert_rgb_compand(green(c)), invert_rgb_compand(blue(c))
    XYZ{T}(0.4124564*r + 0.3575761*g + 0.1804375*b,
           0.2126729*r + 0.7151522*g + 0.0721750*b,
           0.0193339*r + 0.1191920*g + 0.9503041*b)
end


cnvt{T}(::Type{XYZ{T}}, c::HSV) = cnvt(XYZ{T}, convert(RGB{T}, c))
cnvt{T}(::Type{XYZ{T}}, c::HSL) = cnvt(XYZ{T}, convert(RGB{T}, c))
cnvt{T}(::Type{XYZ{T}}, c::HSI) = cnvt(XYZ{T}, convert(RGB{T}, c))


function cnvt{T}(::Type{XYZ{T}}, c::xyY)
    X = c.Y*c.x/c.y
    Z = c.Y*(1-c.x-c.y)/c.y
    XYZ{T}(X, c.Y, Z)
end


const xyz_epsilon = 216 / 24389
const xyz_kappa   = 24389 / 27

convert(::Type{XYZ}, c, wp::XYZ) = convert(XYZ{eltype(wp)}, c, wp)
convert{T}(::Type{XYZ{T}}, c, wp::XYZ) = cnvt(XYZ{T}, c, wp)
function cnvt{T}(::Type{XYZ{T}}, c::Lab, wp::XYZ)
    fy = (c.l + 16) / 116
    fx = c.a / 500 + fy
    fz = fy - c.b / 200

    fx3 = fx^3
    fz3 = fz^3

    x = fx3 > xyz_epsilon ? fx3 : (116fx - 16) / xyz_kappa
    y = c.l > xyz_kappa * xyz_epsilon ? ((c. l+ 16) / 116)^3 : c.l / xyz_kappa
    z = fz3 > xyz_epsilon ? fz3 : (116fz - 16) / xyz_kappa

    XYZ{T}(x*wp.x, y*wp.y, z*wp.z)
end


cnvt{T}(::Type{XYZ{T}}, c::Lab)   = convert(XYZ{T}, c, WP_DEFAULT)
cnvt{T}(::Type{XYZ{T}}, c::LCHab) = cnvt(XYZ{T}, convert(Lab{T}, c))
cnvt{T}(::Type{XYZ{T}}, c::DIN99) = cnvt(XYZ{T}, convert(Lab{T}, c))
cnvt{T}(::Type{XYZ{T}}, c::DIN99o) = cnvt(XYZ{T}, convert(Lab{T}, c))

cnvt{T<:UFixed}(::Type{XYZ{T}}, c::LCHab) = cnvt(XYZ{T}, convert(Lab{eltype(c)}, c))
cnvt{T<:UFixed}(::Type{XYZ{T}}, c::DIN99) = cnvt(XYZ{T}, convert(Lab{eltype(c)}, c))
cnvt{T<:UFixed}(::Type{XYZ{T}}, c::DIN99o) = cnvt(XYZ{T}, convert(Lab{eltype(c)}, c))


function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    d==0 && return (d, d)
    u = 4c.x / d
    v = 9c.y / d
    return (u, v)
end


function cnvt{T}(::Type{XYZ{T}}, c::Luv, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)

    a = (52 * (c.l==0 ? zero(T) : c.l / (c.u + 13 * c.l * u_wp)) - 1) / 3
    y = c.l > xyz_kappa * xyz_epsilon ? wp.y * ((c.l + 16) / 116)^3 : wp.y * c.l / xyz_kappa
    b = -5y
    d = y * (39 * (c.l==0 ? zero(T) : c.l / (c.v + 13 * c.l * v_wp)) - 5)
    x = d==b ? zero(T) : (d - b) / (a + 1/3)
    z = a * x + b + zero(T)

    XYZ{T}(x, y, z)
end

cnvt{T}(::Type{XYZ{T}}, c::LCHuv) = cnvt(XYZ{T}, convert(Luv{T}, c))


function cnvt{T}(::Type{XYZ{T}}, c::DIN99d)

    # Go back to C-h space
    # FIXME: Clean this up (why is there no atan2d?)
    h = rad2deg(atan2(c.b,c.a)) + 50
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end

    C = sqrt(c.a^2 + c.b^2)

    # Intermediate terms
    G = (exp(C/22.5)-1)/0.06
    f = G*sind(h - 50)
    ee = G*cosd(h - 50)

    l = (exp(c.l/325.22)-1)/0.0036
    # a = ee*cosd(50) - f/1.14*sind(50)
    a = ee*0.6427876096865393 - f/1.14*0.766044443118978
    # b = ee*sind(50) - f/1.14*cosd(50)
    b = ee*0.766044443118978 - f/1.14*0.6427876096865393

    adj = convert(XYZ, Lab(l, a, b))

    XYZ{T}((adj.x + 0.12*adj.z)/1.12, adj.y, adj.z)

end


function cnvt{T}(::Type{XYZ{T}}, c::LMS)
    @mul3x3 XYZ{T} CAT02_INV c.l c.m c.s
end


cnvt{T}(::Type{XYZ{T}}, c::YIQ) = cnvt(XYZ{T}, convert(RGB{T}, c))
cnvt{T}(::Type{XYZ{T}}, c::YCbCr) = cnvt(XYZ{T}, convert(RGB{T}, c))

cnvt{T}(::Type{XYZ{T}}, c::RGB24) = cnvt(XYZ{T}, convert(RGB{T}, c))

# Everything to xyY
# -----------------

function cnvt{T}(::Type{xyY{T}}, c::XYZ)

    x = c.x/(c.x + c.y + c.z)
    y = c.y/(c.x + c.y + c.z)

    xyY{T}(x, y, convert(typeof(x), c.y))

end

cnvt{T}(::Type{xyY{T}}, c::Color3) = cnvt(xyY{T}, convert(XYZ{T}, c))



# Everything to Lab
# -----------------

cnvt{T}(::Type{Lab{T}}, c::AbstractRGB) = convert(Lab{T}, convert(XYZ{T}, c))
cnvt{T}(::Type{Lab{T}}, c::HSV) = cnvt(Lab{T}, convert(RGB{T}, c))
cnvt{T}(::Type{Lab{T}}, c::HSL) = cnvt(Lab{T}, convert(RGB{T}, c))

convert{T}(::Type{Lab{T}}, c, wp::XYZ) = cnvt(Lab{T}, c, wp)
convert(::Type{Lab}, c, wp::XYZ) = cnvt(Lab{eltype(wp)}, c, wp)

function fxyz2lab(v)
    v > xyz_epsilon ? cbrt(v) : (xyz_kappa * v + 16) / 116
end
function cnvt{T}(::Type{Lab{T}}, c::XYZ, wp::XYZ)
    fx, fy, fz = fxyz2lab(c.x / wp.x), fxyz2lab(c.y / wp.y), fxyz2lab(c.z / wp.z)
    Lab{T}(116fy - 16, 500(fx - fy), 200(fy - fz))
end


cnvt{T}(::Type{Lab{T}}, c::XYZ{T}) = cnvt(Lab{T}, c, WP_DEFAULT)


function cnvt{T}(::Type{Lab{T}}, c::LCHab)
    hr = deg2rad(c.h)
    Lab{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


function cnvt{T}(::Type{Lab{T}}, c::DIN99)

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
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
    # ciea = ee*cosd(16) - (f/0.7)*sind(16)
    ciea = ee*0.9612616959383189 - (f/0.7)*0.27563735581699916
    # cieb = ee*sind(16) + (f/0.7)*cosd(16)
    cieb = ee*0.27563735581699916 + (f/0.7)*0.9612616959383189

    # CIELAB L*
    ciel = (e^(c.l*ke/105.51)-1)/0.0158

    Lab{T}(ciel, ciea, cieb)
end


function cnvt{T}(::Type{Lab{T}}, c::DIN99o)

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
    kch = 1
    ke = 1

    # Calculate Chroma (C99) in the DIN99o space
    co = sqrt(c.a^2 + c.b^2)

    # hue angle h99o
    h = atan2(c.b, c.a)

    # revert rotation by 26°
    ho= rad2deg(h)-26

    # revert logarithmic chroma compression
    g = (e^(co*kch*ke/23.0)-1)/0.075

    # Temporary redness
    eo = g*cosd(ho)

    # Temporary yellowness
    fo = g*sind(ho)

    # CIELAB a*b* (revert b* axis compression)
    # ciea = eo*cosd(26) - (fo/0.83)*sind(26)
    ciea = eo*0.898794046299167 - (fo/0.83)*0.4383711467890774
    # cieb = eo*sind(26) + (fo/0.83)*cosd(26)
    cieb = eo*0.4383711467890774 + (fo/0.83)*0.898794046299167

    # CIELAB L* (revert logarithmic lightness compression)
    ciel = (e^(c.l*ke/303.67)-1)/0.0039

    Lab{T}(ciel, ciea, cieb)
end


cnvt{T}(::Type{Lab{T}}, c::Color3) = cnvt(Lab{T}, convert(XYZ{T}, c))


# Everything to Luv
# -----------------

cnvt{T}(::Type{Luv{T}}, c::AbstractRGB) = cnvt(Luv{T}, convert(XYZ{T}, c))
cnvt{T}(::Type{Luv{T}}, c::HSV) = cnvt(Luv{T}, convert(RGB{T}, c))
cnvt{T}(::Type{Luv{T}}, c::HSL) = cnvt(Luv{T}, convert(RGB{T}, c))

convert{T}(::Type{Luv{T}}, c, wp::XYZ) = cnvt(Luv{T}, c, wp)
convert(::Type{Luv}, c, wp::XYZ) = cnvt(Luv{eltype(wp)}, c, wp)

function cnvt{T}(::Type{Luv{T}}, c::XYZ, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y

    l = y > xyz_epsilon ? 116 * cbrt(y) - 16 : xyz_kappa * y
    u = 13 * l * (u_ - u_wp) + zero(T)
    v = 13 * l * (v_ - v_wp) + zero(T)

    Luv{T}(l, u, v)
end


function cnvt{T}(::Type{Luv{T}}, c::LCHuv)
    hr = deg2rad(c.h)
    Luv{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


cnvt{T}(::Type{Luv{T}}, c::Color3) = cnvt(Luv{T}, convert(XYZ{T}, c))


# Everything to LCHuv
# -------------------

function cnvt{T}(::Type{LCHuv{T}}, c::Luv)
    h = rad2deg(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv{T}(c.l, sqrt(c.u^2 + c.v^2), h)
end


cnvt{T}(::Type{LCHuv{T}}, c::Color3) = cnvt(LCHuv{T}, convert(Luv{T}, c))


# Everything to LCHab
# -------------------

function cnvt{T}(::Type{LCHab{T}}, c::Lab)
    h = rad2deg(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab{T}(c.l, sqrt(c.a^2 + c.b^2), h)
end


cnvt{T}(::Type{LCHab{T}}, c::Color3) = cnvt(LCHab{T}, convert(Lab{T}, c))


# Everything to DIN99
# -------------------

function cnvt{T}(::Type{DIN99{T}}, c::Lab)

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
    kch = 1
    ke = 1

    # Calculate DIN99 L
    l99 = (1/ke)*105.51*log(1+0.0158*c.l)

    # Temporary value for redness and yellowness
    # ee = c.a*cosd(16) + c.b*sind(16)
    ee = c.a*0.9612616959383189 + c.b*0.27563735581699916
    # f = -0.7*c.a*sind(16) + 0.7*c.b*cosd(16)
    f = -0.7*c.a*0.27563735581699916 + 0.7*c.b*0.9612616959383189

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

    DIN99{T}(l99, a99, b99)

end


cnvt{T}(::Type{DIN99{T}}, c::Color3) = cnvt(DIN99{T}, convert(Lab{T}, c))


# Everything to DIN99d
# --------------------

function cnvt{T}(::Type{DIN99d{T}}, c::XYZ{T})

    # Apply tristimulus-space correction term
    adj_c = XYZ(1.12*c.x - 0.12*c.z, c.y, c.z)

    # Apply L*a*b*-space correction
    lab = convert(Lab, adj_c)
    adj_L = 325.22*log(1+0.0036*lab.l)

    # Calculate intermediate parameters
    # ee = lab.a*cosd(50) + lab.b*sind(50)
    ee = lab.a*0.6427876096865393 + lab.b*0.766044443118978
    # f = 1.14*(lab.b*cosd(50) - lab.a*sind(50))
    f = 1.14*(lab.b*0.6427876096865393 - lab.a*0.766044443118978)
    G = sqrt(ee^2+f^2)

    # Calculate hue/chroma
    C = 22.5*log(1+0.06*G)
    # FIXME: Clean this up (why is there no atan2d?)
    h = rad2deg(atan2(f,ee)) + 50
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end

    DIN99d{T}(adj_L, C*cosd(h), C*sind(h))

end


cnvt{T}(::Type{DIN99d{T}}, c::Color3) = cnvt(DIN99d{T}, convert(XYZ{T}, c))


# Everything to DIN99o
# -------------------

function cnvt{T}(::Type{DIN99o{T}}, c::Lab)

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
    kch = 1
    ke = 1

    # Calculate DIN99o L (logarithmic compression)
    l99 = 303.67/ke*log(1+0.0039*c.l)

    # Temporary value for redness and yellowness
    # including rotation by 26°
    # eo = c.a*cosd(26) + c.b*sind(26)
    eo = c.a*0.898794046299167 + c.b*0.4383711467890774
    # compression along the yellowness (blue-yellow) axis
    # fo = 0.83 * (c.b*cosd(26) - c.a*sind(26))
    fo = 0.83 * (c.b*0.898794046299167 - c.a*0.4383711467890774)

    # Temporary value for chroma
    go = sqrt(eo^2 + fo^2)
    ho = atan2(fo,eo)
    # rotation of the color space by 26°
    h  = rad2deg(ho) + 26

    # DIN99o chroma (logarithmic compression)
    cc = 23.0*log(1+0.075*go)/(kch*ke)

    # DIN99o chromaticities
    a99, b99 = cc*cosd(h), cc*sind(h)

    DIN99o{T}(l99, a99, b99)

end


cnvt{T}(::Type{DIN99o{T}}, c::Color3) = cnvt(DIN99o{T}, convert(Lab{T}, c))


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


function cnvt{T}(::Type{LMS{T}}, c::XYZ)
    @mul3x3 LMS{T} CAT02 c.x c.y c.z
end


cnvt{T}(::Type{LMS{T}}, c::Color3) = cnvt(LMS{T}, convert(XYZ{T}, c))

# Everything to YIQ
# -----------------

correct_gamut{T}(c::YIQ{T}) = YIQ{T}(clamp(c.y, zero(T), one(T)),
                                     clamp(c.i, convert(T,-0.5957), convert(T,0.5957)),
                                     clamp(c.q, convert(T,-0.5226), convert(T,0.5226)))

function cnvt{T}(::Type{YIQ{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    YIQ{T}(0.299*red(rgb)+0.587*green(rgb)+0.114*blue(rgb),
           0.595716*red(rgb)-0.274453*green(rgb)-0.321263*blue(rgb),
           0.211456*red(rgb)-0.522591*green(rgb)+0.311135*blue(rgb))
end

cnvt{T}(::Type{YIQ{T}}, c::Color3) = cnvt(YIQ{T}, convert(RGB{T}, c))


# Everything to YCbCr
# -------------------

correct_gamut{T}(c::YCbCr{T}) = YCbCr{T}(clamp(c.y, convert(T,16), convert(T,235)),
                                         clamp(c.cb, convert(T,16), convert(T,240)),
                                         clamp(c.cr, convert(T,16), convert(T,240)))

function cnvt{T}(::Type{YCbCr{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    YCbCr{T}(16+65.481*red(rgb)+128.553*green(rgb)+24.966*blue(rgb),
             128-37.797*red(rgb)-74.203*green(rgb)+112*blue(rgb),
             128+112*red(rgb)-93.786*green(rgb)-18.214*blue(rgb))
end

cnvt{T}(::Type{YCbCr{T}}, c::Color3) = cnvt(YCbCr{T}, convert(RGB{T}, c))

# Everything to RGB24
# -------------------

convert(::Type{RGB24}, c::RGB24) = c
convert(::Type{RGB24}, c::AbstractRGB{N0f8}) = RGB24(red(c), green(c), blue(c))
function convert(::Type{RGB24}, c::AbstractRGB)
    u = (reinterpret(N0f8(red(c))) % UInt32)<<16 +
        (reinterpret(N0f8(green(c))) % UInt32)<<8 +
        reinterpret(N0f8(blue(c))) % UInt32
    reinterpret(RGB24, u)
end

convert(::Type{RGB24}, c::Color) = convert(RGB24, convert(RGB{N0f8}, c))

# To ARGB32
# ----------------

convert(::Type{ARGB32}, c::ARGB32) = c
convert{CV<:AbstractRGB{N0f8}}(::Type{ARGB32}, c::TransparentColor{CV}) =
    ARGB32(red(c), green(c), blue(c), alpha(c))
function convert(::Type{ARGB32}, c::TransparentColor)
    u = reinterpret(UInt32, convert(RGB24, c)) | (reinterpret(N0f8(alpha(c)))%UInt32)<<24
    reinterpret(ARGB32, u)
end
function convert(::Type{ARGB32}, c::Color)
    u = reinterpret(UInt32, convert(RGB24, c)) | 0xff000000
    reinterpret(ARGB32, u)
end
function convert(::Type{ARGB32}, c::Color, alpha)
    u = reinterpret(UInt32, convert(RGB24, c)) | (reinterpret(N0f8(alpha))%UInt32)<<24
    reinterpret(ARGB32, u)
end

# To Gray
# -------

# Rec 601 luma conversion
if VERSION < v"0.4.0-dev+1827"
    const unsafe_trunc = itrunc
else
    const unsafe_trunc = Base.unsafe_trunc
end

convert{T<:UFixed}(::Type{Gray{T}}, x::AbstractRGB{T}) = (TU = FixedPointNumbers.rawtype(T); Gray{T}(T(round(TU, min(typemax(TU), 0.299f0*reinterpret(x.r) + 0.587f0*reinterpret(x.g) + 0.114f0*reinterpret(x.b))), 0)))
convert{T}(::Type{Gray{T}}, x::AbstractRGB) = convert(Gray{T}, 0.299f0*x.r + 0.587f0*x.g + 0.114f0*x.b)
