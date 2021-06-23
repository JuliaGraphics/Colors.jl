# Conversions
# -----------

#=
`convert(C, c)` might be called as `convert(RGB, c)` or
`convert(RGB{Float32}, c)`.
This is handled in ColorTypes, which calls functions
```
    _convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c)
    _convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c, alpha)
```
Here are the argument types:
- `Cdest` may be any concrete `Colorant{T,N}` type. For parametric Color types
  it _always_ has the desired element type (e.g., `Float32`), so it's safe to
  dispatch on `Cdest <: Colorant{T}`.
- `Odest` and `Osrc` are opaque `Color` subtypes, i.e., things like `RGB` or
  `HSV`. They have no element type.
- `c` is the `Colorant` object you wish to convert.
- `alpha`, if present, is a user-supplied alpha value (to be used in place of
  any default alpha or alpha present in `c`).

The original motivation for this arrangement was that Julia "did not" support
"triangular dispatch", e.g.,
```
    convert(::Type{C{T}}, c) where {C, T}
```
On Julia v0.6 or later, parameter constraints can refer to previous parameters.
Threfore, we can use:
```
    convert(::Type{C}, c) where {T, C <: Colorant{T}}
```
However, the example above does not match `convert(RGB, c)`. Also, we should
catch all the various alpha variants (e.g. `ARGB`/`RGBA` with/without element
type).
The various arguments of `_convert` "peel off" element types (or guarantee them)
so that comparisons may be made via dispatch. Therefore, this arrangement is
still helpful.

Note that ColorTypes handles the cases where `Odest == Osrc`, or they are both
subtypes of `AbstractRGB` or `AbstractGray`. Therefore, here we only have to
deal with conversions between different spaces.
=#

function ColorTypes._convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, p, alpha=alpha(p)) where {Cdest<:TransparentColor,Odest,Osrc}
    # Convert the base color
    c = cnvt(color_type(Cdest), color(p))
    # Append the alpha
    ColorTypes._convert(Cdest, Odest, Odest, c, alpha)
end

ColorTypes._convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, c) where {Cdest<:Color,Odest,Osrc} = cnvt(Cdest, c)

# with the whitepoint `wp` as the third argument
convert(::Type{XYZ}, c, wp::XYZ) = cnvt(XYZ{eltype(wp)}, c, wp)
convert(::Type{Lab}, c, wp::XYZ) = cnvt(Lab{eltype(wp)}, c, wp)
convert(::Type{Luv}, c, wp::XYZ) = cnvt(Luv{eltype(wp)}, c, wp)

convert(::Type{XYZ{T}}, c, wp::XYZ) where {T} = cnvt(XYZ{T}, c, wp)
convert(::Type{Lab{T}}, c, wp::XYZ) where {T} = cnvt(Lab{T}, c, wp)
convert(::Type{Luv{T}}, c, wp::XYZ) where {T} = cnvt(Luv{T}, c, wp)

# Fallback to catch undefined operations
cnvt(::Type{C}, c::TransparentColor) where {C<:Color} = cnvt(C, color(c))
cnvt(::Type{C}, c) where {C} = convert(C, convert(RGB{eltype(C)}, c)::RGB{eltype(C)})

# Conversions from grayscale
# --------------------------
function ColorTypes._convert(::Type{Cdest}, ::Type{Odest}, ::Type{Osrc}, g) where {Cdest<:Color,Odest,Osrc<:AbstractGray}
    cnvt(Cdest, convert(RGB{eltype(Cdest)}, g))
end

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

correct_gamut(c::CV) where {CV<:AbstractRGB} = CV(clamp01(red(c)), clamp01(green(c)), clamp01(blue(c)))
correct_gamut(c::CV) where {T<:Union{N0f8,N0f16,N0f32,N0f64},
                            CV<:Union{AbstractRGB{T},TransparentRGB{T}}} = c
correct_gamut(c::CV) where {CV<:TransparentRGB} =
    CV(clamp01(red(c)), clamp01(green(c)), clamp01(blue(c)), clamp01(alpha(c))) # for `hex`

@inline function srgb_compand(v)
    F = typeof(0.5 * v)
    vf = F(v)
    vc = @fastmath max(vf, F(0.0031308))
    # `pow5_12` is an optimized function to get `v^(1/2.4)`
    vf > F(0.0031308) ? muladd(F(1.055), F(pow5_12(vc)), F(-0.055)) : F(12.92) * vf
