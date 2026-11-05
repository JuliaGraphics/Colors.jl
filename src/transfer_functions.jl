"""
    Colors.AbstractTransferFunction{N}

Abstract supertype for transfer functions that operate on `N` real-valued
components at a time.

The parameter `N` specifies the number of components processed by a single
application of the transfer function.
It is independent of any particular color space or color model.

For `N == 1`, the transfer function operates on a single `Real` value.
For `N > 1`, it operates on an `NTuple{N}` of `Real` values.

Custom subtypes should implement [`Colors.to_linear`](@ref) and
[`Colors.from_linear`](@ref).
"""
abstract type AbstractTransferFunction{N} end

Base.Broadcast.broadcastable(x::AbstractTransferFunction) = Ref(x)

const TransferFunction1 = AbstractTransferFunction{1}
const TransferFunction3 = AbstractTransferFunction{3}

"""
    Colors.TransferFunction{S} <: Colors.AbstractTransferFunction{1}

A singleton type that represents a built-in scalar transfer function identified
by the symbol `S`.
"""
struct TransferFunction{S} <: TransferFunction1 end

const SRGBTransferFunction = TransferFunction{:sRGB}()
const Gamma2_4 = TransferFunction{:Gamma2_4}()

"""
    Colors.to_linear([T,] v::Real, transfer::Colors.AbstractTransferFunction{1})
    Colors.to_linear([T,] vs::NTuple{N}, transfer::Colors.AbstractTransferFunction{N}) where {N}

Applies the transfer function to convert a value to its linear representation.
`T` is the result element type, defaulting to `typeof(v)` or `eltype(vs)`.

See also [`Colors.from_linear`](@ref) for the inverse operation.
"""
to_linear(v::Real, transfer::TransferFunction1) = to_linear(typeof(v), v, transfer)
function to_linear(vs::NTuple{N}, transfer::AbstractTransferFunction{N}) where {N}
    return to_linear(eltype(vs), vs, transfer)
end
function to_linear(T::Type, vs::Tuple{<:Real}, transfer::AbstractTransferFunction{1})
    return (to_linear(T, first(vs), transfer),)
end

"""
    Colors.from_linear([T,] v::Real, transfer::Colors.AbstractTransferFunction{1})
    Colors.from_linear([T,] vs::NTuple{N}, transfer::Colors.AbstractTransferFunction{N}) where {N}

Applies the (inverse) transfer function to convert a value from its linear
representation.

See [`Colors.to_linear`](@ref) for details.
"""
from_linear(v::Real, transfer::TransferFunction1) = from_linear(typeof(v), v, transfer)
function from_linear(v::NTuple{N}, transfer::AbstractTransferFunction{N}) where {N}
    return from_linear(eltype(v), v, transfer)
end
function from_linear(T::Type, vs::Tuple{<:Real}, transfer::AbstractTransferFunction{1})
    return (from_linear(T, first(vs), transfer),)
end

# RGB
"""
    to_linear_rgb([C,] rgb; builtin)
    to_linear_rgb([C,] rgb [, transfer::Colors.AbstractTransferFunction{N}])

Applies the transfer function to convert an RGB color to the linear RGB.

The `transfer` argument must be an instance of
[`Colors.AbstractTransferFunction`](@ref), not a Julia `Function`.
For RGB colors, `N` must be `1` or `3`.
The default transfer function is the sRGB transfer function.

`C` is the result type of the conversion, and defaults to the type of `rgb`.

See also [`from_linear_rgb`](@ref) for the inverse operation.

# Keyword Arguments

- `builtin`: A symbol that specifies a built-in transfer function. The choices
    are:
  - `:Gamma2_4`: The gamma 2.4 transfer function, commonly used as an
    approximation to BT.1886.
  - `:sRGB`: The sRGB transfer function (approximately gamma 2.2).

# Examples
```jldoctest; setup = :(using Colors)
julia> to_linear_rgb(RGB{Float32}, RGB(1.0, 0.5, 0.0))
RGB{Float32}(1.0, 0.21404114, 0.0)

julia> to_linear_rgb(RGB(1, 0.5f0, 0), builtin=:Gamma2_4)
RGB{Float32}(1.0, 0.18946457, 0.0)

julia> to_linear_rgb(RGB(1, 0.5f0, 0), Colors.TransferFunction{:Gamma2_4}())
RGB{Float32}(1.0, 0.18946457, 0.0)
```

!!! note
    This function does not perform any clamping or validation of the input
    components, even if the standard specifications require them.
    Accuracy cannot be guaranteed for input components that exceed the range
    of [0, 1].
    In other words, HDR colors are not supported.
    Also, the behavior when an output component cannot be represented by the
    output type is implementation-dependent.

!!! tip
    Specifying `builtin=:Gamma2_4` is functionally equivalent to specifying
    `Colors.TransferFunction{:Gamma2_4}()` for `transfer`.
    However, since the latter style determines the type at compile time, it may
    be faster than the former.

!!! compat "Colors v0.13.5"
    `to_linear_rgb` and `from_linear_rgb` are introduced in Colors v0.13.5.
"""
function to_linear_rgb(C::Type{<:AbstractRGB}, rgb::AbstractRGB;
                       builtin::Union{Symbol, Nothing} = nothing)
    Cc = ccolor(C, typeof(rgb))
    return _to_linear_rgb(Cc, rgb, _solve_rgb_transfer_function(builtin))
