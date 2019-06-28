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
    weight1 = convert(promote_type(eltype(c1), eltype(c2)),w1)
    weight2 = weight1 >= 0 && weight1 <= 1 ? oftype(weight1,1-weight1) : throw(DomainError())
    mapc((x,y)->weight1*x+weight2*y, c1, c2)
end
function weighted_color_mean(w1::Real, c1::Gray{Bool}, c2::Gray{Bool})
    # weighting of two Gray{Bool} would return different color type and therefore omitted
    throw(DomainError())
end

"""
    range(start::Color; stop::Color, length=100)

Generates `n`>2 colors in a linearly interpolated ramp from `start` to`stop`,
inclusive, returning an `Array` of colors.
"""
function range(start::T; stop::T, length::Integer=100) where T<:Colorant
    return T[weighted_color_mean(w1, start, stop) for w1 in range(1.0,stop=0.0,length=length)]
end

"""
    wavelength_to_rgb(wavelength;gamma=0.8)

An approximate conversion of optical wavelength (nm) to RGB.
Based on https://gist.github.com/friendly/67a7df339aa999e2bcfcfec88311abfc
Which is a conversion of code by Dan Bruton http://www.physics.sfasu.edu/astro/color/spectra.html
And discussed: https://stackoverflow.com/questions/1472514/convert-light-frequency-to-rgb
"""

function wavelength_to_rgb(wavelength;gamma=0.8)
    if (wavelength >= 380) && (wavelength <= 440)
        attenuation = 0.3 + 0.7 * (wavelength - 380) / (440 - 380)
        R = ((-(wavelength - 440) / (440 - 380)) * attenuation) ^ gamma
        G = 0.0
        B = (1.0 * attenuation) ^ gamma
    elseif (wavelength >= 440) && (wavelength <= 490)
        R = 0.0
        G = ((wavelength - 440) / (490 - 440)) ^ gamma
        B = 1.0
    elseif (wavelength >= 490) && (wavelength <= 510)
        R = 0.0
        G = 1.0
        B = (-(wavelength - 510) / (510 - 490)) ^ gamma
    elseif (wavelength >= 510) && (wavelength <= 580)
        R = ((wavelength - 510) / (580 - 510)) ^ gamma
        G = 1.0
        B = 0.0
    elseif (wavelength >= 580) && (wavelength <= 645)
        R = 1.0
        G = (-(wavelength - 645) / (645 - 580)) ^ gamma
        B = 0.0
    elseif (wavelength >= 645) && (wavelength <= 750)
        attenuation = 0.3 + 0.7 * (750 - wavelength) / (750 - 645)
        R = (1.0 * attenuation) ^ gamma
        G = 0.0
        B = 0.0
    else
        R = 0.0
        G = 0.0
        B = 0.0
    end
    return RGB(R,G,B)
end

if VERSION < v"1.0.0-"
import Base: linspace
Base.@deprecate linspace(start::Colorant, stop::Colorant, n::Integer=100) range(start, stop=stop, length=n)
end

#Double quadratic Bezier curve
function Bezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    B(t,a,b,c)=a*(1.0-t)^2.0+2.0b*(1.0-t)*t+c*t^2.0
    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    else #t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end
end

#Inverse double quadratic Bezier curve
function invBezier(t::T, p0::T, p2::T, q0::T, q1::T, q2::T) where T<:Real
    invB(t,a,b,c)=(a-b+sqrt(b^2.0-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    else #t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end
end
