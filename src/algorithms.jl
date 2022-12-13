# Arithmetic
#XYZ and LMS are linear vector spaces
const Linear3 = Union{XYZ, LMS}
+(a::Linear3, b::Linear3) = mapc(+, a, b)
-(a::Linear3, b::Linear3) = mapc(-, a, b)
-(a::Linear3) = mapc(-, a)
*(k::Number, a::Linear3) = mapc(v -> k * v, a)
*(a::Linear3, k::Number) = k * a
/(a::Linear3, k::Number) = mapc(v -> v / k, a)

# Algorithms relating to color processing and generation


# Chromatic Adaptation / Whitebalancing
# -------------------------------------

"""
    whitebalance(c, src_white, ref_white)

Whitebalance a color.

Input a source (adopted) and destination (reference) white. For example, if you want a photo
taken under fluorescent lighting to appear correct in regular sunlight, you might do
something like `whitebalance(c, WP_F2, WP_D65)`.

# Arguments

- `c`: An observed color.
- `src_white`: Adopted or source white corresponding to `c`
- `ref_white`: Reference or destination white.

Returns a whitebalanced color.
"""
function whitebalance(c::T, src_white::Color, ref_white::Color) where T <: Color
    c_lms = convert(LMS, c)
    src_wp = convert(LMS, src_white)
    dest_wp = convert(LMS, ref_white)

    # This is sort of simplistic, it sets the degree of adaptation term in
    # CAT02 to 0.
    # Setting the degree of adaptation to 0 is rather odd. Wouldn’t setting
    # it to 1.0 make more sense as a temporary default value?
    ans = LMS(c_lms.l * dest_wp.l / src_wp.l,
              c_lms.m * dest_wp.m / src_wp.m,
              c_lms.s * dest_wp.s / src_wp.s)

    convert(T, ans)
end


# Simulation of color deficiency (color "blindness")
# ----------------------------

# This method is due to:
# Brettel, H., Viénot, F., & Mollon, J. D. (1997).  Computerized simulation of
# color appearance for dichromats. Josa A, 14(10), 2647–2655.
#
# These functions add to Brettel's method a parameter p in [0, 1] giving the
# degree of photopigment loss. At p = 1, the complete loss of a particular
# photopigment is simulated, where 0 < p < 1 represents partial loss.


# This is supposed to be "the brightest possible metamer of an equal-energy
# stimulus". I'm punting a bit and just calling that RGB white.
const default_brettel_neutral = convert(LMS, RGB(1, 1, 1))


# Helper function for Brettel conversions.
function brettel_abc(neutral::LMS, anchor::LMS)
    a = neutral.m * anchor.s - neutral.s * anchor.m
    b = neutral.s * anchor.l - neutral.l * anchor.s
    c = neutral.l * anchor.m - neutral.m * anchor.l
    (a, b, c)
end


