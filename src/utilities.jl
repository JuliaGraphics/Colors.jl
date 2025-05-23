# Helper data for CIE observer functions
include("cie_data.jl")

# readonly static 3x3 matrix
struct Mat3x3{T} <: AbstractMatrix{T}
    e::NTuple{9, T}
end
Mat3x3(mat::Matrix{T}) where {T} = Mat3x3{T}(Tuple(mat))
Base.IndexStyle(::Type{<:Mat3x3}) = IndexLinear()
Base.size(::Mat3x3) = (3, 3)
Base.getindex(M::Mat3x3{T}, i::Int) where {T} = M.e[i]

macro mul3x3(C, M, c1, c2, c3)
    esc(quote
        F = typeof(0.5f0 * $c1) === Float32 ? Float32 : eltype($M)
        if $c1 isa N0f8 && $c2 isa N0f8 && $c3 isa N0f8
            s = 0xffffff
            c1x = Int32(reinterpret($c1)) * 0x10101
            c2x = Int32(reinterpret($c2)) * 0x10101
            c3x = Int32(reinterpret($c3)) * 0x10101
        else
            s = true
            c1x, c2x, c3x = $c1, $c2, $c3
        end
        @inbounds ret = $C(
            muladd(F($M[1,1] / s), c1x, muladd(F($M[1,2] / s), c2x, F($M[1,3] / s) * c3x)),
            muladd(F($M[2,1] / s), c1x, muladd(F($M[2,2] / s), c2x, F($M[2,3] / s) * c3x)),
            muladd(F($M[3,1] / s), c1x, muladd(F($M[3,2] / s), c2x, F($M[3,3] / s) * c3x)))
        ret
    end)
end

# for optimization
div60(x) = x / 60
_div60(x::T) where T = muladd(x, T(1/960), x * T(0x1p-6))
if reduce(max, _div60.((90.0f0,))) == 1.5f0
    div60(x::T) where T <: Union{Float32, Float64} = _div60(x)
else
    # force two-step multiplication
    div60(x::T) where T <: Union{Float32, Float64} = x * T(0x1p-6) + x * T(1/960)
end

# mod6 supports the input `x` in [-2^28, 2^29]
mod6(::Type{T}, x::Int32) where T = unsafe_trunc(T, x - 6 * ((widemul(x, 0x2aaaaaaa) + Int64(0x20000000)) >> 0x20))

# Approximation of the reciprocal of the cube root, x^(-1/3).
# assuming that x > 0.003, the conditional branches are omitted.
@inline function rcbrt(x::Float64)
    ix = reinterpret(UInt64, x)
    e0 = (ix >> 0x34) % UInt32
    ed = e0 ÷ 0x3
    er = e0 - ed * 0x3
    a = 0x000b_f2d7 - 0x0005_5718 * er
    e = (UInt32(1363) - ed) << 0x14 | a
    t1 = reinterpret(Float64, UInt64(e) << 0x20)
    h1 = muladd(t1^2, -x * t1, 1.0)
    t2 = muladd(@evalpoly(h1, 1/3, 2/9, 14/81), h1 * t1, t1)
    h2 = muladd(t2^2, -x * t2, 1.0)
    t3 = muladd(muladd(2/9, h2, 1/3), h2 * t2, t2)
    reinterpret(Float64, reinterpret(UInt64, t3) & 0xffff_ffff_8000_0000)
end
@inline function rcbrt(x::Float32)
    ix = reinterpret(UInt32, x)
    e0 = ix >> 0x17 + 0x2
    ed = e0 ÷ 0x3
    er = e0 - ed * 0x3
    a = 0x005f_9cbe - 0x002a_bd7d * er
    t1 = reinterpret(Float32, (UInt32(169) - ed) << 0x17 | a)
    h1 = muladd(t1^2, -x * t1, 1.0f0)
    t2 = muladd(muladd(2/9f0, h1, 1/3f0), h1 * t1, t1)
    h2 = muladd(t2^2, -x * t2, 1.0f0)
    t3 = muladd(1/3f0, h2 * t2, t2)
    reinterpret(Float32, reinterpret(UInt32, t3) & 0xffff_f000)
end

cbrt01(x) = cbrt(x)
@inline function cbrt01(x::Float64)
    r = rcbrt(x) # x^(-1/3)
    h = muladd(r^2, -x * r, 1.0)
    e = muladd(2/9, h, 1/3) * h * r
    muladd(r, x * r, x * e * (r + r + e)) # x * x^(-2/3)