end

function _hsx_to_rgb(im::UInt8, v, n, m)
    #=
    if     hue <  60; im = 0b000001 # ---------+
    elseif hue < 120; im = 0b000010 # --------+|
    elseif hue < 180; im = 0b000100 # -------+||
    elseif hue < 240; im = 0b001000 # ------+|||
    elseif hue < 300; im = 0b010000 # -----+||||
    else            ; im = 0b100000 # ----+|||||
    end                             #     ||||||
    (hue < 60 || hue >= 300) === ((im & 0b100001) != 0x0)
    =#
    r = ifelse((im & 0b100001) == 0x0, ifelse((im & 0b010010) == 0x0, m, n), v)
    g = ifelse((im & 0b000110) == 0x0, ifelse((im & 0b001001) == 0x0, m, n), v)
    b = ifelse((im & 0b011000) == 0x0, ifelse((im & 0b100100) == 0x0, m, n), v)
    return (r, g, b)
end
function _hsx_to_rgb(im::UInt8, v::T, n::T, m::T) where T <:Union{Float16, Float32, Float64}
    vu, nu, mu = reinterpret.(Unsigned, (v, n, m)) # prompt the compiler to use conditional moves
    r = ifelse((im & 0b100001) == 0x0, ifelse((im & 0b010010) == 0x0, mu, nu), vu)
    g = ifelse((im & 0b000110) == 0x0, ifelse((im & 0b001001) == 0x0, mu, nu), vu)
    b = ifelse((im & 0b011000) == 0x0, ifelse((im & 0b100100) == 0x0, mu, nu), vu)
    return reinterpret.(T, (r, g, b))
end

function cnvt(::Type{CV}, c::HSV) where {T, CV<:AbstractRGB{T}}
    F = promote_type(T, eltype(c))
    h, s, v = div60(F(c.h)), clamp01(F(c.s)), clamp01(F(c.v))
    hi = unsafe_trunc(Int32, h) # instead of floor
    i = h < 0 ? hi - one(hi) : hi
    f = i & one(i) == zero(i) ? 1 - (h - i) : h - i
    im = 0x1 << (mod6(UInt8, i) & 0x07)
    # use `@fastmath` just to reduce the estimated costs for inlining
    @fastmath m = v * (1 - s)
    @fastmath n = v * (1 - s * f)

    r, g, b = _hsx_to_rgb(im, v, n, m)
    T <: FixedPoint && typemax(T) >= 1 ? CV(r % T, g % T, b % T) : CV(r, g, b)
end

function cnvt(::Type{CV}, c::HSL) where {T, CV<:AbstractRGB{T}}
    F = promote_type(T, eltype(c))
    h, s, l = div60(F(c.h)), clamp01(F(c.s)), clamp01(F(c.l))
    a = @fastmath min(l, 1 - l) * s
    v = l + a
    hi = unsafe_trunc(Int32, h) # instead of floor
    i = h < 0 ? hi - one(hi) : hi
    f = i & one(i) == zero(i) ? 1 - (h - i) : h - i
    im = 0x1 << (mod6(UInt8, i) & 0x07)
    # use `@fastmath` just to reduce the estimated costs for inlining
    @fastmath m = l - a # v - 2 * a
    @fastmath n = v - 2 * a * f

    r, g, b = _hsx_to_rgb(im, v, n, m)
    T <: FixedPoint && typemax(T) >= 1 ? CV(r % T, g % T, b % T) : CV(r, g, b)
end

function cnvt(::Type{CV}, c::HSI) where {T, CV<:AbstractRGB{T}}
    F = promote_type(T, eltype(c))
    h, s, i = deg2rad(normalize_hue(F(c.h))), clamp01(F(c.s)), clamp01(F(c.i))
    is = i * s
    if h < F(2π/3)
        @fastmath cosr = cos(h) / cos(F(π/3)-h)
        r0, g0, b0 = muladd(is, cosr, i), muladd(is, 1-cosr, i), i - is
    elseif h < F(4π/3)
        @fastmath cosr = cos(h-F(2π/3)) / cos(F(π)-h)
        r0, g0, b0 = i - is, muladd(is, cosr, i), muladd(is, 1-cosr, i)
    else
        @fastmath cosr = cos(h-F(4π/3)) / cos(F(5π/3)-h)
        r0, g0, b0 = muladd(is, 1-cosr, i), i - is, muladd(is, cosr, i)
    end
    r, g, b = min(r0, oneunit(F)), min(g0, oneunit(F)), min(b0, oneunit(F))
    T <: FixedPoint && typemax(T) >= 1 ? CV(r % T, g % T, b % T) : CV(r, g, b)
