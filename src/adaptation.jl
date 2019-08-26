# Chromatic Adaptation / Whitebalancing
# -------------------------------------

# Define an abstract type to represent chromatic adaptation transform
abstract type AbstractCAT end

"""
There is incompatibility between `MatrixCAT` and `NonLinearCAT`.
In other words, `MatrixCAT` is never a special case or subtype of `NonLinearCAT`.

In the `MatrixCAT` adaptation, the flow is as follows:
    `XYZ` -(Matrix CAT)-> `LMS` -(white point conversion)-> `LMS` -(inv. Matrix CAT)-> `XYZ`
In the white point conversion, the von Kries model, i.e. the diagonal matrix, is used.


In the `NonLinearCAT` adaptation, the flow is as follows:
    `XYZ` -(CAT w/ white balancing)-> `LMS` -(inv. CAT w/ white balancing)-> `XYZ`

"""
abstract type MatrixCAT <: AbstractCAT end

abstract type NonLinearCAT<: AbstractCAT end

const EYE3x3 = [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0]

# Hunt-Pointer-Estevez (also called von Kries) transformation matrix
const HPE = [ 0.38971  0.68898 -0.07868
             -0.22981  1.18340  0.04641
              0.00000  0.00000  1.00000 ]

const HPE_INV = inv(HPE)

# Bradford transformation matrix from v4 ICC Specification
const BFD = [ 0.8951  0.2664 -0.1614
             -0.7502  1.7135  0.0367
              0.0389 -0.0685  1.0296 ]

const BFD_INV = inv(BFD)

# Chromatic adaptation from CIECAM97s
const CAT97s = [ 0.8562  0.3372 -0.1934
                -0.8360  1.8327  0.0033
                 0.0357 -0.0469  1.0112 ]

const CAT97s_INV = inv(CAT97s)

# Chromatic adaptation from CIECAM02
const CAT02 = [ 0.7328 0.4296 -0.1624
               -0.7036 1.6975  0.0061
                0.0030 0.0136  0.9834 ]

const CAT02_INV = inv(CAT02)


# MatrixCATs
# ----------

# XYZ-space conversion
struct CAT_XYZ <: MatrixCAT
end
cat_cnvt(::CAT_XYZ) = EYE3x3
cat_invt(::CAT_XYZ) = EYE3x3


struct CAT_HPE <: MatrixCAT
end
cat_cnvt(::CAT_HPE) = HPE
cat_invt(::CAT_HPE) = HPE_INV


struct CAT_BFD <: MatrixCAT
end
cat_cnvt(::CAT_BFD) = BFD
cat_invt(::CAT_BFD) = BFD_INV


struct CAT_97s <: MatrixCAT
end
cat_cnvt(::CAT_97s) = CAT97s
cat_invt(::CAT_97s) = CAT97s_INV


struct CAT_02 <: MatrixCAT
end
cat_cnvt(::CAT_02) = CAT02
cat_invt(::CAT_02) = CAT02_INV

# NonLinearCATs
# -------------

# TODO: add non-linear CATs




"""
    whitebalance(c, src_white, ref_white)

Whitebalance a color.

Input a source (adopted) and destination (reference) white. E.g., if you have
a photo taken under florencent lighting that you then want to appear correct
under regular sunlight, you might do something like
`whitebalance(c, Colors.WP_F2, Colors.WP_D65)`.


Args:

- `c`: An observed color.
- `src_white`: Adopted or source white corresponding to `c`.
- `ref_white`: Reference or destination white.

Returns:
  A whitebalanced color.
"""
function whitebalance(c::T, src_white::Color, ref_white::Color) where T <: Color
    c_lms = convert(LMS, c)
    src_wp = convert(LMS, src_white)
    dest_wp = convert(LMS, ref_white)

    # This is sort of simplistic, it sets the degree of adaptation term in
    # CAT02 to 1.
    ans = LMS(c_lms.l * dest_wp.l / src_wp.l,
              c_lms.m * dest_wp.m / src_wp.m,
              c_lms.s * dest_wp.s / src_wp.s)

    convert(T, ans)
end