end
@inline function cbrt01(x::Float32)
    r = Float64(rcbrt(x)) # x^(-1/3)
    h = muladd(r^2, -Float64(x) * r, 1.0)
    e = muladd(muladd(14/81, h, 2/9), h, 1/3) * h
    Float32(1 / muladd(r, e, r))
end

pow3_4(x) = (y = @fastmath(sqrt(x)); y*@fastmath(sqrt(y))) # x^(3/4)

# `pow5_12` is called from `srgb_compand`.
pow5_12(x) = pow3_4(x) / cbrt(x) # 5/12 == 1/2 + 1/4 - 1/3 == 3/4 - 1/3
@inline function pow5_12(x::Float64)
    p3_4 = pow3_4(x)
    # x^(-1/6)
    if x < 0.02
        t0 = @evalpoly(x, 3.1366722556806232,
            -221.51395962221136, 19788.889459114234, -905934.6541469148, 1.5928561711645417e7)
    elseif x < 0.12
        t0 = @evalpoly(x, 2.3135905865468644,
            -26.43664640894651, 385.0146581045545, -2890.0920682466267, 8366.343115590817)
    elseif x < 1.2
        t0 = @evalpoly(x, 1.7047813285940905, -3.1261253501167308,
            7.498744828350077, -10.100319516746419, 6.820601476522508, -1.7978894213531524)
    else
        return p3_4 / cbrt01(x)
    end
    # x^(-1/3)
    t1 = t0 * t0
    h1 = muladd(t1^2, -x * t1, 1.0)
    t2 = muladd(h1, 1/3 * t1, t1)
    h2 = muladd(t2^2, -x * t2, 1.0)
    t2h = @evalpoly(h2, 1/3, 2/9, 14/81) * h2 * t2 # Taylor series of (1-h)^(-1/3)
    # x^(3/4) * x^(-1/3)
    muladd(p3_4, t2, p3_4 * t2h)
end
@inline function pow5_12(x::Float32)
    # x^(-1/3)
    rc = rcbrt(x)
    rcx = -rc * x
    rch = muladd(muladd(rc, x, rcx), -rc^2, muladd(rc^2, rcx, 1.0f0)) # 1 - x * rc^3
    rce = muladd(2/9f0, rch, 1/3f0) * rch * rc
    # x^(3/4)
    p3_4_f64 = pow3_4(Float64(x))
    p3_4r = reinterpret(Float64, reinterpret(UInt64, p3_4_f64) & 0xffffffff_e0000000)
    p3_4 = Float32(p3_4r)
    p3_4e = Float32(p3_4_f64 - p3_4r)
    # x^(3/4) * x^(-1/3)
    muladd(p3_4, rc, muladd(p3_4, rce, p3_4e * rc))
end

# `pow12_5` is called from `invert_srgb_compand`.
pow12_5(x) = pow12_5(Float64(x))
pow12_5(x::BigFloat) = x^big"2.4"
@inline function pow12_5(x::Float64)
    # x^0.4
    t1 = @evalpoly(@fastmath(min(x, 1.75)), 0.24295462640373672,
        1.7489099720303518, -1.9919942887850166, 1.3197188815160004, -0.3257258790067756)
    t2 = muladd(2/5, muladd(x / t1^2, @fastmath(sqrt(t1)), -t1), t1) # Newton's method
    t3 = muladd(2/5, muladd(x / t2^2, @fastmath(sqrt(t2)), -t2), t2)
    t4 = muladd(2/5, muladd(x / t3^2, @fastmath(sqrt(t3)), -t3), t3)
    # x^0.4 * x^2
    rx = reinterpret(Float64, reinterpret(UInt64, x) & 0xffffffff_f8000000) # hi
    e = x - rx # lo
    muladd(t4, rx^2, t4 * (rx + rx + e) * e)
end

pow7(x) = (y = x*x*x; y*y*x)

# TODO: migrate to ColorTypes.jl
@inline function atan360_kernel(t::Float64)
    @evalpoly(t^2,
        0.8952465548919112,  -0.2984155182972285,   0.1790493109637673,   -0.12789236387151418,
        0.09947179554077099, -0.08138502549008089,  0.06884985860325084,  -0.059532134551367105,
        0.05164982834653973, -0.042514874197367984, 0.028600080170923112, -0.011001809246782802)