end

function cnvt(::Type{CV}, c::XYZ) where CV<:AbstractRGB
    r =  3.2404542*c.x - 1.5371385*c.y - 0.4985314*c.z
    g = -0.9692660*c.x + 1.8760108*c.y + 0.0415560*c.z
    b =  0.0556434*c.x - 0.2040259*c.y + 1.0572252*c.z
    CV(clamp01(srgb_compand(r)),
       clamp01(srgb_compand(g)),
       clamp01(srgb_compand(b)))
end

function cnvt(::Type{CV}, c::YIQ) where CV<:AbstractRGB
    cc = correct_gamut(c)
    CV(clamp01(cc.y+0.9563*cc.i+0.6210*cc.q),
       clamp01(cc.y-0.2721*cc.i-0.6474*cc.q),
       clamp01(cc.y-1.1070*cc.i+1.7046*cc.q))
end

function cnvt(::Type{CV}, c::YCbCr) where CV<:AbstractRGB
    cc = correct_gamut(c)
    ny = cc.y - 16
    ncb = cc.cb - 128
    ncr = cc.cr - 128
    CV(clamp01(0.004567ny - 1.39135e-7ncb + 0.0062586ncr),
       clamp01(0.004567ny - 0.00153646ncb - 0.0031884ncr),
       clamp01(0.004567ny + 0.00791058ncb - 2.79201e-7ncr))
end

# To avoid stack overflow, the source types which do not support direct or
# indirect conversion to RGB should be rejected.
cnvt(::Type{CV}, c::Union{LMS, xyY}              ) where {CV<:AbstractRGB} = cnvt(CV, convert(XYZ, c))
cnvt(::Type{CV}, c::Union{Lab, Luv, LCHab, LCHuv}) where {CV<:AbstractRGB} = cnvt(CV, convert(XYZ, c))
cnvt(::Type{CV}, c::Union{DIN99d, DIN99o, DIN99} ) where {CV<:AbstractRGB} = cnvt(CV, convert(XYZ, c))
@noinline function cnvt(::Type{CV}, @nospecialize(c::Color)) where {CV<:AbstractRGB}
    error("No conversion of ", c, " to ", CV, " has been defined")
end

# AbstractGray --> AbstractRGB conversions are implemented in ColorTypes.jl


# Everything to HSV
# -----------------

function cnvt(::Type{HSV{T}}, c::AbstractRGB) where T
    F = promote_type(T, eltype(c))
    r, g, b = F.((red(c), green(c), blue(c)))
    c_min = @fastmath min(min(r, g), b)
    c_max = @fastmath max(max(r, g), b)
    s0 = c_max - c_min
    s0 == zero(F) && return HSV{T}(zero(T), zero(T), T(c_max))
    s = @fastmath s0 / c_max

    # In general, it is dangerous to compare floating point numbers with `===`.
    diff = ifelse(c_max === r,  g - b,         ifelse(c_max === g,  b - r,  r - g))
    ofs  = ifelse(c_max === r, (g < b)*F(360), ifelse(c_max === g, F(120), F(240)))
    h0 = @fastmath diff * F(60) / s0

    HSV{T}(h0 + ofs, s, c_max)
end


cnvt(::Type{HSV{T}}, c::Color) where {T} = cnvt(HSV{T}, convert(RGB{T}, c))


# Everything to HSL
# -----------------

function cnvt(::Type{HSL{T}}, c::AbstractRGB) where T
    F = promote_type(T, eltype(c))
    r, g, b = F(red(c)), F(green(c)), F(blue(c))
    c_min = @fastmath min(min(r, g), b)
    c_max = @fastmath max(max(r, g), b)
    l0 = c_max + c_min
    s0 = c_max - c_min
    l = l0 * F(0.5)
    s0 == zero(F) && return HSL{T}(zero(T), zero(T), T(l))
    s = @fastmath s0 / min(l0, F(2) - l0)

    # In general, it is dangerous to compare floating point numbers with `===`.
    diff = ifelse(c_max === r,  g - b,         ifelse(c_max === g,  b - r,  r - g))
    ofs  = ifelse(c_max === r, (g < b)*F(360), ifelse(c_max === g, F(120), F(240)))
    h0 = @fastmath diff * F(60) / s0

    HSL{T}(h0 + ofs, s, l)
