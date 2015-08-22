
# Define an abstract type to represent color difference metrics
abstract DifferenceMetric

# TODO?: make the DifferenMetrics parametric, to preserve type-stability

# CIE Delta E 2000 recommendation
immutable DE_2000 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
    DE_2000(kl,kc,kh) = new(kl,kc,kh)
    DE_2000() = new(1,1,1)
end

# CIE Delta E 94 recommendation
immutable DE_94 <: DifferenceMetric
    kl::Float64
    kc::Float64
    kh::Float64
    DE_94(kl,kc,kh) = new(kl,kc,kh)
    DE_94() = new(1,1,1)
end

# McDonald "JP Coates Thread Company" formulation
immutable DE_JPC79 <: DifferenceMetric

end

# CMC recommendation
immutable DE_CMC <: DifferenceMetric
    kl::Float64
    kc::Float64
    DE_CMC(kl,kc) = new(kl,kc)
    DE_CMC() = new(1,1)
end

# BFD recommendation
immutable DE_BFD <: DifferenceMetric
    wp::XYZ{Float64}
    kl::Float64
    kc::Float64
    DE_BFD(wp,kl,kc) = new(wp,kl,kc)
    DE_BFD() = new(WP_DEFAULT,1,1)
    DE_BFD(kl, kc) = new(WP_DEFAULT,kl, kc)
end

# The original CIE Delta E equation (Euclidian)
immutable DE_AB <: DifferenceMetric

end

# DIN99 color difference (Euclidian)
immutable DE_DIN99 <: DifferenceMetric

end

# DIN99d color difference (Euclidian)
immutable DE_DIN99d <: DifferenceMetric

end

# DIN99o color difference (Euclidian)
immutable DE_DIN99o <: DifferenceMetric

end

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
const twentyfive7 = 25^7

# Delta E 2000
function colordiff(ai::Color, bi::Color, m::DE_2000)
    # Ensure that the input values are in L*a*b* space
    a_Lab = convert(Lab, ai)
    b_Lab = convert(Lab, bi)

    # Calculate some necessary factors from the L*a*b* values
    ac, bc = sqrt(a_Lab.a^2 + a_Lab.b^2), sqrt(b_Lab.a^2 + b_Lab.b^2)
    mc = (ac + bc)/2
    g = (1 - sqrt(pow7(mc) / (pow7(mc) + twentyfive7))) / 2
    a_Lab = Lab(a_Lab.l, a_Lab.a * (1 + g), a_Lab.b)
    b_Lab = Lab(b_Lab.l, b_Lab.a * (1 + g), b_Lab.b)

    # Convert to L*C*h, where the remainder of the calculations are performed
    a = convert(LCHab, a_Lab)
    b = convert(LCHab, b_Lab)

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
function colordiff(ai::Color, bi::Color, m::DE_94)

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
function colordiff(ai::Color, bi::Color, m::DE_JPC79)

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
function colordiff(ai::Color, bi::Color, m::DE_CMC)

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
    ml, mc = (a.l + b.l)/2, (a.c + b.c)/2

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
function colordiff(ai::Color, bi::Color, m::DE_BFD)

    # We have to start back in XYZ because BFD uses a different L equation
    a_XYZ = convert(XYZ, ai, m.wp)
    b_XYZ = convert(XYZ, bi, m.wp)

    la = 54.6*log10(a_XYZ.y+1.5)-9.6
    lb = 54.6*log10(b_XYZ.y+1.5)-9.6

    # Convert into LCh with the proper white point
    a_Lab = convert(Lab, a_XYZ, m.wp)
    b_Lab = convert(Lab, b_XYZ, m.wp)
    a1 = convert(LCHab, a_Lab)
    b1 = convert(LCHab, b_Lab)

    # Substitute in the different L values into the L*C*h values
    a = LCHab(la, a1.c, a1.h)
    b = LCHab(lb, b1.c, b1.h)

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

# Delta E*ab (the original)
function colordiff(ai::Color, bi::Color, m::DE_AB)

    # Convert directly into L*a*b*
    a = convert(Lab, ai)
    b = convert(Lab, bi)

    dl, da, db = (b.l - a.l), (b.a - a.a), (b.b - a.b)

    sqrt(dl^2 + da^2 + db^2)

end

# Evaluate the DIN99 color difference formula, implemented according to the
# DIN 6176 specification.
#
# Args:
#   a, b: Any two colors.
#
# Returns:
#   The DIN99 color difference metric evaluated between a and b.
function colordiff(ai::Color, bi::Color, m::DE_DIN99)

    a = convert(DIN99, ai)
    b = convert(DIN99, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# A color difference formula for the DIN99d uniform color space
function colordiff(ai::Color, bi::Color, m::DE_DIN99d)

    a = convert(DIN99d, ai)
    b = convert(DIN99d, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# The DIN99o color difference metric evaluated between colors a and b.
function colordiff(ai::Color, bi::Color, m::DE_DIN99o)

    a = convert(DIN99o, ai)
    b = convert(DIN99o, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# Default to Delta E 2000
@doc """
    colordiff(a, b)
    colordiff(a, b, metric)

Compute an approximate measure of the perceptual difference between
colors `a` and `b`.  Optionally, a `metric` may be supplied, chosen
among `DE_2000` (the default), `DE_94`, `DE_JPC79`, `DE_CMC`,
`DE_BFD`, `DE_AB`, `DE_DIN99`, `DE_DIN99d`, `DE_DIN99o`.
""" ->
colordiff(ai::Color, bi::Color) = colordiff(ai::Color, bi::Color, DE_2000())