end
@inline function atan360_kernel(t::Float32)
    @evalpoly(t^2,
        0.89524657f0, -0.2984143f0, 0.17899014f0, -0.12683357f0, 0.090689056f0, -0.045563098f0)
end

# a variant of `atand` returning the angle in the range of [0, 360]
atan360(y, x) = (a = atand(y, x); signbit(a) ? oftype(a, a + 360) : a)
@inline function atan360(y::T, x::T) where T <: Union{Float32, Float64}
    (isnan(x) | isnan(y)) && return T(NaN)
    ax, ay = abs(x), abs(y)
    n, m = minmax(ax, ay)
    if m == T(Inf)
        d0 = n == T(Inf) ? T(45) : T(0)
    else
        m = m == T(0) ? T(0.5) : m
        ta = (n + n) > m ? T(0.5) : T(0) # 1-step CORDIC
        # ro=(n + n) > m ? T(atand(0.5) / 64) : T(0)
        ro = max(T(0), ta - T(0.5 - 0.4150789246418436))
        n1 = n - ta * m
        m1 = m + ta * n
        t = n1 / m1 # in [0, 0.5]
        p = atan360_kernel(t)
        d0 = muladd(t, p, ro) * T(64)
    end
    b1 = T( 90) + flipsign(T( -90), x)
    b2 = T(180) + flipsign(T(-180), y)
    d1 = ay > ax ? T(90) - d0 : d0
    d2 = b1 + flipsign(d1, x) # signbit(x) ? T(180) - d1 : d1
    dd = b2 + flipsign(d2, y) # signbit(y) ? T(360) - d2 : d2
    return dd
end

# override only the `Lab`, `Luv`, and `Oklab` versions just for now
@inline ColorTypes.hue(c::Lab) = atan360(c.b, c.a)
@inline ColorTypes.hue(c::Luv) = atan360(c.v, c.u)
@inline ColorTypes.hue(c::Oklab) = atan360(c.b, c.a)

@inline function sin_kernel(x::Float64)
    x * @evalpoly(x^2,
        1.117010721276371, -0.23228479064016105, 0.014491237085286733, -0.00043049771889962576,
        7.460244157055791e-6, -8.462038405688494e-8, 6.767827147797153e-10, -3.987482394639226e-12)
end
@inline function sin_kernel(x::Float32)
    y = @evalpoly(x^2, 0.11701072f0, -0.23228478f0, 0.014491233f0, -0.0004304645f0, 7.368049f-6)
    muladd(x, y, x)
end
@inline function cos_kernel(x::Float64)
    @evalpoly(x^2, 1.0,
        -0.6238564757231793, 0.06486615038362423, -0.002697811198135598, 6.010882091788964e-5,
        -8.333171603045294e-7, 7.876495580576226e-9, -5.351642293798961e-11)
end
@inline function cos_kernel(x::Float32)
    @evalpoly(x^2, 1.0f0, -0.6238565f0,0.06486606f0,-0.002697325f0, 5.904168f-5)
end

sincos360(x) = sincos(deg2rad(x))
@inline function sincos360(x::T) where T <: Union{Float32, Float64}
    isfinite(x) || return T(NaN), T(NaN)
    t = x - round(x * T(1/360)) * 360 # [-180, 180]
    a0 = @fastmath abs(t)              # [0, 180]
    a1 = a0 <= 90 ? a0 : 180 - a0      # [0, 90]
    a2 = a1 <= 45 ? a1 : 90 - a1       # [0, 45]
    ax = a2 * T(1/64)
    sn, cs  = sin_kernel(ax), cos_kernel(ax)
    sn1, cs1 = a1 === a2 ? (sn, cs) : (cs, sn)
    return @fastmath flipsign(sn1, t), flipsign(cs1, 90 - a0)
end

"""
    x, y = polar_to_cartesian(r, theta)

Convert a polar coordinate of radius `r` and angle `theta` (in degrees) to a
Cartesian coordinate.
"""
@inline function polar_to_cartesian(r, theta)
    y, x = r .* sincos360(theta)
    return x, y
end

# Linear interpolation in [a, b] where x is in [0,1],
# or coerced to be if not.
function lerp(x, a, b)
    a + (b - a) * max(min(x, one(x)), zero(x))
end

clamp01(v::T) where {T<:Fractional} = ifelse(v < zero(T), zero(T), ifelse(v > oneunit(T), oneunit(T), v))
clamp01(v::T) where {T<:Union{Bool,N0f8,N0f16,N0f32,N0f64}} = v