end


cnvt(::Type{HSL{T}}, c::Color) where {T} = cnvt(HSL{T}, convert(RGB{T}, c))


# Everything to HSI
# -----------------

# Since acosd() is slow, the following is "inline-worthy".
@inline function cnvt(::Type{HSI{T}}, c::AbstractRGB) where T
    rgb = correct_gamut(c)
    F = promote_type(T, eltype(c))
    r, g, b = F(red(rgb)), F(green(rgb)), F(blue(rgb))
    dnorm = @fastmath sqrt(((r-g)^2 + (r-b)^2 + (g-b)^2) * F(0.5))
    isum = r + g + b
    i = isum / F(3)
    dnorm == zero(F) && return HSI{T}(T(90), zero(T), T(i))
    val = muladd(g + b, F(-0.5), r) / dnorm
    h = @fastmath acosd(clamp(val, -oneunit(F), oneunit(F)))
    m = @fastmath min(min(r, g), b)
    s = oneunit(F) - m/i
    HSI{T}(b > g ? F(360) - h : h, s, i)
end

cnvt(::Type{HSI{T}}, c::Color) where {T} = cnvt(HSI{T}, convert(RGB{T}, c))

# Everything to XYZ
# -----------------

@inline function invert_srgb_compand(v)
    F = typeof(0.5 * v)
    vf = F(v)
    # `pow12_5` is an optimized function to get `x^2.4`
    vf > F(0.04045) ? pow12_5(muladd(F(1000/1055), vf, F(55/1055))) : F(100/1292) * vf
end

# lookup table for `N0f8` (the extra two elements are for `Float32` splines)
const invert_srgb_compand_n0f8 = [invert_srgb_compand(v/255.0) for v = 0:257]

function invert_srgb_compand(v::N0f8)
    @inbounds invert_srgb_compand_n0f8[reinterpret(UInt8, v) + 1]
end

function invert_srgb_compand(v::Float32)
    i = unsafe_trunc(Int32, v * 255)
    (i < 13 || i > 255) && return invert_srgb_compand(Float64(v))
    @inbounds y = view(invert_srgb_compand_n0f8, i:i+3)
    dv = v * 255.0 - i
    dv == 0.0 && @inbounds return y[2]
    if v < 0.38857287f0
        return @fastmath(y[2]+0.5*dv*((-2/3*y[1]- y[2])+(2y[3]-1/3*y[4])+
                                  dv*((     y[1]-2y[2])+  y[3]-
                                  dv*(( 1/3*y[1]- y[2])+( y[3]-1/3*y[4]) ))))
    else
        return @fastmath(y[2]+0.5*dv*((4y[3]-3y[2])-y[4]+dv*((y[4]-y[3])+(y[2]-y[3]))))
    end
end

function cnvt(::Type{XYZ{T}}, c::AbstractRGB) where T
    r = invert_srgb_compand(red(c))
    g = invert_srgb_compand(green(c))
    b = invert_srgb_compand(blue(c))
    XYZ{T}(0.4124564*r + 0.3575761*g + 0.1804375*b,
           0.2126729*r + 0.7151522*g + 0.0721750*b,
           0.0193339*r + 0.1191920*g + 0.9503041*b)
end


function cnvt(::Type{XYZ{T}}, c::xyY) where T
    X = c.Y*c.x/c.y
    Z = c.Y*(1-c.x-c.y)/c.y
    XYZ{T}(X, c.Y, Z)
end


const xyz_epsilon   = 216 / 24389 # (6/29)^3
const xyz_kappa     = 24389 / 27  # (29/6)^3*8
const xyz_kappa_inv = 27 / 24389

function cnvt(::Type{XYZ{T}}, c::Lab, wp::XYZ = WP_DEFAULT) where T
    fy = (c.l + 16) / 116
    fx = fy + c.a / 500
    fz = fy - c.b / 200

    fx3 = fx^3
    fy3 = fy^3
    fz3 = fz^3

    epsilon = oftype(fx3, xyz_epsilon)
    kappa_inv = oftype(fx3, xyz_kappa_inv)

    x = fx3 > epsilon ? fx3 : muladd(116, fx, -16) * kappa_inv
    y = fy3 > epsilon ? fy3 : c.l * kappa_inv
    z = fz3 > epsilon ? fz3 : muladd(116, fz, -16) * kappa_inv

    XYZ{T}(x*wp.x, y*wp.y, z*wp.z)
