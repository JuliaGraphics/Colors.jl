# Helper data for color parsing
include("names_data.jl")


# Color Parsing
# -------------

const col_pat_func3 = r"^\s*(?:rgba?|hsla?)
                               \(\s*([^\s,/\)]+)\s*
                            [,\s]\s*([^\s,/\)]+)\s*
                            [,\s]\s*([^\s,/\)]+)\s*
                            (?:[,/]\s*([^\s,/\)]+)\s*)?\)\s*$"ix
const col_pat_hex = r"^\s*(?:#|0x)([[:xdigit:]]{3,8})\s*$"
const col_pat_unitful = r"^([+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)(.*)$"i

chop1(x) = SubString(x, 1, lastindex(x) - 1) # `chop` is slightly slow

function parse_hex(hex::SubString{String}) # It is guaranteed to be a valid hex string.
    digits = UInt32(0)
    for d in codeunits(hex)
        dl = d | 0x20
        digits = (digits << 0x4) + dl - (dl < UInt8('a') ? UInt8('0') : UInt8('a') - 0xa)
    end
    return digits
end

function tryparse_dec(dec::SubString{String})
    de = 0
    for d in codeunits(dec)
        dx = d - UInt8('0')
        0x0 <= dx <= 0x9 || return nothing
        de = de * 10 + dx
    end
    return de
end

function parse_f32(dec::SubString{String})
    v = tryparse_dec(dec)
    v === nothing && return parse(Float32, dec)
    Float32(v)
end

# Parse a number used in the "rgb()" or "hsl()" color.

function parse_rgb(num::SubString{String})
    @inbounds num[end] == '%' && throw_rgb_unification_error()
    v = tryparse_dec(num)
    if v === nothing
        v = round(Int, parse(Float32, num))
    end
    return reinterpret(N0f8, unsafe_trunc(UInt8, clamp(v, 0, 255)))
end

function parse_rgb_pc(num::SubString{String})
    @inbounds num[end] == '%' || throw_rgb_unification_error()
    v = round(Int, parse_f32(chop1(num)) * 2.55f0)
    return reinterpret(N0f8, unsafe_trunc(UInt8, clamp(v, 0, 255)))
end

function throw_rgb_unification_error()
    throw(ArgumentError("RGB values should be unified in numbers in [0,255] or percentages."))
end

function parse_hue(num::SubString{String})
    vi = tryparse_dec(num)
    vi !== nothing && return Float32(vi)
    mat = match(col_pat_unitful, num)
    if mat !== nothing
        v0, unit0 = mat.captures
        v = parse_f32(v0)
        isempty(unit0) && return v
        unit = lowercase(unit0)
        if unit == "deg"
            return v
        elseif unit == "turn"
            return v * 360f0
        elseif unit == "rad"
            return rad2deg(v)
        elseif unit == "grad"
            return v * 0.9f0
        end
    end
    throw(ArgumentError("invalid hue notation: $num"))
end

function parse_hsl_pc(num::SubString{String})
    if @inbounds num[end] != '%'
        throw(ArgumentError("saturation and lightness must end in %"))
    end
    return clamp(parse_f32(chop1(num)) / 100f0, 0.0f0, 1.0f0)
end

# Parse a number used in the alpha field of "rgba()" and "hsla()".
function parse_alpha(num::SubString{String})
    if @inbounds num[end] == '%'
        v = parse_f32(chop1(num)) / 100f0
    else
        v = parse(Float32, num)
    end
    return clamp(v, 0.0f0, 1.0f0)
end

function _parse_colorant(desc::String)
    n0f8(x) = reinterpret(N0f8, unsafe_trunc(UInt8, x))
    mat = match(col_pat_hex, desc)
    if mat !== nothing
        len = ncodeunits(mat[1])
        digits = parse_hex(mat[1])
        if len == 6
            return convert(RGB{N0f8}, reinterpret(RGB24, digits))
        elseif len == 3
            return RGB(n0f8((digits>>8) & 0xF * 0x11),
                       n0f8((digits>>4) & 0xF * 0x11),
                       n0f8((digits>>0) & 0xF * 0x11))
        elseif len == 8
            if occursin('#', desc)
                return RGBA{N0f8}(n0f8(digits>>24),
                                  n0f8(digits>>16),
                                  n0f8(digits>> 8),
                                  n0f8(digits>> 0))
            else
                return ARGB{N0f8}(n0f8(digits>>16),
                                  n0f8(digits>> 8),
                                  n0f8(digits>> 0),
                                  n0f8(digits>>24))
            end
        elseif len == 4
            if occursin('#', desc)
                return RGBA{N0f8}(n0f8((digits>>12) & 0xF * 0x11),
                                  n0f8((digits>> 8) & 0xF * 0x11),
                                  n0f8((digits>> 4) & 0xF * 0x11),
                                  n0f8((digits>> 0) & 0xF * 0x11))
            else
                return ARGB{N0f8}(n0f8((digits>> 8) & 0xF * 0x11),
                                  n0f8((digits>> 4) & 0xF * 0x11),
                                  n0f8((digits>> 0) & 0xF * 0x11),
                                  n0f8((digits>>12) & 0xF * 0x11))
            end
        end
    end
    mat = match(col_pat_func3, desc)
    if mat !== nothing #&& mat[1] !== nothing && mat[2] !== nothing && mat[3] !== nothing
        if occursin(r"^\s*rgb"i, desc)
            return _parse_colorant_rgb(mat[1], mat[2], mat[3], mat[4])
        else # occursin(r"^\s*hsl"i, desc)
            return _parse_colorant_hsl(mat[1], mat[2], mat[3], mat[4])
        end
    end

    sdesc = strip(desc)
    c = get(color_names, sdesc, nothing)
    c !== nothing && return RGB{N0f8}(n0f8(c[1]), n0f8(c[2]), n0f8(c[3]))

    # since `lowercase` is slightly slow, it is applied only when needed
    ldesc = lowercase(sdesc)
    c = get(color_names, ldesc, nothing)
    c !== nothing && return RGB{N0f8}(n0f8(c[1]), n0f8(c[2]), n0f8(c[3]))

    ldesc == "transparent" && return RGBA{N0f8}(0,0,0,0)

    wo_spaces = replace(ldesc, r"(?<=[^bfptuv ][^p ][adeghk-rtwy]) (?=[^efinq ][aeh-mo-rtuy][^kw \d][a-y]{0,7}\b)" => "")
    c = get(color_names, wo_spaces, nothing)
    if c !== nothing && sizeof(wo_spaces) > 6
        return RGB{N0f8}(n0f8(c[1]), n0f8(c[2]), n0f8(c[3]))
    end

    throw(ArgumentError("Unknown color: $desc"))
