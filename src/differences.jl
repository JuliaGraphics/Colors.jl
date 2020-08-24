
# Define an abstract type to represent color difference metrics
abstract type DifferenceMetric end

abstract type EuclideanDifferenceMetric{T<:Color3} <: DifferenceMetric end

# TODO?: make the DifferenMetrics parametric, to preserve type-stability

struct DE_2000 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
end
"""
    DE_2000()
    DE_2000(kl, kc, kh)

Construct a metric of the CIE Delta E 2000 recommendation, with weighting
parameters `kl`, `kc` and `kh` as provided for in the recommendation. When not
provided, these parameters default to `1`.
"""
DE_2000() = DE_2000(1,1,1)


struct DE_94 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
end
"""
    DE_94()
    DE_94(kl, kc, kh)

Construct a metric of CIE Delta E 94 recommendation (1994), with weighting
parameters `kl`, `kc` and `kh` as provided for in the recommendation. When not
provided, these parameters default to `1`.
The `DE_94` is more perceptually uniform than the [`DE_AB`](@ref), but has some
non-uniformities resolved by the [`DE_2000`](@ref).
"""
DE_94() = DE_94(1,1,1)


struct DE_JPC79 <: DifferenceMetric

end
"""
    DE_JPC79()

Construct a metric using McDonald's "JP Coates Thread Company" color difference
formula.
"""
DE_JPC79()


struct DE_CMC <: DifferenceMetric
    kl::Float64
    kc::Float64
end
"""
    DE_CMC()
    DE_CMC(kl, kc)

Construct a metric using the CMC equation (CMC l:c), with weighting parameters
`kl` and `kc`. When not provided, these parameters default to `1`.
!!! note
    The `DE_CMC` is a quasimetric, i.e. violates symmetry. Therefore,
    `colordiff(a, b, metric=DE_CMC())` may not equal to
    `colordiff(b, a, metric=DE_CMC())`.
"""
DE_CMC() = DE_CMC(1,1)


struct DE_BFD <: DifferenceMetric
    wp::XYZ{Float64}
    kl::Float64
    kc::Float64
end
"""
    DE_BFD()
    DE_BFD([wp,] kl, kc)

Construct a metric using the BFD equation, with weighting parameters `kl` and
`kc`. Additionally, a whitepoint `wp` can be specified, because the BFD equation
must convert between `XYZ` and `Lab` during the computation. When not provided,
`kl` and `kc` default to `1`, and `wp` defaults to CIE D65 (`Colors.WP_D65`).
"""
DE_BFD() = DE_BFD(WP_DEFAULT,1,1)
DE_BFD(kl, kc) = DE_BFD(WP_DEFAULT,kl, kc)


struct DE_AB <: EuclideanDifferenceMetric{Lab}

end
"""
    DE_AB()

Construct a metric of the original CIE Delta E equation (ΔE*ab), or Euclidean
color difference equation in the `Lab` (CIELAB) colorspace.
"""
DE_AB()

struct DE_DIN99 <: EuclideanDifferenceMetric{DIN99}

end
"""
    DE_DIN99()

Construct a metric using Euclidean color difference equation applied in the
`DIN99` colorspace.
"""
DE_DIN99()

struct DE_DIN99d <: EuclideanDifferenceMetric{DIN99d}

end
"""
    DE_DIN99d()

Construct a metric using Euclidean color difference equation applied in the
`DIN99d` colorspace.
"""
DE_DIN99d()

struct DE_DIN99o <: EuclideanDifferenceMetric{DIN99o}

end
"""
    DE_DIN99o()

Construct a metric using Euclidean color difference equation applied in the
`DIN99o` colorspace.
"""
DE_DIN99o()


# Compute the mean of two hue angles
function mean_hue(h1, h2)
    if abs(h2 - h1) > 180
        if h1 + h2 < 360
            mh = (h1 + h2 + 360) / 2
        else
            mh = (h1 + h2 - 360) / 2
        end
    else
        mh = (h1 + h2) / 2
    end

    mh
end

# Color difference metrics
# ------------------------

# Evaluate the CIEDE2000 color difference formula, implemented according to:
#   Klaus Witt, CIE Color Difference Metrics, Colorimetry: Understanding the CIE
#   System. 2007
#
# Args:
#   a, b: Any two colors.
#
# Returns:
#   The CIEDE2000 color difference metric evaluated between a and b.
#

pow7(x) = (y = x*x*x; y*y*x)
pow7(x::Integer) = pow7(Float64(x))
const twentyfive7 = pow7(25)

