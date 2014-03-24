# Color Difference Metrics
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

function colordiff_2000(ai::ColorValue, bi::ColorValue)
    # Ensure that the input values are in L*a*b* space
    a = convert(LAB, ai)
    b = convert(LAB, bi)

    # Calculate some necessary factors from the L*a*b* values
    ac, bc = sqrt(a.a^2 + a.b^2), sqrt(b.a^2 + b.b^2)
    mc = (ac + bc)/2
    g = (1 - sqrt(mc^7 / (mc^7 + 25^7))) / 2
    a = LAB(a.l, a.a * (1 + g), a.b)
    b = LAB(b.l, b.a * (1 + g), b.b)

    # Convert to L*C*h, where the remainder of the calculations are performed
    a = convert(LCHab, a)
    b = convert(LCHab, b)

    # Calculate the delta values for each channel
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
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
    elseif abs(b.h - a.h) > 180
        if a.h + b.h < 360
            mh = (a.h + b.h + 360) / 2
        else
            mh = (a.h + b.h - 360) / 2
        end
    else
        mh = (a.h + b.h) / 2
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
    cr = 2 * sqrt(mc^7 / (mc^7 + 25^7))
    tr = -sind(2*dtheta) * cr

    # Final calculation
    sqrt((dl/sl)^2 + (dc/sc)^2 + (dh/sh)^2 +
         tr * (dc/sc) * (dh/sh))
end

# Leave the default function as-is.
colordiff = colordiff_2000

# Delta E94
function colordiff_94(ai::ColorValue, bi::ColorValue)

    # FIXME: Right now, tuning parameters are fixed at 1.
    kl = 1
    kc = 1
    kh = 1

    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate the delta values for each channel
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
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

    sqrt((dl/(kl*sl))^2 + (dc/(kc*sc))^2 + (dh/(kh*sh))^2)

end

# Metric form of jpc79 color difference equation (mostly obsolete)
function colordiff_jpc79(ai::ColorValue, bi::ColorValue)

    # Convert directly into LCh
    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
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
    elseif abs(b.h - a.h) > 180
        if a.h + b.h < 360
            mh = (a.h + b.h + 360) / 2
        else
            mh = (a.h + b.h - 360) / 2
        end
    else
        mh = (a.h + b.h) / 2
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
function colordiff_cmc(ai::ColorValue, bi::ColorValue)

    # FIXME: we do not provide user control over these two parameters!
    l = 1
    c = 1

    # Convert directly into LCh
    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
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
    elseif abs(b.h - a.h) > 180
        if a.h + b.h < 360
            mh = (a.h + b.h + 360) / 2
        else
            mh = (a.h + b.h - 360) / 2
        end
    else
        mh = (a.h + b.h) / 2
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
    sqrt((dl/(l*sl))^2 + (dc/(c*sc))^2 + (dh/sh)^2)

end

# The BFD color difference equation
function colordiff_bfd(ai::ColorValue, bi::ColorValue, wp::XYZ = WP_D65)

    # FIXME: Right now, tuning parameters are fixed at 1.
    l = 1
    c = 1

    # We have to start back in XYZ because BFD uses a different L equation
    a = convert(XYZ, ai, wp)
    b = convert(XYZ, bi, wp)

    la = 54.6*log10(a.y+1.5)-9.6
    lb = 54.6*log10(b.y+1.5)-9.6

    # Convert into LCh
    a = convert(LCHab, ai)
    b = convert(LCHab, bi)

    # Substitute in the different L values into the L*C*h values
    a = LCHab(la, a.c, a.h)
    b = LCHab(lb, b.c, b.h)

    # Calculate deltas in each direction
    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
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
    elseif abs(b.h - a.h) > 180
        if a.h + b.h < 360
            mh = (a.h + b.h + 360) / 2
        else
            mh = (a.h + b.h - 360) / 2
        end
    else
        mh = (a.h + b.h) / 2
    end

    # Too many correction terms.....
    g = sqrt(mc^4/(mc^4 + 14000))

    t = 0.627 + 0.055*cosd(mh - 245) - 0.04*cosd(2*mh - 136) + 0.07*cosd(3*mh - 32) + 0.049*cosd(4*mh + 114) - 0.015*cosd(5*mh + 103)

    rc = sqrt(mc^6/(mc^6 + 7e7))

    rh = -0.26cosd(mh-308) - 0.379cosd(2*mh-160) - 0.636*cosd(3*mh - 254) + 0.226cosd(4*mh + 140) - 0.194*cosd(5*mh + 280)

    dcc = 0.035*mc/(1+0.00365*mc) + 0.521
    dhh = dcc*(g*t+1-g)
    rt = rc*rh

    # Final calculation
    a = sqrt((dl/l)^2 + (dc/(c*dcc))^2 + (dh/dhh)^2 + rt*((dc*dh)/(dcc*dhh)))

end

# Delta E*ab (the original)
function colordiff_ab(ai::ColorValue, bi::ColorValue)

    # Convert directly into L*a*b*
    a = convert(LAB, ai)
    b = convert(LAB, bi)

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
function colordiff_din99(ai::ColorValue, bi::ColorValue)

    a = convert(DIN99, ai)
    b = convert(DIN99, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# A color difference formula for the DIN99d uniform color space
function colordiff_din99d(ai::ColorValue, bi::ColorValue)

    a = convert(DIN99d, ai)
    b = convert(DIN99d, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end

# The DIN99o color difference metric evaluated between colors a and b.
function colordiff_din99o(ai::ColorValue, bi::ColorValue)

    a = convert(DIN99o, ai)
    b = convert(DIN99o, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end