end

function _parse_colorant_rgb(p1, p2, p3, alpha)
    if @inbounds p1[end] == '%'
        r, g, b = parse_rgb_pc(p1), parse_rgb_pc(p2), parse_rgb_pc(p3)
    else
        r, g, b = parse_rgb(p1), parse_rgb(p2), parse_rgb(p3)
    end
    if alpha === nothing
        return RGB{N0f8}(r, g, b)
    else
        return RGBA{N0f8}(r, g, b, parse_alpha(alpha) % N0f8)
    end
end

function _parse_colorant_hsl(p1, p2, p3, alpha)
    h, s, l = parse_hue(p1), parse_hsl_pc(p2), parse_hsl_pc(p3)
    if alpha === nothing
        return typeof(HSL(0,0,0))(h, s, l)
    else
        return typeof(HSLA(0,0,0))(h, s, l, parse_alpha(alpha))
    end
end

"""
    parse(Colorant, desc)

Parse a color description.

This parses a subset of HTML/CSS color specifications. In particular, everything
is supported but: `currentColor`.

It does support named colors (though it uses X11 named colors, which are
slightly different than W3C named colors in some cases), `rgb()`, `hsl()`,
`#RGB`, and `#RRGGBB` syntax.

# Arguments

- `Colorant`: literal Colorant
- `desc`: color name or description

A literal Colorant will parse according to the `desc` string (usually returning
an `RGB`); any more specific choice will return a color of the specified type.

# Returns

- an `RGB{N0f8}` color, or

- an `HSL` color if `hsl(h, s, l)` was used

- an `RGBA` color if `rgba(r, g, b, a)` was used

- an `HSLA` color if `hsla(h, s, l, a)` was used

- an `ARGB{N0f8}` color if `0xAARRGGBB`/`0xARGB` was used

- a specific `Colorant` type as specified in the first argument

!!! note "Note for X11 named colors"
    The X11 color names with spaces (e.g. "sea green") are not recommended
    because they are not allowed in the SVG/CSS.

!!! note "Note for hex notations"
    You can parse not only the CSS-style hex notations `#RRGGBB`/`#RGB`, but
    also `0xRRGGBB`/`0xRGB`.

    You can also parse the 8-digit or 4-digit hex notation into an RGB color
    with alpha. However, the result depends on the prefix (i.e. `#` or `0x`).
    ```julia-repl
    julia> parse(Colorant, "#FF8800AA") # transparent orange
    RGBA{N0f8}(1.0,0.533,0.0,0.667)

    julia> parse(Colorant, "0xFF8800AA") # opaque purple
    ARGB{N0f8}(0.533,0.0,0.667,1.0)
    ```
"""
function Base.parse(::Type{C}, desc::AbstractString) where {C<:Colorant}
    c = _parse_colorant(String(desc))
    C === Colorant && return c
    c = convert(C, c)
    return isconcretetype(C) ? c::C : c
end

Base.parse(::Type{C}, desc::Symbol) where {C<:Colorant} = parse(C, string(desc))

@noinline function Base.parse(::Type{C}, c::Colorant) where {C<:Colorant}
    Base.depwarn("""
        `parse(::Type, ::Colorant)` is deprecated.
          Do not call `parse` if the object does not need to be parsed.""", :parse)
    c
end

"""
    @colorant_str(ex)

Parse a literal color name as a Colorant.
See [`Base.parse(Colorant, desc)`](@ref).
"""
macro colorant_str(ex)
    isa(ex, AbstractString) || error("colorant requires literal strings")
    col = parse(Colorant, ex)
    :($col)
end
