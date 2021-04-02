# Helper data for CIE observer functions
include("cie_data.jl")

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

# TODO: move `pow7` from "src/differences.jl" to here

pow3_4(x) = (y = @fastmath(sqrt(x)); y*@fastmath(sqrt(y))) # x^(3/4)

# `pow5_12` is called from `srgb_compand`.
# `cbrt` generates a function call, so there is little benefit of `@fastmath`.
pow5_12(x) = pow3_4(x) / cbrt(x) # 5/12 == 1/2 + 1/4 - 1/3 == 3/4 - 1/3

# `pow12_5` is called from `invert_srgb_compand`.
# x^y ≈ exp(y*log(x)) ≈ exp2(y*log2(y)); the middle form is faster
@noinline pow12_5(x) = x^2 * exp(0.4 * log(x)) # 12/5 == 2.4 == 2 + 0.4


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
- `style`: a symbol to specify the hexadecimal notation. Spesifying the
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

!!! compat
    For backward compatibility, `hex(c::ColorAlpha)` currently returns an
    "AARRGGBB" style string. This is inconsistent with `hex(c, :AUTO)` returning
    an "RRGGBBAA" style string. The alpha position for `ColorAlpha` will soon be
    changed to the tail.
"""
hex(c::Colorant) = _hex(HexAuto, c) # there is no need to search the dictionary
hex(c::Colorant, style::Symbol) = _hex(get(_hex_styles, style, HexAuto), c)

function Base.hex(c::Colorant)
    Base.depwarn("Base.hex(c) has been moved to the package Colors.jl, i.e. Colors.hex(c).", :hex)
    hex(c)
end

# TODO: abolish the transitional measure (i.e. remove the following method)
function hex(c::ColorAlpha)
    Base.depwarn("""
        The alpha position for $(typeof(c)) (<:ColorAlpha) will soon be changed.
        You can get the alpha-first style string by `hex(c, :AARRGGBB)` or `hex(c |> ARGB32)`.
        """, :hex)
    #_hex(HexNotation{RGBA,:upper,8}, c) # breaking change in v1.0
    _hex( HexNotation{ARGB,:upper,8}, c) # backward compatible
end

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
normalize_hue(c::C) where C <: Union{LCHab, LCHuv} = C(c.l, c.c, normalize_hue(c.h))
normalize_hue(c::C) where {Cb <: Union{LCHab, LCHuv}, C <: Union{AlphaColor{Cb}, ColorAlpha{Cb}}} =
    C(c.l, c.c, normalize_hue(c.h), c.alpha)

"""
    weighted_color_mean(w1, c1, c2)

Returns the color `w1*c1 + (1-w1)*c2` that is the weighted mean of `c1` and
`c2`, where `c1` has a weight 0 ≤ `w1` ≤ 1.
"""
weighted_color_mean(w1::Real, c1::Colorant, c2::Colorant) = _weighted_color_mean(w1, c1, c2)
function weighted_color_mean(w1::Real, c1::C, c2::C) where {Cb <: Union{HSV, HSL, HSI, LCHab, LCHuv},
                                                            C <: Union{Cb, AlphaColor{Cb}, ColorAlpha{Cb}}}
    normalize_hue(_weighted_color_mean(w1, c1, c2))
end
function _weighted_color_mean(w1::Real, c1::Colorant{T1}, c2::Colorant{T2}) where {T1,T2}
    @fastmath min(w1, oneunit(w1) - w1) >= zero(w1) || throw(DomainError(w1, "`w1` must be in [0, 1]"))
    weight1 = convert(promote_type(T1, T2), w1) # TODO: Consider the need for this
    weight2 = oneunit(weight1) - weight1
    mapc((x, y) -> convert(promote_type(T1, T2), muladd(weight1, x, weight2 * y)), c1, c2)
end
function _weighted_color_mean(w1::Integer, c1::C, c2::C) where C <: Colorant
    (w1 & 0b1) === w1 || throw(DomainError(w1, "`w1` must be in [0, 1]"))
    w1 == zero(w1) ? c2 : c1
end

"""
    range(start::T; stop::T, length=100) where T<:Colorant
    range(start::T, stop::T; length=100) where T<:Colorant

Generates N (=`length`) >2 colors in a linearly interpolated ramp from `start` to`stop`,
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

#Double quadratic Bezier curve
function Bezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    B(t,a,b,c)=a*(1.0-t)^2 + 2.0b*(1.0-t)*t + c*t^2
    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    else #t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end
end

#Inverse double quadratic Bezier curve
function invBezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    invB(t,a,b,c)=(a-b+sqrt(b^2-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    else #t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end
end