"""
    HexNotation{C, A, N}

This is a private type for specifying the style of hex notations. It is not
recommended to use this type and its derived types in user scripts or other
packages, since they may change in the future without notice.

# Arguments
- `C`: a base colorant type.
- `A`: a symbol (`:upper` or `:lower`) to specify the letter casing.
- `N`: a total number of digits.
"""
abstract type HexNotation{C, A, N} end
abstract type HexAuto <: HexNotation{Colorant,:upper,0} end
abstract type HexShort{A} <: HexNotation{Colorant,A,0} end

"""
    hex(c::Colorant)
    hex(c::Colorant, style::Symbol)

Convert a color to a hexadecimal string, optionally specifying its style.

# Arguments
- `c`: a target color.
- `style`: a symbol to specify the hexadecimal notation. Specifying the
  uppercase symbols means the return values are in uppercase. The following
  symbols are available:
  - `:AUTO`: notation automatically selected according to the type of `c`
  - `:RRGGBB`/`:rrggbb`: 6-digit opaque notation
  - `:AARRGGBB`/`:aarrggbb`: 8-digit notation with alpha at the head
  - `:RRGGBBAA`/`:rrggbbaa`: 8-digit notation with alpha at the tail
  - `:RGB`/`:rgb`/`:ARGB`/`:argb`/`:RGBA`/`:rgba`: 3-digit or 4-digit noatation
  - `:S`/`:s`: short notation if available

# Examples
```jldoctest; setup = :(using Colors)
julia> hex(RGB(1,0.5,0))
"FF8000"

julia> hex(ARGB(1,0.5,0,0.25))
"40FF8000"

julia> hex(HSV(30,1.0,1.0), :AARRGGBB)
"FFFF8000"

julia> hex(ARGB(1,0.533,0,0.267), :rrggbbaa)
"ff880044"

julia> hex(ARGB(1,0.533,0,0.267), :rgba)
"f804"

julia> hex(ARGB(1,0.533,0,0.267), :S)
"4F80"
```

!!! compat "Colors v0.12"
    `style` requires at least Colors v0.12.
"""
hex(c::Colorant) = _hex(HexAuto, c) # there is no need to search the dictionary
hex(c::Colorant, style::Symbol) = _hex(get(_hex_styles, style, HexAuto), c)

const _hex_styles = Dict{Symbol, Type}(
    :AUTO => HexAuto,
    :S => HexShort{:upper}, :s => HexShort{:lower},
    :RGB => HexNotation{RGB,:upper,3}, :rgb => HexNotation{RGB,:lower,3},
    :ARGB => HexNotation{ARGB,:upper,4}, :argb => HexNotation{ARGB,:lower,4},
    :RGBA => HexNotation{RGBA,:upper,4}, :rgba => HexNotation{RGBA,:lower,4},
    :RRGGBB => HexNotation{RGB,:upper,6}, :rrggbb => HexNotation{RGB,:lower,6},
    :AARRGGBB => HexNotation{ARGB,:upper,8}, :aarrggbb => HexNotation{ARGB,:lower,8},
    :RRGGBBAA => HexNotation{RGBA,:upper,8}, :rrggbbaa => HexNotation{RGBA,:lower,8},
)
@inline function _hexstring(::Type{T}, u::U, itr) where {C, T <: HexNotation{C,:upper}, U <: Unsigned}
    s = UInt8(8sizeof(u) - 4)
    @inbounds String([b"0123456789ABCDEF"[((u << i) >> s) + 1] for i in itr])
end
@inline function _hexstring(::Type{T}, u::U, itr) where {C, T <: HexNotation{C,:lower}, U <: Unsigned}
    s = UInt8(8sizeof(u) - 4)
    @inbounds String([b"0123456789abcdef"[((u << i) >> s) + 1] for i in itr])
end

_to_uint32(c::Colorant) = reinterpret(UInt32, ARGB32(c))
_to_uint32(c::TransparentColor) = reinterpret(UInt32, alphacolor(RGB24(c), clamp01(alpha(c))))
_to_uint32(c::C) where C <: Union{AbstractRGB, TransparentRGB} =
    reinterpret(UInt32, ARGB32(correct_gamut(c)))