end


function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    d==0 && return (d, d)
    u = 4c.x / d
    v = 9c.y / d
    return (u, v)
end


function cnvt(::Type{XYZ{T}}, c::Luv, wp::XYZ = WP_DEFAULT) where T
    c.l == zero(c.l) && return XYZ{T}(zero(T), zero(T), zero(T))

    u_wp, v_wp = xyz_to_uv(wp)

    ls = c.l * oftype(u_wp, xyz_kappa_inv)
    y = c.l > 8 ? wp.y * ((c.l + 16) / 116)^3 : wp.y * ls

    u = c.u / (13c.l) + u_wp
    v = c.v / (13c.l) + v_wp
    v4 = 4v
    x = y * 9u / v4
    z = y * (12 - 3u - 20v) / v4
    XYZ{T}(x, y, z)
end

function cnvt(::Type{XYZ{T}}, c::DIN99d) where T

    # Go back to C-h space
    C = chroma(c)
    h = atan(c.b, c.a) - 50π/180

    # Intermediate terms
    G = (exp(C/22.5)-1)/0.06
    f, ee = G .* sincos(h)

    l = (exp(c.l/325.221)-1)/0.0036
    # a = ee*cosd(50) - f/1.14*sind(50)
    a = ee*0.6427876096865394 - f/1.14*0.766044443118978
    # b = ee*sind(50) - f/1.14*cosd(50)
    b = ee*0.766044443118978 + f/1.14*0.6427876096865394

    adj = convert(XYZ, Lab(l, a, b))

    XYZ{T}((adj.x + 0.12*adj.z)/1.12, adj.y, adj.z)

end


function cnvt(::Type{XYZ{T}}, c::LMS) where T
    @mul3x3 XYZ{T} CAT02_INV c.l c.m c.s
end

cnvt(::Type{XYZ{T}}, c::Union{LCHab, DIN99, DIN99o}) where {T} = cnvt(XYZ{T}, convert(Lab{T}, c))
cnvt(::Type{XYZ{T}}, c::LCHuv) where {T} = cnvt(XYZ{T}, convert(Luv{T}, c))
cnvt(::Type{XYZ{T}}, c::Color) where {T} = cnvt(XYZ{T}, convert(RGB{T}, c))

# Everything to xyY
# -----------------

function cnvt(::Type{xyY{T}}, c::XYZ) where T

    x = c.x/(c.x + c.y + c.z)
    y = c.y/(c.x + c.y + c.z)

    xyY{T}(x, y, convert(typeof(x), c.y))

end

cnvt(::Type{xyY{T}}, c::Color) where {T} = cnvt(xyY{T}, convert(XYZ{T}, c))



# Everything to Lab
# -----------------

@inline function fxyz2lab(v)
    ka = oftype(v, 841 / 108) # (29/6)^2 / 3 = xyz_kappa / 116
    kb = oftype(v, 16 / 116) # 4/29
    vc = @fastmath max(v, oftype(v, xyz_epsilon))
    @fastmath min(cbrt01(vc), muladd(ka, v, kb))
end

function cnvt(::Type{Lab{T}}, c::XYZ, wp::XYZ = WP_DEFAULT) where T
    f = mapc(fxyz2lab, mapc((x, y) -> x / y, c, wp))
    Lab{T}(muladd(116, f.y, -16), 500(f.x - f.y), 200(f.y - f.z))
end


function cnvt(::Type{Lab{T}}, c::LCHab) where T
    b, a = c.c .* sincos(deg2rad(c.h))
    Lab{T}(c.l, a, b)
end


function cnvt(::Type{Lab{T}}, c::DIN99) where T

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
    kch = 1
    ke = 1

    # Calculate Chroma (C99) in the DIN99 space
    cc = chroma(c)

    # Temporary variable for chroma
    g = (exp(0.045*cc*kch*ke)-1)/0.045

    # Temporary redness
    ee = cc > 0 ? g * c.a / cc : zero(g)

    # Temporary yellowness
    f = cc > 0 ? g * c.b / cc : zero(g)

    # CIELAB a*b*
    # ciea = ee*cosd(16) - (f/0.7)*sind(16)
    ciea = ee*0.9612616959383189 - (f/0.7)*0.27563735581699916
    # cieb = ee*sind(16) + (f/0.7)*cosd(16)
    cieb = ee*0.27563735581699916 + (f/0.7)*0.9612616959383189

    # CIELAB L*
    ciel = (exp(c.l*ke/105.51)-1)/0.0158

    Lab{T}(ciel, ciea, cieb)
