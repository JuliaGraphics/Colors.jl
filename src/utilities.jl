# Helper data for CIE observer functions
include("cie_data.jl")


# Linear interpolation in [a, b] where x is in [0,1],
# or coerced to be if not.
function lerp(x, a, b)
    a + (b - a) * max(min(x, one(x)), zero(x))
end


"""
    hex(c)

Print a color as a RGB hex triple, or a transparent paint as an ARGB
hex quadruplet.
"""
function hex(c::RGB)
    @sprintf("%02X%02X%02X",
             round(Int, lerp(c.r, 0.0, 255.0)),
             round(Int, lerp(c.g, 0.0, 255.0)),
             round(Int, lerp(c.b, 0.0, 255.0)))
end
function hex(c::ARGB)
    @sprintf("%02X%02X%02X%02X",
             round(Int, lerp(alpha(c), 0.0, 255.0)),
             round(Int, lerp(red(c), 0.0, 255.0)),
             round(Int, lerp(green(c), 0.0, 255.0)),
             round(Int, lerp(blue(c), 0.0, 255.0)))
end

hex(c::Color) = hex(convert(RGB, c))
hex(c::Colorant) = hex(convert(ARGB, c))

"""
    weighted_color_mean(w1, c1, c2)

Returns the color `w1*c1 + (1-w1)*c2` that is the weighted mean of `c1` and 
`c2`, where `c1` has a weight 0 ≤ `w1` ≤ 1.
"""
function weighted_color_mean(w1::Real, c1::Colorant, c2::Colorant)
    w1 = convert(eltype(c1),w1)
    w2 = w1 >= 0 && w1 <= 1 ? oftype(w1,1-w1) : throw(DomainError())
    _weighted_color_mean(base_colorant_type(c1), base_colorant_type(c2), w1, w2, c1, c2)
end

function _weighted_color_mean{C<:ColorTypes.AbstractGray}(::Type{C}, ::Type{C}, w1, w2, c1, c2)
    C(w1*comp1(c1)+w2*comp1(c2))
end

function _weighted_color_mean{C<:ColorTypes.TransparentGray}(::Type{C}, ::Type{C}, w1, w2, c1, c2)
    C(w1*comp1(c1)+w2*comp1(c2), w1*alpha(c1)+w2*alpha(c2))
end

function _weighted_color_mean{C<:ColorTypes.Color3}(::Type{C}, ::Type{C}, w1, w2, c1, c2)
    C(w1*comp1(c1)+w2*comp1(c2), w1*comp2(c1)+w2*comp2(c2), w1*comp3(c1)+w2*comp3(c2))
end

function _weighted_color_mean{C<:ColorTypes.Transparent3}(::Type{C}, ::Type{C}, w1, w2, c1, c2)
    C(w1*comp1(c1)+w2*comp1(c2), w1*comp2(c1)+w2*comp2(c2), w1*comp3(c1)+w2*comp3(c2), w1*alpha(c1)+w2*alpha(c2))
end

function _weighted_color_mean{C<:ColorTypes.TransparentRGB}(::Type{C}, ::Type{C}, w1, w2, c1, c2)
    C(w1*comp1(c1)+w2*comp1(c2), w1*comp2(c1)+w2*comp2(c2), w1*comp3(c1)+w2*comp3(c2), w1*alpha(c1)+w2*alpha(c2))
end

function _weighted_color_mean(::Type, ::Type, w1, w2, c1, c2)
    throw(ArgumentError("the two colors must be from the same colorspace, but got $c1 and $c2"))
end

"""
    linspace(c1::Color, c2::Color, n=100)

Generates `n` colors in a linearly interpolated ramp from `c1` to
`c2`, inclusive, returning an `Array` of colors.
"""
function linspace{T<:Colorant}(c1::T, c2::T, n=100)
    a = Array(T, convert(Int, n))
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

#Double quadratic Bezier curve
function Bezier{T<:Real}(t::T, p0::T, p2::T, q0::T, q1::T, q2::T)
    B(t,a,b,c)=a*(1.0-t)^2.0+2.0b*(1.0-t)*t+c*t^2.0
    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    else #t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end
end

#Inverse double quadratic Bezier curve
function invBezier{T<:Real}(t::T, p0::T, p2::T, q0::T, q1::T, q2::T)
    invB(t,a,b,c)=(a-b+sqrt(b^2.0-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    else #t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end
end