end
function to_linear_rgb(C::Type{<:AbstractRGB}, rgb::AbstractRGB,
                       transfer::Union{TransferFunction1, TransferFunction3})
    Cc = ccolor(C, typeof(rgb))
    return _to_linear_rgb(Cc, rgb, transfer)
end
function to_linear_rgb(rgb::AbstractRGB; builtin::Union{Symbol, Nothing} = nothing)
    return to_linear_rgb(typeof(rgb), rgb; builtin = builtin)
end
function to_linear_rgb(rgb::AbstractRGB,
                       transfer::Union{TransferFunction1, TransferFunction3})
    return _to_linear_rgb(typeof(rgb), rgb, transfer)
end

function _to_linear_rgb(::Type{C}, rgb::AbstractRGB,
                        transfer::TransferFunction1) where {T, C<:AbstractRGB{T}}
    r = to_linear(T, red(rgb), transfer)
    g = to_linear(T, green(rgb), transfer)
    b = to_linear(T, blue(rgb), transfer)
    return C(r, g, b)
end
function _to_linear_rgb(::Type{C}, rgb::AbstractRGB,
                        transfer::TransferFunction3) where {T, C<:AbstractRGB{T}}
    return C(to_linear(T, (red(rgb), green(rgb), blue(rgb)), transfer)...)
end

"""
    from_linear_rgb([C,] rgb; builtin)
    from_linear_rgb([C,] rgb [, transfer::AbstractTransferFunction{N}])

Applies the (inverse) transfer function to convert an RGB color from the linear
RGB.

The default transfer function is the sRGB transfer function.

`C` is the result type of the conversion, and defaults to the type of `rgb`.

See [`to_linear_rgb`](@ref) for details.
"""
function from_linear_rgb(C::Type{<:AbstractRGB}, rgb::AbstractRGB;
                         builtin::Union{Symbol, Nothing} = nothing)
    Cc = ccolor(C, typeof(rgb))
    return _from_linear_rgb(Cc, rgb, _solve_rgb_transfer_function(builtin))
end
function from_linear_rgb(C::Type{<:AbstractRGB}, rgb::AbstractRGB,
                         transfer::Union{TransferFunction1, TransferFunction3})
    Cc = ccolor(C, typeof(rgb))
    return _from_linear_rgb(Cc, rgb, transfer)
end
function from_linear_rgb(rgb::AbstractRGB; builtin::Union{Symbol, Nothing} = nothing)
    return from_linear_rgb(typeof(rgb), rgb; builtin = builtin)
end
function from_linear_rgb(rgb::AbstractRGB,
                         transfer::Union{TransferFunction1, TransferFunction3})
    return _from_linear_rgb(typeof(rgb), rgb, transfer)
end

function _from_linear_rgb(::Type{C}, rgb::AbstractRGB,
                          transfer::TransferFunction1) where {T, C<:AbstractRGB{T}}
    r = from_linear(T, red(rgb), transfer)
    g = from_linear(T, green(rgb), transfer)
    b = from_linear(T, blue(rgb), transfer)
    return C(r, g, b)
