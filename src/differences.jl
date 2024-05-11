
# Define an abstract type to represent color difference metrics
abstract type DifferenceMetric end

abstract type EuclideanDifferenceMetric{T<:Color3} <: DifferenceMetric end

# TODO?: make the DifferenMetrics parametric, to preserve type-stability

struct DE_2000 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
    DE_2000(kl=1, kc=1, kh=1) = new(kl, kc, kh)
end
"""
    DE_2000(kl=1, kc=1, kh=1)

Construct a metric of the CIE Delta E 2000 recommendation, with weighting
parameters `kl`, `kc` and `kh` as provided for in the recommendation. When not
provided, these parameters default to `1`.
"""
DE_2000()


struct DE_94 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
    k1::Float64
    k2::Float64
    DE_94(kl=1, kc=1, kh=1, k1=0.045, k2=0.015) = new(kl, kc, kh, k1, k2)
end
"""
    DE_94(kl=1, kc=1, kh=1, k1=0.045, k2=0.015)

Construct a metric of CIE Delta E 94 recommendation (1994), with weighting
parameters `kl`, `kc`, `kh`, `k1`, and `k2` as provided for in the
recommendation. The `kl`, `k1`, and `k2` depend on the application:

|    |Graphic Arts|Textiles|
|:--:|:-----------|:-------|
|`kl`|`1`         |`2`     |
|`k1`|`0.045`     |`0.048` |
|`k2`|`0.015`     |`0.014` |

and the default values are for graphic arts. The `kc` and `kh` default to `1`.

The `DE_94` is more perceptually uniform than the [`DE_AB`](@ref), but has some
non-uniformities resolved by the [`DE_2000`](@ref).

!!! note
    The `DE_94` is a quasimetric, i.e. violates symmetry. Therefore,
    `colordiff(a, b, metric=DE_94())` may not equal to
    `colordiff(b, a, metric=DE_94())`.
    The first argument of `colordiff` is taken as the reference (standard)
    color.
"""
DE_94()


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
    DE_CMC(kl=1, kc=1) = new(kl, kc)
end
"""
    DE_CMC(kl=1, kc=1)

Construct a metric using the CMC equation (CMC l:c), with weighting parameters
`kl` and `kc`. When not provided, these parameters default to `1`.

!!! note
    The `DE_CMC` is a quasimetric, i.e. violates symmetry. Therefore,
    `colordiff(a, b, metric=DE_CMC())` may not equal to
    `colordiff(b, a, metric=DE_CMC())`.
    The first argument of `colordiff` is taken as the reference (standard)
    color.
"""
DE_CMC()


struct DE_BFD <: DifferenceMetric
    wp::XYZ{Float64}
    kl::Float64
    kc::Float64
    DE_BFD(wp::XYZ, kl=1, kc=1) = new(wp, kl, kc)
end
"""
    DE_BFD([wp,] kl=1, kc=1)

Construct a metric using the BFD equation, with weighting parameters `kl` and
`kc`. Additionally, a whitepoint `wp` can be specified, because the BFD equation
must convert between `XYZ` and `Lab` during the computation. When not provided,
`kl` and `kc` default to `1`, and `wp` defaults to CIE D65 (`Colors.WP_D65`).
"""
DE_BFD(kl=1, kc=1) = DE_BFD(WP_DEFAULT, kl, kc)

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


# Delta E 2000
# Ensure that the input values are in L*a*b* space
function _colordiff(a::Color, b::Color, m::DE_2000)
    _colordiff(promote(convert(Lab, a), convert(Lab, b))..., m)