_to_uint32(c::C) where C <: Union{AbstractGray, TransparentGray} =
    reinterpret(UInt32, AGray32(clamp01(gray(c)), clamp01(alpha(c))))

_hex(t::Type, c::Colorant) = _hex(t, _to_uint32(c))

_hex(::Type{HexAuto}, c::Color) = _hex(HexNotation{RGB,:upper,6}, c)
_hex(::Type{HexAuto}, c::AlphaColor) = _hex(HexNotation{ARGB,:upper,8}, c)
_hex(::Type{HexAuto}, c::ColorAlpha) = _hex(HexNotation{RGBA,:upper,8}, c)

function _hex(::Type{HexShort{A}}, c::Colorant) where A
    u = _to_uint32(c)
    s = u == (u & 0x0F0F0F0F) * 0x11
    c isa AlphaColor && return _hex(HexNotation{ARGB, A, s ? 4 : 8}, u)
    c isa ColorAlpha && return _hex(HexNotation{RGBA, A, s ? 4 : 8}, u)
    _hex(HexNotation{RGB, A, s ? 3 : 6}, u)
end

# for 3-digit or 4-digit notations
function _hex(t::Type{T}, u::UInt32) where {C <:Union{RGB, ARGB, RGBA}, A, T <: HexNotation{C,A}}
    # To double the number of digits, we multiply each element by 17 (= 0x11).
    # Thus, we divide each element by 17 here, to halve the number of digits.
    u64 = UInt64(u)
    # TODO: use SIMD `move` with zero extension (e.g. vpmovzxbw)
    unpacked = ((u64 & 0xFF00FF00)<<24) | (u64 & 0x00FF00FF) # 0x00AA00GG00RR00BB
    # `all(x -> round(x / 17) == (x * 15 + 135) >> 8, 0:255) == true`
    q = muladd(unpacked, 0xF,  0x0087_0087_0087_0087) # 0x0Aaa0Ggg0Rrr0Bbb
    t <: HexNotation{ARGB} && return _hexstring(t, q, (0x04, 0x24, 0x14, 0x34))
    t <: HexNotation{RGBA} && return _hexstring(t, q, (0x24, 0x14, 0x34, 0x04))
    _hexstring(t, q, (0x24, 0x14, 0x34))
end

# for 6-digit or 8-digit notations
_hex(t::Type{HexNotation{ RGB,A,6}}, u::UInt32) where {A} = _hexstring(t, u, 0x8:0x4:0x1C)
_hex(t::Type{HexNotation{ARGB,A,8}}, u::UInt32) where {A} = _hexstring(t, u, 0x0:0x4:0x1C)
_hex(t::Type{HexNotation{RGBA,A,8}}, u::UInt32) where {A} =
    _hexstring(t, u, (0x8, 0xC, 0x10, 0x14, 0x18, 0x1C, 0x0, 0x4))

"""
    normalize_hue(h::Real)
    normalize_hue(c::Colorant)

Returns a normalized (wrapped-around) hue angle, or a color with the normalized
hue, in degrees, in [0, 360]. The normalization is essentially equivalent to
`mod(h, 360)`, but is faster at the expense of some accuracy.
"""
@fastmath normalize_hue(h::Real) = max(muladd(floor(h / 360), -360, h), zero(h))
@fastmath normalize_hue(h::Float16) = Float16(normalize_hue(Float32(h)))
normalize_hue(c::C) where {C <: Union{HSV, HSL, HSI}} = C(normalize_hue(c.h), c.s, comp3(c))
normalize_hue(c::C) where {Cb <: Union{HSV, HSL, HSI}, C <: Union{AlphaColor{Cb}, ColorAlpha{Cb}}} =
    C(normalize_hue(c.h), c.s, comp3(c), alpha(c))
normalize_hue(c::C) where C <: Union{LCHab, LCHuv, Oklch} = C(c.l, c.c, normalize_hue(c.h))
normalize_hue(c::C) where {Cb <: Union{LCHab, LCHuv, Oklch}, C <: Union{AlphaColor{Cb}, ColorAlpha{Cb}}} =
    C(c.l, c.c, normalize_hue(c.h), c.alpha)

"""
    mean_hue(h1::Real, h2::Real)
    mean_hue(a::C, b::C) where {C <: Colorant}

Compute the mean of two hue angles in degrees.

If the inputs are HSV-like or Lab-like color objects, this will also return a
hue, not a color. If one of the colors is achromatic, i.e. has zero saturation
or chroma, the hue of the other color is returned instead of the mean.

When the hue difference is exactly 180 degrees, which of the two mean hues is
returned depends on the implementation. In other words, it may vary by the color
type and version.
"""
mean_hue(a, b) = _mean_hue(promote(a, b)...)

