# Arithmetic
#XYZ and LMS are linear vector spaces
typealias Linear3 Union{XYZ, LMS}
+{C<:Linear3}(a::C, b::C) = C(comp1(a)+comp1(b), comp2(a)+comp2(b), comp3(a)+comp3(b))
-{C<:Linear3}(a::C, b::C) = C(comp1(a)-comp1(b), comp2(a)-comp2(b), comp3(a)-comp3(b))
-(a::Linear3) = typeof(a)(-comp1(a), -comp2(a), -comp3(a))
*(c::Number, a::Linear3) = base_color_type(a)(c*comp1(a), c*comp2(a), c*comp3(a))
/(a::Linear3, c::Number) = base_color_type(a)(comp1(a)/c, comp2(a)/c, comp3(a)/c)

# Algorithms relating to color processing and generation


# Chromatic Adaptation / Whitebalancing
# -------------------------------------

"""
    whitebalance(c, src_white, ref_white)

Whitebalance a color.

Input a source (adopted) and destination (reference) white. E.g., if you have
a photo taken under florencent lighting that you then want to appear correct
under regular sunlight, you might do something like
`whitebalance(c, WP_F2, WP_D65)`.

Args:

- `c`: An observed color.
- `src_white`: Adopted or source white corresponding to `c`
- `ref_white`: Reference or destination white.

Returns:
  A whitebalanced color.
"""
function whitebalance{T <: Color}(c::T, src_white::Color, ref_white::Color)
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
long-wavelength photopigment).  `c` is the input color; the optional
argument `p` is the fraction of photopigment loss, in the range 0 (no
loss) to 1 (complete loss).
"""
function protanopic{T <: Color}(q::T, p, neutral::LMS)
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
middle-wavelength photopigment).  See the description of `protanopic` for detail about the arguments.
"""
function deuteranopic{T <: Color}(q::T, p, neutral::LMS)
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
short-wavelength photogiment).  See `protanopic` for more detail about
the arguments.
"""
function tritanopic{T <: Color}(q::T, p, neutral::LMS)
    q = convert(LMS, q)
    anchor_wavelen = q.m / q.l < neutral.m / neutral.l ? 660 : 485
    anchor = colormatch(anchor_wavelen)
    anchor = convert(LMS, anchor)
    (a, b, c) = brettel_abc(neutral, anchor)

    q = LMS(q.l,
            q.m,
            (one(p) - p) * q.l + p * (-(a*q.l + b*q.m)/c))
    convert(T, q)
end


protanopic(c::Color, p)   = protanopic(c, p, default_brettel_neutral)
deuteranopic(c::Color, p) = deuteranopic(c, p, default_brettel_neutral)
tritanopic(c::Color, p)   = tritanopic(c, p, default_brettel_neutral)

protanopic(c::Color)   = protanopic(c, 1.0)
deuteranopic(c::Color) = deuteranopic(c, 1.0)
tritanopic(c::Color)   = tritanopic(c, 1.0)

Compat.@dep_vectorize_1arg Color protanopic
Compat.@dep_vectorize_1arg Color deuteranopic
Compat.@dep_vectorize_1arg Color tritanopic

# MSC - Most Saturated Colorant for given hue h
# ---------------------

"""
    MSC(h)
    MSC(h, l)

Calculates the most saturated color for any given hue `h` by
finding the corresponding corner in LCHuv space. Optionally,
the lightness `l` may also be specified.
"""
function MSC(h)

    #Corners of RGB cube
    const h0 = 12.173988685914473 #convert(LCHuv,RGB(1,0,0)).h
    const h1 = 85.872748860776770 #convert(LCHuv,RGB(1,1,0)).h
    const h2 = 127.72355046632740 #convert(LCHuv,RGB(0,1,0)).h
    const h3 = 192.17397321802082 #convert(LCHuv,RGB(0,1,1)).h
    const h4 = 265.87273498040290 #convert(LCHuv,RGB(0,0,1)).h
    const h5 = 307.72354567594960 #convert(LCHuv,RGB(1,0,1)).h

    #Wrap h to [0, 360] range]
    h = mod(h, 360)

    p=0 #variable
    o=0 #min
    t=0 #max

    #Selecting edge of RGB cube; R=1 G=2 B=3
    if h0 <= h < h1
        p=2; o=3; t=1
    elseif h1 <= h < h2
        p=1; o=3; t=2
    elseif h2 <= h < h3
        p=3; o=1; t=2
    elseif h3 <= h < h4
        p=2; o=1; t=3
    elseif h4 <= h < h5
        p=1; o=2; t=3
    elseif h5 <= h || h < h0
        p=3; o=2; t=1
    end

    col=zeros(3)

    #check if we are directly on the edge of the RGB cube (within some tolerance)
    for edge in [h0, h1, h2, h3, h4, h5]
        if edge - 200eps() < h < edge + 200eps()
            col[p] = edge in [h0, h2, h4] ? 0.0 : 1.0
            col[o] = 0.0
            col[t] = 1.0
            return convert(LCHuv, RGB(col[1],col[2],col[3]))
        end
    end

    alpha=-sind(h)
    beta=cosd(h)

    #un &vn are calculated based on reference white (D65)
    #X=0.95047; Y=1.0000; Z=1.08883
    const un=0.19783982482140777 #4.0X/(X+15.0Y+3.0Z)
    const vn=0.46833630293240970 #9.0Y/(X+15.0Y+3.0Z)

    #sRGB matrix
    const M=[0.4124564  0.3575761  0.1804375;
             0.2126729  0.7151522  0.0721750;
             0.0193339  0.1191920  0.9503041]'
    const g=2.4

    m_tx=M[t,1]
    m_ty=M[t,2]
    m_tz=M[t,3]
    m_px=M[p,1]
    m_py=M[p,2]
    m_pz=M[p,3]

    f1=(4alpha*m_px+9beta*m_py)
    a1=(4alpha*m_tx+9beta*m_ty)
    f2=(m_px+15m_py+3m_pz)
    a2=(m_tx+15m_ty+3m_tz)

    cp=((alpha*un+beta*vn)*a2-a1)/(f1-(alpha*un+beta*vn)*f2)

    #gamma inversion
    cp = cp <= 0.003 ? 12.92cp : 1.055cp^(1.0/g)-0.05
    #cp = 1.055cp^(1.0/g)-0.05

    col[p]=clamp01(cp)
    col[o]=0.0
    col[t]=1.0

    return convert(LCHuv, RGB(col[1],col[2],col[3]))
end


# Maximum saturation for given lightness and hue
# ----------------------

# Maximally saturated color for a specific hue and lightness
# is found by looking for the edge of LCHuv space.
function MSC(h,l)
    pmid=MSC(h)

    if l <= pmid.l
        pend=LCHuv(0,0,0)
    elseif l > pmid.l
        pend=LCHuv(100,0,0)
    end

    a=(pend.l-l)/(pend.l-pmid.l)
    a*(pmid.c-pend.c)+pend.c
end
