
abstract type AbstractGamut end

abstract type AbstractRGBGamut <: AbstractGamut end

absolute_whitepoint(gamut::Type{<:AbstractGamut}) =
    whitepoint(gamut) * whitepoint_luminance(gamut)
absolute_blackpoint(gamut::Type{<:AbstractGamut}) =
    blackpoint(gamut) * blackpoint_luminance(gamut)

luminance_range(gamut::Type{<:AbstractGamut}) =
    absolute_whitepoint(gamut) - absolute_blackpoint(gamut)

# fallback definitions
whitepoint(::Type{<:AbstractGamut}) = WP_E
whitepoint_luminance(::Type{<:AbstractGamut}) = 100.0
blackpoint(gamut::Type{<:AbstractGamut}) = whitepoint(gamut)
blackpoint_luminance(::Type{<:AbstractGamut}) = 0.0
gamma_compand(::Type{<:AbstractGamut}, v::Fractional) = Float64(v)^(1/2.2)
gamma_expand( ::Type{<:AbstractGamut}, v::Fractional) = Float64(v)^(2.2)

# Define the gamuts as abstract types so that Colors.jl in the future and the
# users can extend them.

# sRGB
abstract type Gamut_sRGB <: AbstractRGBGamut end
primary_red(  ::Type{<:Gamut_sRGB}) = xyY(0.64, 0.33, 1)
primary_green(::Type{<:Gamut_sRGB}) = xyY(0.30, 0.60, 1)
primary_blue( ::Type{<:Gamut_sRGB}) = xyY(0.15, 0.06, 1)
whitepoint(::Type{<:Gamut_sRGB}) = WP_D65
whitepoint_luminance(::Type{<:Gamut_sRGB}) = 80.0 # cd/m^2
blackpoint_luminance(::Type{<:Gamut_sRGB}) = 0.2 # cd/m^2

# Adobe RGB (1998)
abstract type Gamut_AdobeRGB <: AbstractRGBGamut end
primary_red(  ::Type{<:Gamut_AdobeRGB}) = xyY(0.64, 0.33, 1)
primary_green(::Type{<:Gamut_AdobeRGB}) = xyY(0.21, 0.71, 1)
primary_blue( ::Type{<:Gamut_AdobeRGB}) = xyY(0.15, 0.06, 1)
whitepoint(::Type{<:Gamut_AdobeRGB}) = WP_D65
whitepoint_luminance(::Type{<:Gamut_AdobeRGB}) = 160.0
blackpoint_luminance(::Type{<:Gamut_AdobeRGB}) = 0.5557

# original NTSC (1953) gamut
abstract type Gamut_NTSC <: AbstractRGBGamut end
primary_red(  ::Type{<:Gamut_NTSC}) = xyY(0.67, 0.33, 1)
primary_green(::Type{<:Gamut_NTSC}) = xyY(0.21, 0.71, 1)
primary_blue( ::Type{<:Gamut_NTSC}) = xyY(0.14, 0.08, 1)
whitepoint(::Type{<:Gamut_NTSC}) = WP_C

# SMPTE-C gamut
abstract type Gamut_SMPTE_C <: AbstractRGBGamut end
primary_red(  ::Type{<:Gamut_SMPTE_C}) = xyY(0.630, 0.340, 1)
primary_green(::Type{<:Gamut_SMPTE_C}) = xyY(0.310, 0.595, 1)
primary_blue( ::Type{<:Gamut_SMPTE_C}) = xyY(0.155, 0.070, 1)
whitepoint(::Type{<:Gamut_SMPTE_C}) = WP_D65


function gamma_compand(::Type{<:Gamut_sRGB}, v::Fractional)
    # `pow5_12` is an optimized function to get `v^(1/2.4)`
    v <= 0.0031308 ? 12.92v : 1.055 * pow5_12(v) - 0.055
end

@inline function gamma_expand(::Type{<:Gamut_sRGB}, v::Fractional)
    # `pow12_5` is an optimized function to get `x^2.4`
    v <= 0.04045 ? 1/12.92 * v : pow12_5(1/1.055 * (v + 0.055))
end

# lookup table for `N0f8` (the extra two elements are for `Float32` splines)
const srgb_expand_n0f8 = [gamma_expand(Gamut_sRGB, v/255.0) for v = 0:257]

function gamma_expand(::Type{<:Gamut_sRGB}, v::N0f8)
    @inbounds srgb_expand_n0f8[reinterpret(UInt8, v) + 1]
end

@inline function gamma_expand(::Type{<:Gamut_sRGB}, v::Float32)
    i = unsafe_trunc(Int32, v * 255)
    (i < 13 || i > 255) && return gamma_expand(Gamut_sRGB, Float64(v))
    @inbounds y = view(srgb_expand_n0f8, i:i+3)
    dv = v * 255.0 - i
    dv == 0.0 && @inbounds return y[2]
    if v < 0.38857287f0
        return @fastmath(y[2]+0.5*dv*((-2/3*y[1]- y[2])+(2y[3]-1/3*y[4])+
                                  dv*((     y[1]-2y[2])+  y[3]-
                                  dv*(( 1/3*y[1]- y[2])+( y[3]-1/3*y[4]) ))))
    else
        return @fastmath(y[2]+0.5*dv*((4y[3]-3y[2])-y[4]+dv*((y[4]-y[3])+(y[2]-y[3]))))
    end
end

gamma_compand(::Type{<:Gamut_AdobeRGB}, v::Fractional) = pow256_563(v)
gamma_expand( ::Type{<:Gamut_AdobeRGB}, v::Fractional) = pow563_256(v)

function mat_rgb_to_xyz(gamut::Type{<:AbstractRGBGamut},
                        wp::Union{XYZ, xyY}=whitepoint(gamut))
    pr, pg, pb = primary_red(gamut), primary_green(gamut), primary_blue(gamut)
    z(c::xyY) = 1 - c.x - c.y # Y == 1
    m_prim = BigFloat[ pr.x  pg.x  pb.x
                       pr.y  pg.y  pb.y
                       z(pr) z(pg) z(pb) ]
    w = convert(XYZ, wp)
    sr, sg, sb = inv(m_prim) * [w.x, w.y, w.z] # diag.
    @inbounds Float64[ m_prim[1,1]*sr m_prim[1,2]*sg m_prim[1,3]*sb
                       m_prim[2,1]*sr m_prim[2,2]*sg m_prim[2,3]*sb
                       m_prim[3,1]*sr m_prim[3,2]*sg m_prim[3,3]*sb ]
end

function mat_xyz_to_rgb(gamut::Type{<:AbstractRGBGamut},
                        wp::Union{XYZ, xyY}=whitepoint(gamut))
    Float64.(inv(BigFloat.(mat_rgb_to_xyz(gamut, wp))))
end

function convert_gamut(c::C,
                       src::Type{<:AbstractRGBGamut},
                       dest::Type{<:AbstractRGBGamut}) where C <: AbstractRGB
    T = floattype(eltype(C))
    xyz_src = mapc(*, rgb_to_xyz(XYZ{T}, c, src), luminance_range(src))
    xyz_src_a = xyz_src + absolute_blackpoint(src)
    xyz_dest = xyz_src_a - absolute_blackpoint(dest)
    xyz_to_rgb(C, mapc(/, xyz_dest, luminance_range(dest)), dest)
end
