# Helper data for CIE observer functions
include("cie_data.jl")


# Linear interpolation in [a, b] where x is in [0,1],
# or coerced to be if not.
function lerp(x, a, b)
    a + (b - a) * max(min(x, one(x)), zero(x))
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
                  (:XYZ,:x,:y,:z), (:Lab,:l,:a,:b), (:LCHab,:l,:c,:h),
                  (:Luv,:l,:u,:v), (:LCHuv,:l,:c,:h), (:LMS,:l,:m,:s))
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