# Delta E 2000
function _colordiff(ai::Color, bi::Color, m::DE_2000)
    # Ensure that the input values are in L*a*b* space
    a_Lab = convert(Lab, ai)
    b_Lab = convert(Lab, bi)

    # Calculate some necessary factors from the L*a*b* values
    mc = (chroma(a_Lab) + chroma(b_Lab))/2
    g = (1 - sqrt(pow7(mc) / (pow7(mc) + twentyfive7))) / 2

    # Convert to L*C*h, where the remainder of the calculations are performed
    a = convert(LCHab, Lab(a_Lab.l, a_Lab.a * (1 + g), a_Lab.b))
    b = convert(LCHab, Lab(b_Lab.l, b_Lab.a * (1 + g), b_Lab.b))

    # Calculate the delta values for each channel
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = zero(dh)
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    # Calculate H*
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    # Calculate mean L* and C* values
    ml, mc = (a.l + b.l) / 2, (a.c + b.c) / 2

    # Calculate mean hue value
    if a.c * b.c == 0
        mh = a.h + b.h
    else
        mh = mean_hue(a.h, b.h)
    end

    # lightness weight
    mls = (ml - 50)^2
    sl = 1.0 + 0.015 * mls / sqrt(20 + mls)

    # chroma weight
    sc = 1 + 0.045mc

    # hue weight
    t = 1 - 0.17 * cosd(mh - 30) +
            0.24 * cosd(2mh) +
            0.32 * cosd(3mh + 6) -
            0.20 * cosd(4mh - 63)
    sh = 1 + 0.015 * mc * t

    # rotation term
    dtheta = 30 * exp(-((mh - 275)/25)^2)
    cr = 2 * sqrt(pow7(mc) / (pow7(mc) + twentyfive7))
    tr = -sind(2*dtheta) * cr

    # Final calculation
    sqrt((dl/(m.kl*sl))^2 + (dc/(m.kc*sc))^2 + (dh/(m.kh*sh))^2 +
         tr * (dc/(m.kc*sc)) * (dh/(m.kh*sh)))
end

# Delta E94
function _colordiff(ai::Color, bi::Color, m::DE_94)

    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate the delta values for each channel
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = zero(dh)
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    # Calculate H*
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    # Calculate geometric mean of chroma
    mc = sqrt(a.c*b.c)

    # Lightness, hue, chroma correction terms
    sl = 1
    sc = 1+0.045*mc
    sh = 1+0.015*mc

    sqrt((dl/(m.kl*sl))^2 + (dc/(m.kc*sc))^2 + (dh/(m.kh*sh))^2)

end

# Metric form of jpc79 color difference equation (mostly obsolete)
function _colordiff(ai::Color, bi::Color, m::DE_JPC79)

    # Convert directly into LCh
    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = zero(dh)
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    # Calculate H* from C*'s and h
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    #Calculate mean lightness
    ml = (a.l + b.l)/2
    mc = (a.c + b.c)/2
    # Calculate mean hue value
    if a.c * b.c == 0
        mh = a.h + b.h
    else
        mh = mean_hue(a.h, b.h)
    end

    # L* adjustment term
    sl = 0.08195*ml/(1+0.01765*ml)

    # C* adjustment term
    sc = 0.638+(0.0638*mc/(1+0.0131*mc))

    # H* adjustment term
    if (mc < 0.38)
        sh = sc
    elseif (mh >= 164 && mh <= 345)
        sh = sc*(0.56+abs(0.2*cosd(mh+168)))
    else
        sh = sc*(0.38+abs(0.4*cosd(mh+35)))
    end

    # Calculate the final difference
    sqrt((dl/sl)^2 + (dc/sc)^2 + (dh/sh)^2)

end


# Metric form of the cmc color difference
function _colordiff(ai::Color, bi::Color, m::DE_CMC)

    # Convert directly into LCh
    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = zero(dh)
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    # Calculate H* from C*'s and h
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    # Find the mean value of the inputs to use as the "standard"
    ml, mc = (a.l + b.l)/2, (a.c + b.c)/2 # TODO: use `a.l` and `a.c` instead

    # Calculate mean hue value
    if a.c * b.c == 0
        mh = a.h + b.h
    else
        mh = mean_hue(a.h, b.h)
    end

    # L* adjustment term
    if (a.l <= 16)
        sl = 0.511
    else
        sl = 0.040975*ml/(1+0.01765*ml)
    end

    # C* adjustment term
    sc = 0.0638*mc/(1+0.0131*mc)+0.638

    f = sqrt((mc^4)/(mc^4 + 1900))

    if (mh >= 164 && mh < 345)
        t = 0.56 + abs(0.2*cosd(mh+168))
    else
        t = 0.36 + abs(0.4*cosd(mh+35))
    end

    # H* adjustment term
    sh = sc*(t*f+1-f)

    # Calculate the final difference
    sqrt((dl/(m.kl*sl))^2 + (dc/(m.kc*sc))^2 + (dh/sh)^2)

end