end
function _colordiff(a_lab::Lab{T}, b_lab::Lab{T}, m::DE_2000) where T
    F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)
    _sqrt(x) = @fastmath(sqrt(x))

    # Calculate some necessary factors from the L*a*b* values
    mco7 = pow7((chroma(a_lab) + chroma(b_lab)) * F(0.5 / 25))
    g = F(0.5) - F(0.5) * F(_sqrt(mco7 / (mco7 + 1)))

    a = Lab{F}(a_lab.l, muladd(a_lab.a, g, a_lab.a), a_lab.b)
    b = Lab{F}(b_lab.l, muladd(b_lab.a, g, b_lab.a), b_lab.b)

    # Calculate the delta values for each channel
    dl, dc, dh = b.l - a.l, delta_c(b, a), delta_h(b, a)

    # Calculate mean L*, C* and hue values
    ml, mc, mh = (a.l + b.l) * F(0.5), (chroma(a) + chroma(b)) * F(0.5), mean_hue(a, b)

    # lightness weight
    mls = (ml - 50)^2
    sl = muladd(F(0.015), mls / _sqrt(20 + mls), 1)

    # chroma weight
    sc = muladd(F(0.045), mc, 1)

    # hue weight
    sh = muladd(F(0.015), mc * _de2000_t(mh), 1)

    # rotation term
    mc7 = pow7(mc * F(1 / 25))
    rt = -2 * F(_sqrt(mc7 / (mc7 + 1))) * _de2000_rot(mh)

    # Final calculation
    kl, kc, kh = F(m.kl), F(m.kc), F(m.kh)
    dsl, dsc, dsh = dl / (kl * sl), dc / (kc * sc), dh / (kh * sh)
    F(_sqrt(dsl^2 + dsc^2 + dsh^2 + rt * dsc * dsh))
end

@inline function _de2000_t(mh::F) where F
    h2 = mh < F(180) ? mh : mh - F(180)
    h3 = mh < F(120) ? mh : mh - F(240)
    h4 = h2 < F( 90) ? h2 : h2 - F(90)
    c = F(-17) * cos(muladd(π/F(180), mh, deg2rad(F(-30)))) +
        F( 24) * cos(  h2 * π/F( 90)) +
        F( 32) * cos(muladd(π/F( 60), h3, deg2rad(F(6)))) +
        F(-20) * cos(muladd(π/F( 45), h4, deg2rad(F(-63))))
    muladd(1/F(100), c, 1)
end
function _de2000_t(mh::Float32)
    if mh < 64.0f0
        return @evalpoly((mh - 32.0f0) * (1.0f0/64),
            0.78425723f0, -0.71428823f0, 1.0606939f0, -0.3320813f0, -1.6548954f0, 1.4866706f0,
            1.0461172f0, -0.9630005f0, -0.35182664f0, 0.2700254f0, 0.06314228f0)
    elseif mh < 128.0f0
        return @evalpoly((mh - 96.0f0) * (1.0f0/64),
            0.6708259f0, 0.7022065f0, 1.4496115f0, -0.091134265f0, -2.14522f0, -0.81226975f0,
            1.5013183f0, 0.60370386f0, -0.5584273f0, -0.1776522f0, 0.11164045f0)
    elseif mh < 192.0f0
        return @evalpoly((mh - 160.0f0) * (1.0f0/64),
            1.2647604f0, -0.9152141f0, -1.0652254f0, 3.0960295f0, 1.8619311f0, -2.6234343f0,
            -1.4259213f0, 1.0765249f0, 0.55065846f0, -0.2422152f0, -0.11089423f0)
    elseif mh < 236.0f0
        return @evalpoly((mh - 214.0f0) * (1.0f0/64),
            1.2999026f0, 1.364039f0, -0.30168927f0, -4.335773f0, -0.34714356f0, 3.8063064f0,
            0.43577778f0, -1.6205053f0, -0.19063109f0, 0.3946184f0, 0.0470799f0)
    elseif mh < 268.0f0
        return @evalpoly((mh - 252.0f0) * (1.0f0/64),
            1.3113983f0, -1.7916181f0, -2.341132f0, 3.733874f0, 3.4045563f0, -2.9195895f0,
            -1.9971917f0, 1.2059773f0, 0.6468915f0, -0.2969976f0, -0.1274673f0)
    elseif mh < 320.0f0
        return @evalpoly((mh - 294.0f0) * (1.0f0/64),
            0.37643716f0, 0.47334087f0, 3.8213744f0, -1.4942352f0, -4.5954514f0, 1.4621881f0,
            2.4966235f0, -0.71292526f0, -0.78470963f0, 0.18798664f0, 0.1509905f0)
    else
        return @evalpoly((mh - 340.0f0) * (1.0f0/64),
            1.4223951f0, 0.5289211f0, -3.0410407f0, -0.09073099f0, 3.824369f0, -0.80474544f0,
            -2.16635f0, 0.59577477f0, 0.70546037f0, -0.18656555f0, -0.1424503f0)
    end