end


function cnvt(::Type{Lab{T}}, c::DIN99o) where T

    # We assume the adjustment parameters are always 1; the standard recommends
    # that they not be changed from these values.
    kch = 1
    ke = 1

    # Calculate Chroma (C99) in the DIN99o space
    co = chroma(c)

    # hue angle h99o
    h = atan(c.b, c.a) - 26π/180

    # revert logarithmic chroma compression
    g = (exp(co*kch*ke/23.0)-1)/0.075

    # Temporary yellowness and redness
    fo, eo = g .* sincos(h)

    # CIELAB a*b* (revert b* axis compression)
    # ciea = eo*cosd(26) - (fo/0.83)*sind(26)
    ciea = eo*0.898794046299167 - (fo/0.83)*0.4383711467890774
    # cieb = eo*sind(26) + (fo/0.83)*cosd(26)
    cieb = eo*0.4383711467890774 + (fo/0.83)*0.898794046299167

    # CIELAB L* (revert logarithmic lightness compression)
    ciel = (exp(c.l*ke/303.67)-1)/0.0039

    Lab{T}(ciel, ciea, cieb)
end


cnvt(::Type{Lab{T}}, c::Color) where {T} = cnvt(Lab{T}, convert(XYZ{T}, c))


# Everything to Luv
# -----------------

function cnvt(::Type{Luv{T}}, c::XYZ, wp::XYZ = WP_DEFAULT) where T
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y
    epsilon = oftype(y, xyz_epsilon)
    kappa = oftype(y, xyz_kappa)

    l = y > epsilon ? 116 * cbrt(y) - 16 : kappa * y
    u = 13 * l * (u_ - u_wp)
    v = 13 * l * (v_ - v_wp)

    Luv{T}(l, u, v)
end


function cnvt(::Type{Luv{T}}, c::LCHuv) where T
    v, u = c.c .* sincos(deg2rad(c.h))
    Luv{T}(c.l, u, v)
end

cnvt(::Type{Luv{T}}, c::Color) where {T} = cnvt(Luv{T}, convert(XYZ{T}, c))


# Everything to LCHuv
# -------------------

function cnvt(::Type{LCHuv{T}}, c::Luv) where T
    LCHuv{T}(c.l, chroma(c), hue(c))
end


cnvt(::Type{LCHuv{T}}, c::Color) where {T} = cnvt(LCHuv{T}, convert(Luv{T}, c))


# Everything to LCHab
# -------------------

function cnvt(::Type{LCHab{T}}, c::Lab) where T
    LCHab{T}(c.l, chroma(c), hue(c))
end


cnvt(::Type{LCHab{T}}, c::Color) where {T} = cnvt(LCHab{T}, convert(Lab{T}, c))


# Everything to DIN99
# -------------------

function cnvt(::Type{DIN99{T}}, c::Lab) where T

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

    # DIN99 chroma
    cc = log(1+0.045*g)/(0.045*kch*ke)

    # DIN99 chromaticities
    a99 = g > 0 ? convert(T, cc / g * ee) : zero(T)
    b99 = g > 0 ? convert(T, cc / g * f ) : zero(T)

    DIN99{T}(l99, a99, b99)

end


cnvt(::Type{DIN99{T}}, c::Color) where {T} = cnvt(DIN99{T}, convert(Lab{T}, c))


# Everything to DIN99d
# --------------------

function cnvt(::Type{DIN99d{T}}, c::XYZ{T}) where T

    # Apply tristimulus-space correction term
    adj_c = XYZ(1.12*c.x - 0.12*c.z, c.y, c.z)

    # Apply L*a*b*-space correction
    lab = convert(Lab, adj_c)
    adj_L = 325.221*log(1+0.0036*lab.l)

    # Calculate intermediate parameters
    # ee = lab.a*cosd(50) + lab.b*sind(50)
    ee = lab.a*0.6427876096865394 + lab.b*0.766044443118978
    # f = 1.14*(lab.b*cosd(50) - lab.a*sind(50))
    f = 1.14*(lab.b*0.6427876096865394 - lab.a*0.766044443118978)
    G = sqrt(ee^2+f^2)

    # Calculate hue/chroma
    C = 22.5*log(1+0.06*G)
    h = atan(f, ee) + 50π/180

    b99, a99 = C .* sincos(h)

    DIN99d{T}(adj_L, a99, b99)

