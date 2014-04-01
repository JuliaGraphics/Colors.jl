# Color Difference Metrics
# ------------------------

# CIE Delta-E 2000
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
function colordiff(ai::ColorValue, bi::ColorValue)
    a = convert(LAB, ai)
    b = convert(LAB, bi)

    ac, bc = sqrt(a.a^2 + a.b^2), sqrt(b.a^2 + b.b^2)
    mc = (ac + bc)/2
    g = (1 - sqrt(mc^7 / (mc^7 + 25^7))) / 2
    a = LAB(a.l, a.a * (1 + g), a.b)
    b = LAB(b.l, b.a * (1 + g), b.b)

    a = convert(LCHab, a)
    b = convert(LCHab, b)

    dl, dc, dh = (b.l - a.l), (b.c - a.c), (b.h - a.h)
    if a.c * b.c == 0
        dh = 0
    elseif dh > 180
        dh -= 360
    elseif dh < -180
        dh += 360
    end
    dh = 2 * sqrt(a.c * b.c) * sind(dh/2)

    ml, mc = (a.l + b.l) / 2, (a.c + b.c) / 2
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

    sqrt((dl/sl)^2 + (dc/sc)^2 + (dh/sh)^2 +
         tr * (dc/sc) * (dh/sh))
end


# DIN99
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


# DIN99o
# Evaluate the DIN99o color difference formula, implemented according to the
# DIN 6176 specification.
#
# Args:
#   a, b: Any two colors.
#
# Returns:
#   The DIN99o color difference metric evaluated between a and b.
function colordiff_din99o(ai::ColorValue, bi::ColorValue)

    a = convert(DIN99o, ai)
    b = convert(DIN99o, bi)

    sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)

end