# The BFD color difference equation
function _colordiff(ai::Color, bi::Color, m::DE_BFD)
    # Currently, support for the `wp` argument of `convert` is limited.
    function to_xyz(c::Color, wp)
        c isa XYZ && return ai
        (c isa xyY || c isa LMS) && return convert(XYZ, c)
        (c isa Lab || c isa Luv) && return convert(XYZ, c, wp)
        c isa LCHuv && return convert(XYZ, convert(Luv, c), wp)
        convert(XYZ, convert(Lab, c), wp)
    end

    # We have to start back in XYZ because BFD uses a different L equation
    a_XYZ = to_xyz(ai, m.wp)
    b_XYZ = to_xyz(bi, m.wp)

    la = 54.6*log10(a_XYZ.y+1.5)-9.6
    lb = 54.6*log10(b_XYZ.y+1.5)-9.6

    # Convert into LCh with the proper white point
    a_Lab = convert(Lab, a_XYZ, m.wp)
    b_Lab = convert(Lab, b_XYZ, m.wp)

    # Substitute in the different L values into the L*C*h values
    a = LCHab(la, chroma(a_Lab), hue(a_Lab))
    b = LCHab(lb, chroma(b_Lab), hue(b_Lab))

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = zero(dh)
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end

    # Calculate H* from C*'s and h
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    # Find the mean value of the inputs to use as the "standard"
    ml, mc = (a.l + b.l)/2, (a.c + b.c)/2

    # Calculate mean hue value
    if a.c * b.c == 0
        mh = a.h + b.h
    else
        mh = mean_hue(a.h, b.h)
    end

    # Correction terms for a variety of nonlinearities in CIELAB.
    g = sqrt(mc^4/(mc^4 + 14000))

    t = 0.627 + 0.055*cosd(mh - 245) - 0.04*cosd(2*mh - 136) + 0.07*cosd(3*mh - 32) + 0.049*cosd(4*mh + 114) - 0.015*cosd(5*mh + 103)

    rc = sqrt(mc^6/(mc^6 + 7e7))

    rh = -0.26cosd(mh-308) - 0.379cosd(2*mh-160) - 0.636*cosd(3*mh - 254) + 0.226cosd(4*mh + 140) - 0.194*cosd(5*mh + 280)

    dcc = 0.035*mc/(1+0.00365*mc) + 0.521
    dhh = dcc*(g*t+1-g)
    rt = rc*rh

    # Final calculation
    sqrt((dl/m.kl)^2 + (dc/(m.kc*dcc))^2 + (dh/dhh)^2 + rt*((dc*dh)/(dcc*dhh)))
end

function _colordiff(ai::Color, bi::Color,
                    m::EuclideanDifferenceMetric{T}) where {T <: Color3}
    a, b = convert(T, ai), convert(T, bi)

    d1, d2, d3 = comp1(a) - comp1(b), comp2(a) - comp2(b), comp3(a) - comp3(b)

    sqrt(d1^2 + d2^2 + d3^2)
end

# Default to Delta E 2000
"""
    colordiff(a, b; metric=DE_2000())

Compute an approximate measure of the perceptual difference between colors `a`
and `b`. Optionally, a `metric` may be supplied, chosen among [`DE_2000`](@ref)
(the default), [`DE_94`](@ref), [`DE_JPC79`](@ref), [`DE_CMC`](@ref),
[`DE_BFD`](@ref), [`DE_AB`](@ref), [`DE_DIN99`](@ref), [`DE_DIN99d`](@ref) and
[`DE_DIN99o`](@ref).

The return value is a non-negative number in a type depending on the colors and
metric.

!!! note
    The supported metrics measure the difference within `Lab` or its variant
    colorspaces. When the input colors are not in the colorspace internally used
    by the metric, the colors (e.g. in `RGB`) are converted with the default
    whitepoint CIE D65 (`Colors.WP_D65`). If you want to use another whitepoint,
    convert the colors into the colorspace used by metric (e.g. `Lab` for
    [`DE_2000`](@ref)) in advance.
"""
colordiff(ai::Union{Number, Color},
          bi::Union{Number, Color};
          metric::DifferenceMetric=DE_2000()) = _colordiff(ai, bi, metric)
@deprecate colordiff(ai::Color, bi::Color, metric::DifferenceMetric) colordiff(ai, bi; metric=metric)

function colordiff(ai::Colorant, bi::Colorant; metric::DifferenceMetric=DE_2000())
    alpha(ai) == 1 && alpha(bi) == 1 && return _colordiff(color(ai), color(bi), metric)
    throw(ArgumentError("""
        cannot evaluate the difference in transparent colors.
          Their appearance depends on the backdrop."""))
end

_colordiff(ai::AbstractGray, bi::Number, metric::DifferenceMetric) = _colordiff(ai, Gray(bi), metric)
_colordiff(ai::Number, bi::AbstractGray, metric::DifferenceMetric) = _colordiff(Gray(ai), bi, metric)
_colordiff(ai::Number, bi::Number, metric::DifferenceMetric) = _colordiff(Gray(ai), Gray(bi), metric)