end


cnvt(::Type{DIN99d{T}}, c::Color) where {T} = cnvt(DIN99d{T}, convert(XYZ{T}, c))


# Everything to DIN99o
# -------------------

function cnvt(::Type{DIN99o{T}}, c::Lab) where T

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
    h = atan(fo, eo) + 26π/180

    # DIN99o chroma (logarithmic compression)
    cc = 23.0*log(1+0.075*go)/(kch*ke)

    # DIN99o chromaticities
    b99, a99 = cc .* sincos(h)

    DIN99o{T}(l99, a99, b99)

end


cnvt(::Type{DIN99o{T}}, c::Color) where {T} = cnvt(DIN99o{T}, convert(Lab{T}, c))


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


function cnvt(::Type{LMS{T}}, c::XYZ) where T
    @mul3x3 LMS{T} CAT02 c.x c.y c.z
end


cnvt(::Type{LMS{T}}, c::Color) where {T} = cnvt(LMS{T}, convert(XYZ{T}, c))

# Everything to YIQ
# -----------------

correct_gamut(c::YIQ{T}) where {T} = YIQ{T}(clamp(c.y, zero(T), one(T)),
                                     clamp(c.i, convert(T,-0.5957), convert(T,0.5957)),
                                     clamp(c.q, convert(T,-0.5226), convert(T,0.5226)))

function cnvt(::Type{YIQ{T}}, c::AbstractRGB) where T
    rgb = correct_gamut(c)
    YIQ{T}(0.299*red(rgb)+0.587*green(rgb)+0.114*blue(rgb),
           0.595716*red(rgb)-0.274453*green(rgb)-0.321263*blue(rgb),
           0.211456*red(rgb)-0.522591*green(rgb)+0.311135*blue(rgb))
end

cnvt(::Type{YIQ{T}}, c::Color) where {T} = cnvt(YIQ{T}, convert(RGB{T}, c))


# Everything to YCbCr
# -------------------

correct_gamut(c::YCbCr{T}) where {T} = YCbCr{T}(clamp(c.y, convert(T,16), convert(T,235)),
                                         clamp(c.cb, convert(T,16), convert(T,240)),
                                         clamp(c.cr, convert(T,16), convert(T,240)))

function cnvt(::Type{YCbCr{T}}, c::AbstractRGB) where T
    rgb = correct_gamut(c)
    YCbCr{T}(16+65.481*red(rgb)+128.553*green(rgb)+24.966*blue(rgb),
             128-37.797*red(rgb)-74.203*green(rgb)+112*blue(rgb),
             128+112*red(rgb)-93.786*green(rgb)-18.214*blue(rgb))
end

cnvt(::Type{YCbCr{T}}, c::Color) where {T} = cnvt(YCbCr{T}, convert(RGB{T}, c))


# To Gray
# -------
# AbstractGray --> AbstractRGB conversions are implemented in ColorTypes.jl, but
# AbstractRGB --> AbstractGray conversions should be implemented here.

# Rec 601 luma conversion

function cnvt(::Type{G}, x::AbstractRGB{T}) where {G<:AbstractGray,T<:Normed}
    TU, Tf = FixedPointNumbers.rawtype(T), floattype(T)
    if sizeof(TU) < sizeof(UInt)
        val = Tf(0.001)*(299*reinterpret(red(x)) + 587*reinterpret(green(x)) + 114*reinterpret(blue(x)))
    else
        val = Tf(0.299)*reinterpret(red(x)) + Tf(0.587)*reinterpret(green(x)) + Tf(0.114)*reinterpret(blue(x))
    end
    return G(reinterpret(T, round(TU, val)))
end
cnvt(::Type{G}, x::AbstractRGB) where {G<:AbstractGray} =
    G(0.299f0*red(x) + 0.587f0*green(x) + 0.114f0*blue(x))

cnvt(::Type{G}, x::Color) where {G<:AbstractGray} = convert(G, convert(RGB, x))
