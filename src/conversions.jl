# Conversions
# -----------

# no-op conversions

for CV in CVparametric
    @eval begin
        convert{T}(::Type{$CV{T}}, c::$CV{T}) = c
        convert(::Type{$CV}, c::$CV) = c
    end
end
convert(::RGB24, c::RGB24) = c
convert(::ARGB32, c::ARGB32) = c

# changing the datatype without changing the underlying colorspace
# Note: this assumes that the underlying type constructor doesn't swap the layout!
for CV in CVparametric
    @eval begin
        convert{T}(::Type{$CV{T}}, c::$CV) = $CV{T}(convert(T, getfield(c, 1)), convert(T, getfield(c, 2)), convert(T, getfield(c, 3)))
    end
end


# Conversions where the datatype is not specified
for (ElementClass, Colorspace) in [(Fractional, CVfractional), (FloatingPoint, CVfloatingpoint)]
    for CV in Colorspace
        @eval begin
            # preserves the datatype of the original space
            convert{T<:$ElementClass}(::Type{$CV}, c::ColorValue{T}) = convert($CV{T}, c)
            # fallback is Float64 (needed for RGB24)
            convert{T}(::Type{$CV}, c::ColorValue{T}) = convert($CV{Float64}, c)
        end
    end
end
convert{T}(::Type{RGB}, c::ColorValue{T}) = _convert(RGB{T}, c)
convert{T}(::Type{RGB{T}}, c::ColorValue) = _convert(RGB{T}, c)
convert(::Type{RGB}, c::RGB24) = _convert(RGB{Float64}, c)


# Everything to RGB
# -----------------

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

const M_XYZ_RGB = [ 3.2404542 -1.5371385 -0.4985314
                   -0.9692660  1.8760108  0.0415560
                    0.0556434 -0.2040259  1.0572252 ]


correct_gamut{CV<:AbstractRGB}(c::CV) = CV(clamp01(c.r), clamp01(c.g), clamp01(c.b))
clamp01{T<:Fractional}(v::T) = ifelse(v < zero(T), zero(T), ifelse(v > one(T), one(T), v))


function srgb_compand(v)
    v <= 0.0031308 ? 12.92v : 1.055v^(1/2.4) - 0.055
end


function _convert{CV<:AbstractRGB}(::Type{CV}, c::XYZ)
    ans = M_XYZ_RGB * [c.x, c.y, c.z]
    correct_gamut(CV(srgb_compand(ans[1]),
                     srgb_compand(ans[2]),
                     srgb_compand(ans[3])))
end