end
function _from_linear_rgb(::Type{C}, rgb::AbstractRGB,
                          transfer::TransferFunction3) where {T, C<:AbstractRGB{T}}
    return C(from_linear(T, (red(rgb), green(rgb), blue(rgb)), transfer)...)
end

function _solve_rgb_transfer_function(builtin::Union{Symbol, Nothing})
    (isnothing(builtin) || builtin === :sRGB) && return SRGBTransferFunction
    if builtin in (:Gamma2_4,)
        return TransferFunction{builtin}()
    end
    throw(ArgumentError("Unknown builtin transfer function: $builtin"))
end

# sRGB transfer function
# ----------------------
@inline function to_linear(::Type{Td}, v::Real, ::TransferFunction{:sRGB}) where {Td}
    F = promote_type(typeof(0.5f0v) === Float32 ? Float32 : Float64, Td)
    vf = F(v)
    # `pow12_5` is an optimized function to get `x^2.4`
    Td(vf > F(0.04045) ? pow12_5(muladd(F(1000/1055), vf, F(55/1055))) : F(100/1292) * vf)
end

# lookup table for `N0f8`
const invert_srgb_compand_n0f8 = [to_linear(Float32, v/255, SRGBTransferFunction) for v in 0:255]

@inline function to_linear(::Type{Td}, v::N0f8, ::TransferFunction{:sRGB}) where {Td}
    if Td <: Union{Float32, Float16, FixedPoint}
        return Td(@inbounds invert_srgb_compand_n0f8[reinterpret(v) + 1])
    end
    to_linear(Td, Td(v), SRGBTransferFunction)
end

@noinline function to_linear(::Type{Float32}, v::Float32, ::TransferFunction{:sRGB})
    ss = 2.378414230005442 # 2^(3/2.4)
    s = 1.7817974362806785 # 2^(2/2.4)
    e = 0x2
    if v < 0.38907406f0
        e += 0x3
        s *= ss # s = 2^(5/2.4)
    end
    if v < 0.13171014f0
        e += 0x3
        s *= ss # s = 2^(8/2.4)
    end
    t = reinterpret(Float32, UInt32(0x7f - e) << 0x17) # 2^(-e)
    x = muladd(1000 / 1055, Float64(v), 55 / 1055)
    m = x * s
    z = m + Float64(Int8(-1))

    # m^2.4
    m2_4 = @evalpoly(z, 0.9999999998100612,
        2.4000000066726828, 1.6800000422089263, 0.22399936087080838,
        -0.03360053050949402, 0.010768356626912876, -0.004687927635005098,
        0.002306177943094927, -0.000977187074267818, 0.00022417966696920558)
    yl = Float32(100 / 1292) * v
    y = Float32(m2_4) * t
    return v > 0.04045f0 ? y : yl
end

@inline function from_linear(::Type{T}, v::Real, ::TransferFunction{:sRGB}) where {T}
    F = promote_type(typeof(0.5f0v) === Float32 ? Float32 : Float64, T)
    vf = F(v)
    # `pow5_12` is an optimized function to get `v^(1/2.4)`
    vp = F(pow5_12(@fastmath max(vf, F(0.0031308))))
    T(vf > F(0.0031308) ? muladd(F(0.055), vp, vp - F(0.055)) : F(12.92) * vf)
end
function from_linear(::Type{T}, v::N0f8, ::TransferFunction{:sRGB}) where {T}
    F = promote_type(typeof(0.5f0v) === Float32 ? Float32 : Float64, T)
    from_linear(T, F(v), SRGBTransferFunction)
end

# Gamma 2.4 transfer function
# ---------------------------
function to_linear(::Type{T}, v::Real, ::TransferFunction{:Gamma2_4}) where {T}
    F = promote_type(typeof(0.5f0v) === Float32 ? Float32 : Float64, T)
    T(pow12_5(F(v)))
end

function from_linear(::Type{T}, v::Real, ::TransferFunction{:Gamma2_4}) where {T}
    F = promote_type(typeof(0.5f0v) === Float32 ? Float32 : Float64, T)
    T(pow5_12(F(v)))
end
