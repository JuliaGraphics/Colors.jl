# Conversions
# -----------

# convert(C, c) might be called as convert(RGB, c) or convert(RGB{Float32}, c)
# To deal this this ambiguity, we dispatch to an internal method _convert
# which will always have the eltype filled in.

# changing the datatype without changing the underlying colorspace
for C in ColorTypes.parametric
    fn = colorfields(C)
    fcvt = Expr[:(convert(T, c.$f)) for f in fn]
    @eval _convert{T}(::Type{$C{T}}, c::$C) = $C{T}($(fcvt...))
end

# Conversions to other color spaces (and for which the element type
# may or may not be specified)
for C in ColorTypes.parametric
    @eval convert(::Type{$C}, c::Color) = _convert(ccolor($C,typeof(c)), c)
    @eval convert{T}(::Type{$C{T}}, c::Color) = _convert($C{T}, c)
end

convert{C<:AbstractColor}(::Type{C}, c::Transparent) = convert(C, color(c))
convert{A<:Union(AlphaColor,ColorAlpha)}(::Type{A}, c::AbstractColor) = convert(A, c)
convert{A<:Union(AlphaColor,ColorAlpha)}(::Type{A}, c::Transparent) = A(convert(colortype(A), color(c)), alpha(c))
convert{A<:Union(AlphaColor,ColorAlpha)}(::Type{A}, c::ARGB32) = A(convert(colortype(A), color(c)), alpha(c))


# Everything to RGB
# -----------------

correct_gamut{CV<:AbstractRGB}(c::CV) = CV(clamp01(c.r), clamp01(c.g), clamp01(c.b))
clamp01{T<:Fractional}(v::T) = ifelse(v < zero(T), zero(T), ifelse(v > one(T), one(T), v))

function srgb_compand(v)
    v <= 0.0031308 ? 12.92v : 1.055v^(1/2.4) - 0.055
end

_convert{CV<:AbstractRGB}(::Type{CV}, c::AbstractRGB) = CV(c.r, c.g, c.b)

function _convert{CV<:AbstractRGB}(::Type{CV}, c::HSV)
    h = c.h / 60
    i = floor(h)
    f = h - i
    if round(Int, i) & 1 == 0
        f = 1 - f
    end
    m = c.v * (1 - c.s)
    n = c.v * (1 - c.s * f)
    i = round(Int, i)
    if i == 6 || i == 0; CV(c.v, n, m)
    elseif i == 1;       CV(n, c.v, m)
    elseif i == 2;       CV(m, c.v, n)
    elseif i == 3;       CV(m, n, c.v)
    elseif i == 4;       CV(n, m, c.v)
    else;                CV(c.v, m, n)
    end
end

function _convert{CV<:AbstractRGB}(::Type{CV}, c::HSL)
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

    v = c.l <= 0.5 ? c.l * (1 + c.s) : c.l + c.s - (c.l * c.s)
    u = 2 * c.l - v

    if c.s == 0; CV(c.l, c.l, c.l)
    else;        CV(qtrans(u, v, c.h + 120),
                        qtrans(u, v, c.h),
                        qtrans(u, v, c.h - 120))
    end
end

function _convert{CV<:AbstractRGB}(::Type{CV}, c::HSI)
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

const M_XYZ_RGB = [ 3.2404542 -1.5371385 -0.4985314
                   -0.9692660  1.8760108  0.0415560
                    0.0556434 -0.2040259  1.0572252 ]

function _convert{CV<:AbstractRGB}(::Type{CV}, c::XYZ)
    ans = M_XYZ_RGB * [c.x, c.y, c.z]
    correct_gamut(CV(srgb_compand(ans[1]),
                     srgb_compand(ans[2]),
                     srgb_compand(ans[3])))
end

function _convert{CV<:AbstractRGB}(::Type{CV}, c::YIQ)
    cc = correct_gamut(c)
    CV(clamp01(cc.y+0.9563*cc.i+0.6210*cc.q),
       clamp01(cc.y-0.2721*cc.i-0.6474*cc.q),
       clamp01(cc.y-1.1070*cc.i+1.7046*cc.q))
end