end

@inline _de2000_rot(mh::F) where {F} = sin(π/F(3) * exp(-((mh - 275) * F(1/25))^2))

const DE2000_SINEXP_F32 = [Float32(π/3 * exp(-i)) for i = 0.0:0.25:87.25]
@inline function _de2000_rot(mh::Float32)
    dh2 = ((mh - 275.0f0) * (1.0f0 / 25))^2
    di = reinterpret(UInt32, dh2 + Float32(0x3p20))
    i = di % UInt16 # round(UInt16, dh2 * 4.0)
    i >= UInt16(350) && return 0.0f0 # avoid subnormal numbers
    t = (reinterpret(Float32, di) - Float32(0x3p20)) - dh2 # |t| <= 0.125
    sinexp = @inbounds DE2000_SINEXP_F32[i + 1] # π/3 * exp(-dh2) = (π/3 * exp(-i/4)) * exp(t)
    em1 = @evalpoly(t, 1.0f0, 0.49999988f0, 0.16666684f0, 0.041693877f0, 0.008323605f0) * t
    ex = muladd(sinexp, em1, sinexp)
    ex < eps(0.5f0) && return ex
    sn = @evalpoly(ex^2, -0.16666667f0, 0.008333333f0, -0.00019841234f0, 2.7550889f-6, -2.4529042f-8)
    return muladd(sn * ex, ex^2, ex)
end

# Delta E94
function _colordiff(a::Color, b::Color, m::DE_94)
    _colordiff(promote(convert(Lab, a), convert(Lab, b))..., m)
end
function _colordiff(a::C, b::C, m::DE_94) where {T, C <: Union{Lab{T}, LCHab{T}}}
    F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)

    # Calculate the delta values for each channel
    dl, dc, dh = b.l - a.l, delta_c(b, a), delta_h(b, a)

    # Lightness, hue, chroma correction terms
    # sl = 1
    sc = muladd(F(m.k1), chroma(a), 1)
    sh = muladd(F(m.k2), chroma(a), 1)

    sqrt((dl/F(m.kl))^2 + (dc/(F(m.kc)*sc))^2 + (dh/(F(m.kh)*sh))^2)
end

# Metric form of jpc79 color difference equation (mostly obsolete)
function _colordiff(a::Color, b::Color, m::DE_JPC79)
    _colordiff(promote(convert(Lab, a), convert(Lab, b))..., m)
end
function _colordiff(a::C, b::C, ::DE_JPC79) where {T, C <: Union{Lab{T}, LCHab{T}}}
    F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)

    # Calculate deltas in each direction
    dl, dc, dh = b.l - a.l, delta_c(b, a), delta_h(b, a)

    # Calculate mean lightness, chroma and hue
    ml, mc, mh = (a.l + b.l) * F(0.5), (chroma(a) + chroma(b)) * F(0.5), mean_hue(a, b)

    # L* adjustment term
    sl = F(0.08195) * ml / muladd(F(0.01765), ml, 1)

    # C* adjustment term
    sc = F(0.638) + F(0.0638) * mc / muladd(F(0.0131), mc, 1)

    # H* adjustment term
    if mc < F(0.38)
        sh = sc
    elseif mh >= 164 && mh <= 345
        sh = sc * muladd(F(0.2), abs(cosd(mh + 168)), F(0.56))
    else
        sh = sc * muladd(F(0.4), abs(cosd(mh +  35)), F(0.38))
    end

    # Calculate the final difference
    sqrt((dl/sl)^2 + (dc/sc)^2 + (dh/sh)^2)
end


# Metric form of the cmc color difference
function _colordiff(a::Color, b::Color, m::DE_CMC)
    _colordiff(promote(convert(Lab, a), convert(Lab, b))..., m)