"""
    protanopic(c)
    protanopic(c, p)

Convert a color to simulate protanopic color deficiency (lack of the
long-wavelength photopigment). `c` is the input color; the optional
argument `p` is the fraction of photopigment loss, in the range 0 (no
loss) to 1 (complete loss).
"""
function protanopic(q::T, p, neutral::LMS) where T <: Color
    q = convert(LMS, q)
    anchor_wavelen = q.s / q.m < neutral.s / neutral.m ? 575 : 475
    anchor = colormatch(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS((one(p) - p) * q.l + p * (-(b*q.m + c*q.s)/a),
            q.m,
            q.s)
    convert(T, q)
end


"""
    deuteranopic(c)
    deuteranopic(c, p)

Convert a color to simulate deuteranopic color deficiency (lack of the
middle-wavelength photopigment). See [`protanopic`](@ref) for detail about the arguments.
"""
function deuteranopic(q::T, p, neutral::LMS) where T <: Color
    q = convert(LMS, q)
    anchor_wavelen = q.s / q.l < neutral.s / neutral.l ? 575 : 475
    anchor = colormatch(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS(q.l,
            (one(p) - p) * q.m + p * (-(a*q.l + c*q.s)/b),
            q.s)
    convert(T, q)
end


"""
    tritanopic(c)
    tritanopic(c, p)

Convert a color to simulate tritanopic color deficiency (lack of the
short-wavelength photopigment). See [`protanopic`](@ref) for detail about
the arguments.
"""
function tritanopic(q::T, p, neutral::LMS) where T <: Color
    q = convert(LMS, q)
    anchor_wavelen = q.m / q.l < neutral.m / neutral.l ? 660 : 485
    anchor = colormatch(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS(q.l,
            q.m,
            (one(p) - p) * q.s + p * (-(a*q.l + b*q.m)/c))
    convert(T, q)
end


protanopic(c::Color, p)   = protanopic(c, p, default_brettel_neutral)
deuteranopic(c::Color, p) = deuteranopic(c, p, default_brettel_neutral)
tritanopic(c::Color, p)   = tritanopic(c, p, default_brettel_neutral)

protanopic(c::Color)   = protanopic(c, 1.0)
deuteranopic(c::Color) = deuteranopic(c, 1.0)
tritanopic(c::Color)   = tritanopic(c, 1.0)

# MSC - Most Saturated Colorant for given hue h
# ---------------------

"""
    MSC(h)
    MSC(h, l; linear=false)

Calculate the most saturated color in sRGB gamut for any given hue `h` by
finding the corresponding corner in LCHuv space. Optionally, the lightness `l`
may also be specified.

# Arguments

- `h`: Hue [0,360] in LCHuv space
- `l`: Lightness [0,100] in LCHuv space

# Keyword arguments

- `linear` : If true, the saturation is linearly interpolated between black/
  white and `MSC(h)` as the gamut is approximately triangular in L-C section.

!!! note
    `MSC(h)` returns an `LCHuv` color, but `MSC(h, l)` returns a saturation
    value. This behavior might change in a future release.

"""
function MSC(h)

    #Wrap h to [0, 360] range
    h = normalize_hue(Float64(h))

    #Selecting edge of RGB cube; R=1 G=2 B=3
    # p #variable
    # o #min
    # t #max
    if     h < 12.173988685914473 #convert(LCHuv,RGB(1,0,0)).h
        p=3; t=1
    elseif h < 85.872748860776770 #convert(LCHuv,RGB(1,1,0)).h
        p=2; t=1
    elseif h < 127.72355046632740 #convert(LCHuv,RGB(0,1,0)).h
        p=1; t=2
    elseif h < 192.17397321802082 #convert(LCHuv,RGB(0,1,1)).h
        p=3; t=2
    elseif h < 265.87273498040290 #convert(LCHuv,RGB(0,0,1)).h
        p=2; t=3
    elseif h < 307.72354567594960 #convert(LCHuv,RGB(1,0,1)).h
        p=1; t=3
    else
        p=3; t=1
    end

    alpha=-sind(h)
    beta=cosd(h)

    #un &vn are calculated based on reference white (D65)
    #X=0.95047; Y=1.0000; Z=1.08883
    un = 0.19783982482140777 #4.0X/(X+15.0Y+3.0Z)
    vn = 0.46833630293240970 #9.0Y/(X+15.0Y+3.0Z)

    #sRGB matrix
    M = [0.4124564  0.3575761  0.1804375;
         0.2126729  0.7151522  0.0721750;
         0.0193339  0.1191920  0.9503041]'

    m_tx=M[t,1]
    m_ty=M[t,2]
    m_tz=M[t,3]
    m_px=M[p,1]
    m_py=M[p,2]
    m_pz=M[p,3]

    f1 = 4alpha*m_px+9beta*m_py
    a1 = 4alpha*m_tx+9beta*m_ty
    f2 = m_px+15m_py+3m_pz
    a2 = m_tx+15m_ty+3m_tz

    cp=((alpha*un+beta*vn)*a2-a1)/(f1-(alpha*un+beta*vn)*f2)

    col = zeros(3)
    col[p] = clamp01(srgb_compand(cp))
    # col[o] = 0.0
    col[t] = 1.0

    return convert(LCHuv, RGB(col[1],col[2],col[3]))
end


# Maximum saturation for given lightness and hue
# ----------------------

# Maximally saturated color for a specific hue and lightness
# is found by looking for the edge of LCHuv space.
function MSC(h, l; linear::Bool=false)
    if linear
        pmid = MSC(h)
        pend_l = l > pmid.l ? 100.0 : 0.0
        return (pend_l - l) / (pend_l - pmid.l) * pmid.c
    end
    return find_maximum_chroma(LCHuv{Float64}(l, 0, h))
end

# This function finds the maximum chroma for the lightness `c.l` and hue `c.h`
# by means of the binary search. Even though this requires more than 20
# iterations, somehow, this is fast.
function find_maximum_chroma(c::C,
                             low::Real=0,
                             high::Real=180) where {T, C<:Union{LCHab{T}, LCHuv{T}}}
    err = convert(T, 1e-6)
    l, h = convert(T, low), convert(T, high)
    h - l < err && return l

    mid = convert(T, (l + h) / 2)
    min(mid - l, h - mid) == zero(T) && return l
    lchm = C(c.l, mid, c.h)
    rgbm = convert(RGB{T}, lchm)
    clamped = max(red(rgbm), green(rgbm), blue(rgbm)) > 1-err ||
              min(red(rgbm), green(rgbm), blue(rgbm)) < err
    if clamped
        return find_maximum_chroma(c, l, mid)::T
    else
        return find_maximum_chroma(c, mid, h)::T
    end
end

function find_maximum_chroma(c::LCHab{T}) where T
    maxc = find_maximum_chroma(c, 0, 135)

    # The sRGB gamut in LCHab space has a *hollow* around the yellow corner.
    # Since the following boundary is based on the D65 white point, the values
    # should be modified on other conditions.
    if 97 < c.h < 108 && c.l > 92
        err = convert(T, 1e-6)
        len = 10000
        dh = convert(T, (100 - maxc) / len)
        h_yellow = 102.85124420310268 # convert(LCHab,RGB{Float64}(1,1,0)).h
        chroma = maxc
        for i = 1:len
            chroma += dh
            rgb = convert(RGB, LCHab(c.l, chroma, c.h))
            blue(rgb) < err && continue
            y = c.h < h_yellow ? red(rgb) : green(rgb)
            if y < 1-err
                maxc = chroma
            end
        end
    end
    return maxc
end
find_maximum_chroma(c::Lab) = find_maximum_chroma(convert(LCHab, c))
find_maximum_chroma(c::Luv) = find_maximum_chroma(convert(LCHuv, c))