_mean_hue(a, b) = error("input arguments to `mean_hue` could not promote to valid input types")
function _mean_hue(h1::T, h2::T) where {T <: Real}
    @fastmath hmin, hmax = minmax(h1, h2)
    d = 180 - normalize_hue(hmin - hmax - 180)
    F = typeof(zero(T) / 2)
    mh = muladd(F(0.5), d, hmin)
    return mh < 0 ? mh + 360 : mh
end
@inline function _mean_hue(a::C, b::C) where {Cb <: Union{Lab, Luv, Oklab},
                                     C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    a1, b1, a2, b2 = comp2(a), comp3(a), comp2(b), comp3(b)
    c1, c2 = chroma(a), chroma(b)
    k1 = c1 == zero(c1) ? oneunit(c1) : c1
    k2 = c2 == zero(c2) ? oneunit(c2) : c2
    dp = muladd(a1, a2, b1 * b2) # dot product
    dt = b1 * a2 - a1 * b2
    if dp < zero(dp)
        # 90 deg rotations
        a1, b1 = @fastmath flipsign( b1, dt), flipsign(-a1, dt)
        a2, b2 = @fastmath flipsign(-b2, dt), flipsign( a2, dt)
        if dt == zero(dt) && a1 > zero(a1)
            k1, k2 = -k1, -k2
        end
    end
    ma = muladd(k2, a1, k1 * a2)
    mb = muladd(k2, b1, k1 * b2)
    hue(Cb(zero(ma), ma, mb))
end
function _mean_hue(a::C, b::C) where {Cb <: Union{LCHab, LCHuv, Oklch},
                                     C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    _mean_hue(a.c == 0 ? b.h : a.h, b.c == 0 ? a.h : b.h)
end
function _mean_hue(a::C, b::C) where {Cb <: Union{HSV, HSL, HSI},
                                     C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    _mean_hue(a.s == 0 ? b.h : a.h, b.s == 0 ? a.h : b.h)
end

_delta_h_th(T) = zero(T)
_delta_h_th(::Type{Float32}) = 0.1f0
_delta_h_th(::Type{Float64}) = 6.5e-3

function delta_h(a::C, b::C) where {Cb <: Union{Lab, Luv, Oklab},
                                    C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    a1, b1, a2, b2 = comp2(a), comp3(a), comp2(b), comp3(b)
    c1, c2 = chroma(a), chroma(b)
    dp = muladd(a1, a2, b1 * b2) # dot product
    dt = b1 * a2 - a1 * b2
    if _delta_h_th(typeof(dp)) * dp <= abs(dt)
        if dp isa Float32 || dp < 0
            dh = @fastmath sqrt(2 * muladd(c1, c2, -dp))
        else
            da, db, dc = a1 - a2, b1 - b2, c1 - c2
            dh = @fastmath sqrt(max(muladd(dc, -dc, muladd(da, da, db^2)), 0))
        end
        return copysign(dh, dt)
    else
        dtf = muladd(b1, a2, -a1 * b2)
        tn = dtf / dp #    tan(Δh) = Δh +  (1/3)*Δh^3 +   (2/15)*Δh^5 + ...
                      # 2sin(Δh/2) = Δh - (1/24)*Δh^3 + (1/1920)*Δh^5 - ...
                      #            ≈ tan(Δh) - (3/8)*tan(Δh)^3 + (31/128)*tan(Δh)^5
        sn = tn * @evalpoly(tn^2, 1, oftype(tn, -3/8), oftype(tn, 31/128)) # 2sin(Δh/2)
        return @fastmath sqrt(c1 * c2) * sn
    end
end
function delta_h(a::C, b::C) where {Cb <: Union{LCHab, LCHuv, Oklch},
                                    C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    dh0 = hue(a) - hue(b)
    sh = muladd(dh0, oftype(dh0, 1 / 360), oftype(dh0, 0.5))
    d =  @fastmath sh - floor(sh) - oftype(sh, 0.5)
    2 * sqrt(chroma(a) * chroma(b)) * sinpi(d)
end
delta_h(a, b) = delta_h(promote(a, b)...)

@inline function delta_c(a::C, b::C) where {Cb <: Union{Lab{Float32}, Luv{Float32}, Oklab{Float32}},
                                    C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    n1, m1 = @fastmath minmax(comp2(a)^2, comp3(a)^2)
    n2, m2 = @fastmath minmax(comp2(b)^2, comp3(b)^2)
    ((m1 - m2) + (n1 - n2)) / @fastmath(max(chroma(a) + chroma(b), floatmin(Float32)))
end
delta_c(a, b) = chroma(a) - chroma(b)

"""
    weighted_color_mean(w1, c1, c2)

Returns the color `w1*c1 + (1-w1)*c2` that is the weighted mean of `c1` and
`c2`, where `c1` has a weight 0 ≤ `w1` ≤ 1.
"""
weighted_color_mean(w1::Real, c1::Colorant, c2::Colorant) = _weighted_color_mean(w1, c1, c2)
function weighted_color_mean(w1::Real, c1::C, c2::C) where {Cb <: Union{HSV, HSL, HSI, LCHab, LCHuv, Oklch},
                                                            C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    normalize_hue(_weighted_color_mean(w1, c1, c2))
end
function _weighted_color_mean(w1::Real, c1::Colorant{T1}, c2::Colorant{T2}) where {T1,T2}
    @fastmath min(w1, oneunit(w1) - w1) >= zero(w1) || throw(DomainError(w1, "`w1` must be in [0, 1]"))
    w2 = oneunit(w1) - w1
    mapc((x, y) -> convert(promote_type(T1, T2), muladd(w1, x, w2 * y)), c1, c2)
end
function _weighted_color_mean(w1::Integer, c1::C, c2::C) where C <: Colorant
    (w1 & 0b1) === w1 || throw(DomainError(w1, "`w1` must be in [0, 1]"))
    w1 == zero(w1) ? c2 : c1
end

"""
    weighted_color_mean(weights, colors)

Returns the weighted mean of the given collection `colors` with `weights`.
This is semantically equivalent to the calculation of `sum(weights .* colors)`.

# Examples
```jldoctest; setup = :(using Colors, FixedPointNumbers)
julia> rgbs = (RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1));

julia> weighted_color_mean([0.2, 0.2, 0.6], rgbs)
RGB{N0f8}(0.2, 0.2, 0.6)

julia> weighted_color_mean(0.5:-0.25:0.0, RGB{Float64}.(rgbs))
RGB{Float64}(0.5, 0.25, 0.0)
```

!!! compat "Colors v0.13"
    `wighted_color_mean` with collection or iterator inputs requires Colors
    v0.13 or later.

!!! note
    In a cylindrical color space such as HSV, a weighted mean of more than three
    colors is generally not meaningful.
"""
function weighted_color_mean(weights, colors)
    if length(weights) != length(colors)
        throw(DimensionMismatch("`weights` and `colors` must be the same length."))
    end
    w1, c1 = first(weights), first(colors)
    acc = mapc(_ -> zero(promote_type(typeof(w1), Float32)), c1)
    for (w, c) in zip(weights, colors)
        acc = mapc((a, v) -> a + w * v, acc, c)
    end
    convert(typeof(c1), acc)
end

"""
    range(start::T; stop::T, length=100) where T<:Colorant
    range(start::T, stop::T; length=100) where T<:Colorant

Generates N (=`length`) >2 colors in a linearly interpolated ramp from `start` to `stop`,
inclusive, returning an `Array` of colors.

!!! compat "Julia 1.1"
    `stop` as a positional argument requires at least Julia 1.1.
"""
function range(start::T; stop::T, length::Integer=100) where T<:Colorant
    return T[weighted_color_mean(w1, start, stop) for w1 in range(1.0,stop=0.0,length=length)]
end

if VERSION >= v"1.1"
    range(start::T, stop::T; kwargs...) where T<:Colorant = range(start; stop=stop, kwargs...)
end

if VERSION < v"1.0.0-"
import Base: linspace
Base.@deprecate linspace(start::Colorant, stop::Colorant, n::Integer=100) range(start, stop=stop, length=n)
end

# Double quadratic Bezier curve
function bezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    B(t,a,b,c)=a*(1.0-t)^2 + 2.0b*(1.0-t)*t + c*t^2
    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    else #t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end
end

# Inverse double quadratic Bezier curve
function inv_bezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    invB(t,a,b,c)=(a-b+sqrt(b^2-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    else #t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end
end