_convert{CV<:AbstractRGB}(::Type{CV}, c::xyY)    = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::Lab)    = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::LCHab)  = _convert(CV, convert(Lab{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::Luv)    = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::LCHuv)  = _convert(CV, convert(Luv{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::DIN99)  = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::DIN99o) = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::DIN99d) = _convert(CV, convert(XYZ{eltype(c)}, c))
_convert{CV<:AbstractRGB}(::Type{CV}, c::LMS)    = _convert(CV, convert(XYZ{eltype(c)}, c))

_convert{CV<:AbstractRGB{Ufixed8}}(::Type{CV}, c::RGB24) = CV(Ufixed8(c.color&0x00ff0000>>>16,0), Ufixed8(c.color&0x0000ff00>>>8,0), Ufixed8(c.color&0x000000ff,0))
_convert{CV<:AbstractRGB}(::Type{CV}, c::RGB24) = CV((c.color&0x00ff0000>>>16)/255, ((c.color&0x0000ff00)>>>8)/255, (c.color&0x000000ff)/255)


# Everything to HSV
# -----------------

function convert{T}(::Type{HSV{T}}, c::AbstractRGB)
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


convert{T}(::Type{HSV{T}}, c::ColorValue) = convert(HSV{T}, convert(RGB{T}, c))


# Everything to HSL
# -----------------

function convert{T}(::Type{HSL{T}}, c::AbstractRGB)
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


convert{T}(::Type{HSL{T}}, c::ColorValue) = convert(HSL{T}, convert(RGB{T}, c))


# Everything to XYZ
# -----------------

function invert_rgb_compand(v)
    v <= 0.04045 ? v/12.92 : ((v+0.055) /1.055)^2.4
end


const M_RGB_XYZ =
    [ 0.4124564  0.3575761  0.1804375
      0.2126729  0.7151522  0.0721750
      0.0193339  0.1191920  0.9503041 ]


function convert{T}(::Type{XYZ{T}}, c::AbstractRGB)
    v = [invert_rgb_compand(c.r),
         invert_rgb_compand(c.g),
         invert_rgb_compand(c.b)]
    ans = M_RGB_XYZ * v
    XYZ{T}(ans[1], ans[2], ans[3])
end


convert{T}(::Type{XYZ{T}}, c::HSV) = convert(XYZ{T}, convert(RGB{T}, c))
convert{T}(::Type{XYZ{T}}, c::HSL) = convert(XYZ{T}, convert(RGB{T}, c))


function convert{T}(::Type{XYZ{T}}, c::xyY)
    X = c.Y*c.x/c.y
    Z = c.Y*(1-c.x-c.y)/c.y
    XYZ{T}(X, c.Y, Z)
end


const xyz_epsilon = 216 // 24389
const xyz_kappa   = 24389 // 27


function convert{T}(::Type{XYZ{T}}, c::Lab, wp::XYZ)
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


convert{T}(::Type{XYZ{T}}, c::Lab)   = convert(XYZ{T}, c, WP_DEFAULT)
convert{T}(::Type{XYZ{T}}, c::LCHab) = convert(XYZ{T}, convert(Lab{T}, c))
convert{T}(::Type{XYZ{T}}, c::DIN99) = convert(XYZ{T}, convert(Lab{T}, c))
convert{T}(::Type{XYZ{T}}, c::DIN99o) = convert(XYZ{T}, convert(Lab{T}, c))

convert{T<:Ufixed}(::Type{XYZ{T}}, c::LCHab) = convert(XYZ{T}, convert(Lab{eltype(c)}, c))
convert{T<:Ufixed}(::Type{XYZ{T}}, c::DIN99) = convert(XYZ{T}, convert(Lab{eltype(c)}, c))
convert{T<:Ufixed}(::Type{XYZ{T}}, c::DIN99o) = convert(XYZ{T}, convert(Lab{eltype(c)}, c))


function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    d==0 && return (d, d)
    u = 4c.x / d
    v = 9c.y / d
    return (u, v)
end


function convert{T}(::Type{XYZ{T}}, c::Luv, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)

    a = (52 * (c.l==0 ? zero(T) : c.l / (c.u + 13 * c.l * u_wp)) - 1) / 3
    y = c.l > xyz_kappa * xyz_epsilon ? wp.y * ((c.l + 16) / 116)^3 : wp.y * c.l / xyz_kappa
    b = -5y
    d = y * (39 * (c.l==0 ? zero(T) : c.l / (c.v + 13 * c.l * v_wp)) - 5)
    x = d==b ? zero(T) : (d - b) / (a + 1//3)
    z = a * x + b + zero(T)

    XYZ{T}(x, y, z)
end

convert{T}(::Type{XYZ{T}}, c::LCHuv) = convert(XYZ{T}, convert(Luv{T}, c))
convert{T<:Ufixed}(::Type{XYZ{T}}, c::LCHuv) = convert(XYZ{T}, convert(Luv{eltype(c)}, c))


function convert{T}(::Type{XYZ{T}}, c::DIN99d)

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


function convert{T}(::Type{XYZ{T}}, c::LMS)
    ans = CAT02_INV * [c.l, c.m, c.s]
    XYZ{T}(ans[1], ans[2], ans[3])
end

convert{T}(::Type{XYZ{T}}, c::RGB24) = convert(XYZ{T}, convert(RGB{T}, c))

# Everything to xyY
# -----------------

function convert{T}(::Type{xyY{T}}, c::XYZ)

    x = c.x/(c.x + c.y + c.z)
    y = c.y/(c.x + c.y + c.z)

    xyY{T}(x, y, convert(typeof(x), c.y))

end

convert{T}(::Type{xyY{T}}, c::ColorValue) = convert(xyY{T}, convert(XYZ{T}, c))



# Everything to Lab
# -----------------

convert{T}(::Type{Lab{T}}, c::AbstractRGB) = convert(Lab{T}, convert(XYZ{T}, c))
convert{T}(::Type{Lab{T}}, c::HSV) = convert(Lab{T}, convert(RGB{T}, c))
convert{T}(::Type{Lab{T}}, c::HSL) = convert(Lab{T}, convert(RGB{T}, c))


function convert{T}(::Type{Lab{T}}, c::XYZ, wp::XYZ)
    function f(v)
        v > xyz_epsilon ? cbrt(v) : (xyz_kappa * v + 16) / 116
    end

    fx, fy, fz = f(c.x / wp.x), f(c.y / wp.y), f(c.z / wp.z)
    Lab{T}(116fy - 16, 500(fx - fy), 200(fy - fz))
end


convert{T}(::Type{Lab{T}}, c::XYZ{T}) = convert(Lab{T}, c, WP_DEFAULT)


function convert{T}(::Type{Lab{T}}, c::LCHab)
    hr = deg2rad(c.h)
    Lab{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


function convert{T}(::Type{Lab{T}}, c::DIN99)

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


function convert{T}(::Type{Lab{T}}, c::DIN99o)

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


convert{T}(::Type{Lab{T}}, c::ColorValue) = convert(Lab{T}, convert(XYZ{T}, c))


# Everything to Luv
# -----------------

convert{T}(::Type{Luv{T}}, c::AbstractRGB) = convert(Luv{T}, convert(XYZ{T}, c))
convert{T}(::Type{Luv{T}}, c::HSV) = convert(Luv{T}, convert(RGB{T}, c))
convert{T}(::Type{Luv{T}}, c::HSL) = convert(Luv{T}, convert(RGB{T}, c))


function convert{T}(::Type{Luv{T}}, c::XYZ, wp::XYZ = WP_DEFAULT)
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y

    l = y > xyz_epsilon ? 116 * cbrt(y) - 16 : xyz_kappa * y
    u = 13 * l * (u_ - u_wp) + zero(T)
    v = 13 * l * (v_ - v_wp) + zero(T)

    Luv{T}(l, u, v)
end


function convert{T}(::Type{Luv{T}}, c::LCHuv)
    hr = deg2rad(c.h)
    Luv{T}(c.l, c.c * cos(hr), c.c * sin(hr))
end


convert{T}(::Type{Luv{T}}, c::ColorValue) = convert(Luv{T}, convert(XYZ{T}, c))


# Everything to LCHuv
# -------------------

function convert{T}(::Type{LCHuv{T}}, c::Luv)
    h = rad2deg(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv{T}(c.l, sqrt(c.u^2 + c.v^2), h)
end


convert{T}(::Type{LCHuv{T}}, c::ColorValue) = convert(LCHuv{T}, convert(Luv{T}, c))


# Everything to LCHab
# -------------------

function convert{T}(::Type{LCHab{T}}, c::Lab)
    h = rad2deg(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab{T}(c.l, sqrt(c.a^2 + c.b^2), h)
end


convert{T}(::Type{LCHab{T}}, c::ColorValue) = convert(LCHab{T}, convert(Lab{T}, c))


# Everything to DIN99
# -------------------

function convert{T}(::Type{DIN99{T}}, c::Lab)

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


convert{T}(::Type{DIN99{T}}, c::ColorValue) = convert(DIN99{T}, convert(Lab{T}, c))


# Everything to DIN99d
# --------------------

function convert{T}(::Type{DIN99d{T}}, c::XYZ{T})

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


convert{T}(::Type{DIN99d{T}}, c::ColorValue) = convert(DIN99d{T}, convert(XYZ{T}, c))


# Everything to DIN99o
# -------------------

function convert{T}(::Type{DIN99o{T}}, c::Lab)

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


convert{T}(::Type{DIN99o{T}}, c::ColorValue) = convert(DIN99o{T}, convert(Lab{T}, c))


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


function convert{T}(::Type{LMS{T}}, c::XYZ{T})
    ans = CAT02 * [c.x, c.y, c.z]
    LMS{T}(ans[1], ans[2], ans[3])
end


convert{T}(::Type{LMS{T}}, c::ColorValue) = convert(LMS{T}, convert(XYZ{T}, c))


# Everything to RGB24
# -------------------

convert(::Type{RGB24}, c::AbstractRGB{Ufixed8}) = RGB24(c.r, c.g, c.b)
convert(::Type{RGB24}, c::AbstractRGB) = RGB24(round(Uint32, 255*c.r)<<16 +
                                               round(Uint32, 255*c.g)<<8 +
                                               round(Uint32, 255*c.b))
to32(x::Ufixed8) = convert(Uint32, reinterpret(x))
convert(::Type{RGB24}, val::Uint32) = RGB24(val & 0x00ffffff)

convert(::Type{RGB24}, c::ColorValue) = convert(RGB24, convert(RGB{Ufixed8}, c))

# To Uint32
# ----------------

convert(::Type{Uint32}, c::RGB24) = c.color


convert(::Type{Uint32}, ac::ARGB32) = ac.color


#### AlphaColorValue

convert{C,T}(::Type{AlphaColorValue{C,T}}, c::AlphaColorValue{C,T}) = c
function convert{C,T,D,U}(::Type{AlphaColorValue{C,T}}, c::AbstractAlphaColorValue{D,U})
    AlphaColorValue{C,T}(convert(C, c.c), c.alpha)
end
for CV in CVAlpha
    @eval begin
        function convert{D,T}(AC::Type{$CV}, c::AbstractAlphaColorValue{D,T})
            AlphaColorValue(convert(colortype($CV), c.c), c.alpha)
        end
        convert(AC::Type{$CV}, c::ColorValue) = AlphaColorValue(convert(colortype($CV), c))
    end
end

convert{C,T}(::Type{AlphaColorValue{C,T}}, c::ColorValue) =
    AlphaColorValue{C,T}(convert(C, c), one(T))
convert{C<:ColorValue,D,T}(::Type{C}, c::AlphaColorValue{D, T}) = convert(C, c.c)

convert(::Type{ARGB32}, c::ARGB32) = c
convert{CV<:AbstractRGB{Ufixed8}}(::Type{ARGB32}, c::AbstractAlphaColorValue{CV,Ufixed8}) =
    ARGB32(c.c.r, c.c.g, c.c.b, c.alpha)
convert(::Type{ARGB32}, c::AbstractAlphaColorValue) =
    ARGB32(convert(RGB24, c.c).color | round(Uint32, 255*c.alpha)<<24)
convert(::Type{ARGB32}, c::ColorValue) = ARGB32(convert(RGB24, c).color | 0xff000000)
convert(::Type{ARGB32}, val::Uint32) = ARGB32(val)

function convert(::Type{RGBA{Ufixed8}}, ac::ARGB32)
    RGBA{Ufixed8}(Ufixed8(ac.color&0x00ff0000>>>16,0),
                  Ufixed8(ac.color&0x0000ff00>>>8,0),
                  Ufixed8(ac.color&0x000000ff,0),
                  Ufixed8(ac.color>>>24,0))
end
function convert{T}(::Type{RGBA{T}}, c::ARGB32)
    RGBA{T}((c.color&0x00ff0000>>>16)/255,
            (c.color&0x0000ff00>>>8)/255,
            (c.color&0x000000ff)/255,
            (c.color>>>24)/255)
end
function convert{C,T}(::Type{AlphaColorValue{C,T}}, c::ARGB32)
    convert(AlphaColorValue{C,T}, convert(RGBA{Ufixed8}, c))
end

### Equality
==(c1::AbstractRGB, c2::AbstractRGB) = c1.r == c2.r && c1.g == c2.g && c1.b == c2.b
