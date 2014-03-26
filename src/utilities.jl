# Helper data for CIE observer functions
include("cie_data.jl")


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


# set source color as a ColorValue
function set_source(gc::GraphicsContext, c::ColorValue)
    rgb = convert(RGB, c)
    set_source_rgb(gc, rgb.r, rgb.g, rgb.b)
end

# weighted_color_mean(w1, c1, c2) gives a mean color "w1*c1 + (1-w1)*c2".
for (T,a,b,c) in ((:RGB,:r,:g,:b), (:HSV,:h,:s,:v), (:HSL,:h,:s,:l),
                  (:XYZ,:x,:y,:z), (:LAB,:l,:a,:b), (:LCHab,:l,:c,:h),
                  (:LUV,:l,:u,:v), (:LCHuv,:l,:c,:h), (:LMS,:l,:m,:s))
    @eval weighted_color_mean(w1::Real, c1::$T, c2::$T) =
      let w2 = w1 >= 0 && w1 <= 1 ? 1 - w1 : throw(DomainError())
          $T(c1.($(Expr(:quote, a))) * w1 + c2.($(Expr(:quote, a))) * w2,
             c1.($(Expr(:quote, b))) * w1 + c2.($(Expr(:quote, b))) * w2,
             c1.($(Expr(:quote, c))) * w1 + c2.($(Expr(:quote, c))) * w2)
      end
end
weighted_color_mean(w1::Real, c1::RGB24, c2::RGB24) =
    convert(RGB24, weighted_color_mean(w1, convert(RGB, c1), convert(RGB, c2)))

# return a linear ramp of n colors from c1 to c2, inclusive
function linspace{T<:ColorValue}(c1::T, c2::T, n=100)
    a = Array(T, int(n))
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

#Double quadratic Beziere curve
function Beziere(t,p0,p2,q0,q1,q2)
    function B(t,a,b,c)
    a*(1.0-t)^2.0+2.0*b*(1.0-t)*t+c*t^2.0
    end

    if t <= 0.5
        return B(2.0t, p0, q0, q1)
    elseif t > 0.5
        return B(2.0(t-0.5), q1, q2, p2)
    end

    NaN
end

#Inverse double quadratic Beziere curve
function invBeziere(t,p0,p2,q0,q1,q2)
    function invB(t,a,b,c)
        (a-b+sqrt(b^2.0-a*c+(a-2.0b+c)*t))/(a-2.0b+c)
    end

    if t < q1
        return 0.5*invB(t,p0,q0,q1)
    elseif t >= q1
        return 0.5*invB(t,q1,q2,p2)+0.5
    end

    NaN
end