function _convert{CV<:AbstractRGB}(::Type{CV}, c::YCbCr)
    cc = correct_gamut(c)
    ny = cc.y - 16
    ncb = cc.cb - 128
    ncr = cc.cr - 128
    CV(clamp01(0.004567ny - 1.39135e-7ncb + 0.0062586ncr),
       clamp01(0.004567ny - 0.00153646ncb - 0.0031884ncr),
       clamp01(0.004567ny + 0.00791058ncb - 2.79201e-7ncr))
end

_convert{CV<:AbstractRGB}(::Type{CV}, c::LCHab)  = _convert(CV, _convert(Lab{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::LCHuv)  = _convert(CV, _convert(Luv{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::Color)    = _convert(CV, _convert(XYZ{eltype(c)}, c))

_convert{CV<:AbstractRGB{Ufixed8}}(::Type{CV}, c::RGB24) = CV(Ufixed8(c.color&0x00ff0000>>>16,0), Ufixed8(c.color&0x0000ff00>>>8,0), Ufixed8(c.color&0x000000ff,0))
_convert{CV<:AbstractRGB}(::Type{CV}, c::RGB24) = CV((c.color&0x00ff0000>>>16)/255, ((c.color&0x0000ff00)>>>8)/255, (c.color&0x000000ff)/255)


# Everything to HSV
# -----------------

function _convert{T}(::Type{HSV{T}}, c::AbstractRGB)
    c_min = min(c.r, c.g, c.b)
    c_max = max(c.r, c.g, c.b)
    if c_min == c_max
        return HSV(zero(T), zero(T), c_max)
    end

    if c_min == c.r
        f = c.g - c.b
        i = convert(T, 3)
    elseif c_min == c.g
        f = c.b - c.r
        i = convert(T, 5)
    else
        f = c.r - c.g
        i = convert(T, 1)
    end

    HSV{T}(60 * (i - f / (c_max - c_min)),
        (c_max - c_min) / c_max,
        c_max)
end


_convert{T}(::Type{HSV{T}}, c::Color) = _convert(HSV{T}, _convert(RGB{T}, c))


# Everything to HSL
# -----------------

function _convert{T}(::Type{HSL{T}}, c::AbstractRGB)
    c_min = min(c.r, c.g, c.b)
    c_max = max(c.r, c.g, c.b)
    l = (c_max + c_min) / 2

    if c_max == c_min
        return HSL(zero(T), zero(T), l)
    end

    if l < 0.5; s = (c_max - c_min) / (c_max + c_min)
    else;       s = (c_max - c_min) / (convert(T, 2) - c_max - c_min)
    end

    if c_max == c.r
        h = (c.g - c.b) / (c_max - c_min)
    elseif c_max == c.g
        h = convert(T, 2) + (c.b - c.r) / (c_max - c_min)
    else
        h = convert(T, 4) + (c.r - c.g) / (c_max - c_min)
    end

    h *= 60
    if h < 0
        h += 360
    elseif h > 360
        h -= 360
    end

    HSL{T}(h,s,l)
end


_convert{T}(::Type{HSL{T}}, c::Color) = _convert(HSL{T}, _convert(RGB{T}, c))


# Everything to HSI
# -----------------

function _convert{T}(::Type{HSI{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    α = (2rgb.r - rgb.g - rgb.b)/2
    β = 0.8660254*(rgb.g - rgb.b)
    h = atan2(β, α)
    i = (rgb.r + rgb.g + rgb.b)/3
    s = 1-min(rgb.r, rgb.g, rgb.b)/i
    s = ifelse(i > 0, s, zero(s))
    HSI{T}(h, s, i)
end

_convert{T}(::Type{HSI{T}}, c::Color) = _convert(HSI{T}, _convert(RGB{T}, c))

# Everything to XYZ
# -----------------

function invert_rgb_compand(v)
    v <= 0.04045 ? v/12.92 : ((v+0.055) /1.055)^2.4
end


const M_RGB_XYZ =
    [ 0.4124564  0.3575761  0.1804375
      0.2126729  0.7151522  0.0721750
      0.0193339  0.1191920  0.9503041 ]


function _convert{T}(::Type{XYZ{T}}, c::AbstractRGB)
    v = [invert_rgb_compand(c.r),
         invert_rgb_compand(c.g),
         invert_rgb_compand(c.b)]
    ans = M_RGB_XYZ * v
    XYZ{T}(ans[1], ans[2], ans[3])
end


_convert{T}(::Type{XYZ{T}}, c::HSV) = _convert(XYZ{T}, _convert(RGB{T}, c))
_convert{T}(::Type{XYZ{T}}, c::HSL) = _convert(XYZ{T}, _convert(RGB{T}, c))
_convert{T}(::Type{XYZ{T}}, c::HSI) = _convert(XYZ{T}, _convert(RGB{T}, c))


function _convert{T}(::Type{XYZ{T}}, c::xyY)
    X = c.Y*c.x/c.y
    Z = c.Y*(1-c.x-c.y)/c.y
    XYZ{T}(X, c.Y, Z)
end


const xyz_epsilon = 216 // 24389
const xyz_kappa   = 24389 // 27


function _convert{T}(::Type{XYZ{T}}, c::Lab, wp::XYZ)
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


_convert{T}(::Type{XYZ{T}}, c::Lab)   = _convert(XYZ{T}, c, WP_DEFAULT)
_convert{T}(::Type{XYZ{T}}, c::LCHab) = _convert(XYZ{T}, _convert(Lab{T}, c))
_convert{T}(::Type{XYZ{T}}, c::DIN99) = _convert(XYZ{T}, _convert(Lab{T}, c))
_convert{T}(::Type{XYZ{T}}, c::DIN99o) = _convert(XYZ{T}, _convert(Lab{T}, c))

_convert{T<:Ufixed}(::Type{XYZ{T}}, c::LCHab) = _convert(XYZ{T}, _convert(Lab{eltype(c)}, c))
_convert{T<:Ufixed}(::Type{XYZ{T}}, c::DIN99) = _convert(XYZ{T}, _convert(Lab{eltype(c)}, c))
_convert{T<:Ufixed}(::Type{XYZ{T}}, c::DIN99o) = _convert(XYZ{T}, _convert(Lab{eltype(c)}, c))


function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    d==0 && return (d, d)
    u = 4c.x / d
    v = 9c.y / d
    return (u, v)
end


function _convert{T}(::Type{XYZ{T}}, c::Luv, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)

    a = (52 * (c.l==0 ? zero(T) : c.l / (c.u + 13 * c.l * u_wp)) - 1) / 3
    y = c.l > xyz_kappa * xyz_epsilon ? wp.y * ((c.l + 16) / 116)^3 : wp.y * c.l / xyz_kappa
    b = -5y
    d = y * (39 * (c.l==0 ? zero(T) : c.l / (c.v + 13 * c.l * v_wp)) - 5)
    x = d==b ? zero(T) : (d - b) / (a + 1//3)
    z = a * x + b + zero(T)

    XYZ{T}(x, y, z)
end

_convert{T}(::Type{XYZ{T}}, c::LCHuv) = _convert(XYZ{T}, _convert(Luv{T}, c))


function _convert{T}(::Type{XYZ{T}}, c::DIN99d)

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


function _convert{T}(::Type{XYZ{T}}, c::LMS)
    ans = CAT02_INV * [c.l, c.m, c.s]
    XYZ{T}(ans[1], ans[2], ans[3])
end


_convert{T}(::Type{XYZ{T}}, c::YIQ) = _convert(XYZ{T}, _convert(RGB{T}, c))
_convert{T}(::Type{XYZ{T}}, c::YCbCr) = _convert(XYZ{T}, _convert(RGB{T}, c))

_convert{T}(::Type{XYZ{T}}, c::RGB24) = _convert(XYZ{T}, _convert(RGB{T}, c))

# Everything to xyY
# -----------------

function _convert{T}(::Type{xyY{T}}, c::XYZ)

    x = c.x/(c.x + c.y + c.z)
    y = c.y/(c.x + c.y + c.z)

    xyY{T}(x, y, convert(typeof(x), c.y))

end

_convert{T}(::Type{xyY{T}}, c::Color) = _convert(xyY{T}, _convert(XYZ{T}, c))



# Everything to Lab
# -----------------

_convert{T}(::Type{Lab{T}}, c::AbstractRGB) = convert(Lab{T}, _convert(XYZ{T}, c))
_convert{T}(::Type{Lab{T}}, c::HSV) = _convert(Lab{T}, _convert(RGB{T}, c))
_convert{T}(::Type{Lab{T}}, c::HSL) = _convert(Lab{T}, _convert(RGB{T}, c))


function _convert{T}(::Type{Lab{T}}, c::XYZ, wp::XYZ)
    function f(v)
        v > xyz_epsilon ? cbrt(v) : (xyz_kappa * v + 16) / 116
    end

    fx, fy, fz = f(c.x / wp.x), f(c.y / wp.y), f(c.z / wp.z)
    Lab{T}(116fy - 16, 500(fx - fy), 200(fy - fz))
end


_convert{T}(::Type{Lab{T}}, c::XYZ{T}) = _convert(Lab{T}, c, WP_DEFAULT)


function _convert{T}(::Type{Lab{T}}, c::LCHab)
    hr = deg2rad(c.h)
    Lab{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


function _convert{T}(::Type{Lab{T}}, c::DIN99)

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


function _convert{T}(::Type{Lab{T}}, c::DIN99o)

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


_convert{T}(::Type{Lab{T}}, c::Color) = _convert(Lab{T}, _convert(XYZ{T}, c))


# Everything to Luv
# -----------------

_convert{T}(::Type{Luv{T}}, c::AbstractRGB) = _convert(Luv{T}, _convert(XYZ{T}, c))
_convert{T}(::Type{Luv{T}}, c::HSV) = _convert(Luv{T}, _convert(RGB{T}, c))
_convert{T}(::Type{Luv{T}}, c::HSL) = _convert(Luv{T}, _convert(RGB{T}, c))


function _convert{T}(::Type{Luv{T}}, c::XYZ, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y

    l = y > xyz_epsilon ? 116 * cbrt(y) - 16 : xyz_kappa * y
    u = 13 * l * (u_ - u_wp) + zero(T)
    v = 13 * l * (v_ - v_wp) + zero(T)

    Luv{T}(l, u, v)
end


function _convert{T}(::Type{Luv{T}}, c::LCHuv)
    hr = deg2rad(c.h)
    Luv{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


_convert{T}(::Type{Luv{T}}, c::Color) = _convert(Luv{T}, _convert(XYZ{T}, c))


# Everything to LCHuv
# -------------------

function _convert{T}(::Type{LCHuv{T}}, c::Luv)
    h = rad2deg(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv{T}(c.l, sqrt(c.u^2 + c.v^2), h)
end


_convert{T}(::Type{LCHuv{T}}, c::Color) = _convert(LCHuv{T}, _convert(Luv{T}, c))


# Everything to LCHab
# -------------------

function _convert{T}(::Type{LCHab{T}}, c::Lab)
    h = rad2deg(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab{T}(c.l, sqrt(c.a^2 + c.b^2), h)
end


_convert{T}(::Type{LCHab{T}}, c::Color) = _convert(LCHab{T}, _convert(Lab{T}, c))


# Everything to DIN99
# -------------------

function _convert{T}(::Type{DIN99{T}}, c::Lab)

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


_convert{T}(::Type{DIN99{T}}, c::Color) = _convert(DIN99{T}, _convert(Lab{T}, c))


# Everything to DIN99d
# --------------------

function _convert{T}(::Type{DIN99d{T}}, c::XYZ{T})

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


_convert{T}(::Type{DIN99d{T}}, c::Color) = _convert(DIN99d{T}, _convert(XYZ{T}, c))


# Everything to DIN99o
# -------------------

function _convert{T}(::Type{DIN99o{T}}, c::Lab)

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


_convert{T}(::Type{DIN99o{T}}, c::Color) = _convert(DIN99o{T}, _convert(Lab{T}, c))


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


function _convert{T}(::Type{LMS{T}}, c::XYZ)
    ans = CAT02 * [c.x, c.y, c.z]
    LMS{T}(ans[1], ans[2], ans[3])
end


_convert{T}(::Type{LMS{T}}, c::Color) = _convert(LMS{T}, _convert(XYZ{T}, c))

# Everything to YIQ
# -----------------

correct_gamut{T}(c::YIQ{T}) = YIQ{T}(clamp(c.y, zero(T), one(T)),
                                     clamp(c.i, convert(T,-0.5957), convert(T,0.5957)),
                                     clamp(c.q, convert(T,-0.5226), convert(T,0.5226)))

function _convert{T}(::Type{YIQ{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    YIQ{T}(0.299*rgb.r+0.587*rgb.g+0.114*rgb.b,
           0.595716*rgb.r-0.274453*rgb.g-0.321263*rgb.b,
           0.211456*rgb.r-0.522591*rgb.g+0.311135*rgb.b)
end

_convert{T}(::Type{YIQ{T}}, c::Color) = _convert(YIQ{T}, _convert(RGB{T}, c))


# Everything to YCbCr
# -------------------

correct_gamut{T}(c::YCbCr{T}) = YCbCr{T}(clamp(c.y, convert(T,16), convert(T,235)),
                                         clamp(c.cb, convert(T,16), convert(T,240)),
                                         clamp(c.cr, convert(T,16), convert(T,240)))

function _convert{T}(::Type{YCbCr{T}}, c::AbstractRGB)
    rgb = correct_gamut(c)
    YCbCr{T}(16+65.481*rgb.r+128.553*rgb.g+24.966*rgb.b,
             128-37.797*rgb.r-74.203*rgb.g+112*rgb.b,
             128+112*rgb.r-93.786*rgb.g-18.214*rgb.b)
end

_convert{T}(::Type{YCbCr{T}}, c::Color) = _convert(YCbCr{T}, _convert(RGB{T}, c))

# Everything to RGB24
# -------------------

convert(::Type{RGB24}, c::AbstractRGB{Ufixed8}) = RGB24(c.r, c.g, c.b)
convert(::Type{RGB24}, c::AbstractRGB) = RGB24(round(UInt32, 255*c.r)<<16 +
                                               round(UInt32, 255*c.g)<<8 +
                                               round(UInt32, 255*c.b))
to32(x::Ufixed8) = convert(UInt32, reinterpret(x))
convert(::Type{RGB24}, val::UInt32) = RGB24(val & 0x00ffffff)

convert(::Type{RGB24}, c::Color) = convert(RGB24, convert(RGB{Ufixed8}, c))

# To UInt32
# ----------------

convert(::Type{UInt32}, c::RGB24) = c.color


convert(::Type{UInt32}, ac::ARGB32) = ac.color


# To ARGB32
# ----------------

convert{CV<:AbstractRGB{Ufixed8}}(::Type{ARGB32}, c::Transparent{CV}) =
    ARGB32(c.r, c.g, c.b, c.alpha)
convert(::Type{ARGB32}, c::Transparent) =
    ARGB32(convert(RGB24, c).color | round(UInt32, 255*c.alpha)<<24)
convert(::Type{ARGB32}, c::Color) = ARGB32(convert(RGB24, c).color | 0xff000000)
convert(::Type{ARGB32}, val::UInt32) = ARGB32(val)
convert(::Type{ARGB32}, c::Color, alpha) = ARGB32(convert(RGB24, c).color | round(UInt32, 255*alpha)<<24)

for C in subtypes(AbstractRGB)
    for A in (alphacolor(C), coloralpha(C))
        @eval begin
            function convert(::Type{$A{U8}}, ac::ARGB32)
                $A(Ufixed8(ac.color&0x00ff0000>>>16,0),
                   Ufixed8(ac.color&0x0000ff00>>>8,0),
                   Ufixed8(ac.color&0x000000ff,0),
                   Ufixed8(ac.color>>>24,0))
            end
            function convert{T}(::Type{$A{T}}, ac::ARGB32)
                $A{T}((ac.color&0x00ff0000>>>16)/255,
                      (ac.color&0x0000ff00>>>8)/255,
                      (ac.color&0x000000ff)/255,
                      (ac.color>>>24)/255)
            end
        end
    end
end