end
function _colordiff(a::C, b::C, m::DE_CMC) where {T, C <: Union{Lab{T}, LCHab{T}}}
    F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)

    ac, ah = chroma(a), hue(a)

    # Calculate deltas in each direction
    dl, dc, dh = b.l - a.l, delta_c(b, a), delta_h(b, a)

    # L* adjustment term
    if a.l < 16
        sl = F(0.511)
    else
        sl = F(0.040975) * a.l / muladd(F(0.01765), a.l, 1)
    end

    # C* adjustment term
    sc = F(0.0638) * ac / muladd(F(0.0131), ac, 1) + F(0.638)

    f = sqrt(ac^4 / (ac^4 + 1900))

    if 164 <= ah <= 345
        t = muladd(F(0.2), abs(cosd(ah + 168)), F(0.56))
    else
        t = muladd(F(0.4), abs(cosd(ah +  35)), F(0.36))
    end

    # H* adjustment term
    sh = sc * muladd(t, f, 1 - f)

    # Calculate the final difference
    sqrt((dl/(F(m.kl)*sl))^2 + (dc/(F(m.kc)*sc))^2 + (dh/sh)^2)
end

# The BFD color difference equation
function _colordiff(a::Color, b::Color, m::DE_BFD)
    # We have to start back in XYZ because BFD uses a different L equation
    # Currently, support for the `wp` argument of `convert` is limited.
    function to_xyz(c::Color{T}, wp) where T
        F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)
        c isa XYZ && return c
        (c isa xyY || c isa LMS) && return convert(XYZ, c)
        wpf = XYZ{F}(wp)
        (c isa Lab || c isa Luv) && return convert(XYZ, c, wpf)
        c isa LCHuv && return convert(XYZ, convert(Luv, c), wpf)
        convert(XYZ, convert(Lab, c), wpf)
    end
    _colordiff(promote(to_xyz(a, m.wp), to_xyz(b, m.wp))..., m)
end
function _colordiff(a_xyz::XYZ{T}, b_xyz::XYZ{T}, m::DE_BFD) where T
    F = typeof(0.5f0 * zero(T)) === Float32 ? Float32 : promote_type(Float64, T)

    l_bfd(y) = muladd(F(54.6), log10(y + F(1.5)), F(-9.6))
    la, lb = l_bfd.((a_xyz.y, b_xyz.y))

    # Convert into Lab with the proper white point
    wpf = XYZ{F}(m.wp)
    a_lab = convert(Lab, a_xyz, wpf)
    b_lab = convert(Lab, b_xyz, wpf)

    # Substitute the different L values
    a = Lab(la, a_lab.a, a_lab.b)
    b = Lab(lb, b_lab.a, b_lab.b)

    # Calculate deltas in each direction
    dl, dc, dh = b.l - a.l, delta_c(b, a), delta_h(b, a)

    # Find the mean value of the inputs to use as the "standard"
    mc, mh = (chroma(a) + chroma(b)) * F(0.5), mean_hue(a, b)

    # Correction terms for a variety of nonlinearities in CIELAB.
    g = sqrt(mc^4 / (mc^4 + 14000))

    t_cos = F( 55) * cosd( mh - 245) +
            F(-40) * cosd(2mh - 136) +
            F( 70) * cosd(3mh -  32) +
            F( 49) * cosd(4mh + 114) +
            F(-15) * cosd(5mh + 103)
    t = muladd(F(1/1000), t_cos, F(0.627))

    rc = sqrt(mc^6 / (mc^6 + F(7e7)))

    rh = F(-0.260) * cosd( mh - 308) +
         F(-0.379) * cosd(2mh - 160) +
         F(-0.636) * cosd(3mh - 254) +
         F( 0.226) * cosd(4mh + 140) +
         F(-0.194) * cosd(5mh + 280)

    dcc = muladd(F(0.035), mc / muladd(F(0.00365), mc, 1) , F(0.521))
    dhh = dcc * muladd(g, t, 1 - g)
    rt = rc * rh

    # Final calculation
    sqrt((dl/F(m.kl))^2 + (dc/(F(m.kc)*dcc))^2 + (dh/dhh)^2 + rt*((dc*dh)/(dcc*dhh)))
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
