# Helper data for color parsing
include("names_data.jl")


# Color Parsing
# -------------

const col_pat_hex  = r"^\s*(#|0x)([[:xdigit:]]{3,8})\s*$"
const col_pat_rgb  = r"^\s*rgb\(\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*\)\s*$"
const col_pat_hsl  = r"^\s*hsl\(\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*\)\s*$"
const col_pat_rgba = r"^\s*rgba?\(\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,/]\s*((?:\d+|(?=\.\d))(?:\.\d*)?%?)\s*\)\s*$"
const col_pat_hsla = r"^\s*hsla?\(\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,\s]\s*(\d+%?)\s*[,/]\s*((?:\d+|(?=\.\d))(?:\.\d*)?%?)\s*\)\s*$"

chop1(x) = SubString(x, 1, lastindex(x) - 1) # `chop` is slightly slow

# Parse a number used in the "rgb()" or "hsl()" color.
function parse_rgb(num::AbstractString)
    if num[end] == '%'
        return N0f8(clamp(parse(Int, chop1(num), base=10) / 100, 0, 1))
    else
        return reinterpret(N0f8, UInt8(clamp(parse(Int, num, base=10), 0, 255)))
    end
end

function parse_hsl_hue(num::AbstractString)
    if num[end] == '%'
        error("hue cannot end in %")
    else
        return parse(Int, num, base=10)
    end
end

function parse_hsl_sl(num::AbstractString)
    if num[end] != '%'
        error("saturation and lightness must end in %")
    else
        return parse(Int, chop1(num), base=10) / 100
    end
end

# Parse a number used in the alpha field of "rgba()" and "hsla()".
function parse_alpha_num(num::AbstractString)
    if num[end] == '%'
        return parse(Int, chop1(num), base=10) / 100f0
    else
        # `parse(Float32, num)` is somewhat slow on Windows(x86_64-w64-mingw32).
        # However, the following has the opposite effect on Linux.
        # m = match(r"0?\.(\d{1,9})", num)
        # if m != nothing
        #     d = m.captures[1]
        #     return parse(Int, d, base=10) / Float32(exp10(length(d)))
        # end
        return parse(Float32, num)
    end
end

function _parse_colorant(desc::AbstractString)
    mat = match(col_pat_hex, desc)
    if mat != nothing
        prefix = mat.captures[1]
        len = length(mat.captures[2])
        digits = parse(UInt32, mat.captures[2], base=16)
        if len == 6
            return convert(RGB{N0f8}, reinterpret(RGB24, digits))
        elseif len == 3
            return RGB{N0f8}(reinterpret(N0f8, UInt8(((digits&0xF00)>>8) * 17)),
                             reinterpret(N0f8, UInt8(((digits&0x0F0)>>4) * 17)),
                             reinterpret(N0f8, UInt8(((digits&0x00F))    * 17)))
        elseif len == 8 || len == 4
            error("8-digit and 4-digit hex notations are not supported yet.")
        end
    end
    mat = match(col_pat_rgb, desc)
    if mat != nothing
        return RGB{N0f8}(parse_rgb(mat.captures[1]),
                         parse_rgb(mat.captures[2]),
                         parse_rgb(mat.captures[3]))
    end

    mat = match(col_pat_hsl, desc)
    if mat != nothing
        T = ColorTypes.eltype_default(HSL)
        return HSL{T}(parse_hsl_hue(mat.captures[1]),
                      parse_hsl_sl(mat.captures[2]),
                      parse_hsl_sl(mat.captures[3]))
    end

    mat = match(col_pat_rgba, desc)
    if mat != nothing
        return RGBA{N0f8}(parse_rgb(mat.captures[1]),
                          parse_rgb(mat.captures[2]),
                          parse_rgb(mat.captures[3]),
                          parse_alpha_num(mat.captures[4]))
    end

    mat = match(col_pat_hsla, desc)
    if mat != nothing
        T = ColorTypes.eltype_default(HSLA)
        return HSLA{T}(parse_hsl_hue(mat.captures[1]),
                       parse_hsl_sl(mat.captures[2]),
                       parse_hsl_sl(mat.captures[3]),
                       parse_alpha_num(mat.captures[4]))
    end

    sdesc = strip(desc)
    c = get(color_names, sdesc, nothing)
    if c != nothing
        return RGB{N0f8}(reinterpret(N0f8, UInt8(c[1])),
                         reinterpret(N0f8, UInt8(c[2])),
                         reinterpret(N0f8, UInt8(c[3])))
    end
    # since `lowercase` is slightly slow, it is applied only when needed
    ldesc = lowercase(sdesc)
    c = get(color_names, ldesc, nothing)
    if c != nothing
        return RGB{N0f8}(reinterpret(N0f8, UInt8(c[1])),
                         reinterpret(N0f8, UInt8(c[2])),
                         reinterpret(N0f8, UInt8(c[3])))
    end

    if ldesc == "transparent"
        return RGBA{N0f8}(0,0,0,0)
    end

    wo_spaces = replace(ldesc, r"(?<=[^ ]{3}) (?=[^ ]{3})" => "")
    c = get(color_names, wo_spaces, nothing)
    if c != nothing
        camel = replace(titlecase(ldesc), " " => "")
        Base.depwarn(
            """
            The X11 color names with spaces are not recommended because they are not allowed in the SVG/CSS.
            Use "$camel" or "$wo_spaces" instead.
            """, :parse)
        return RGB{N0f8}(reinterpret(N0f8, UInt8(c[1])),
                         reinterpret(N0f8, UInt8(c[2])),
                         reinterpret(N0f8, UInt8(c[3])))
    end

    error("Unknown color: ", desc)
end

# note: these exist to enable proper dispatch, since super(Colorant) == Any
_parse_colorant(::Type{C}, ::Type{SUP}, desc::AbstractString) where {C<:Colorant,SUP<:Any} = _parse_colorant(desc)
_parse_colorant(::Type{C}, ::Type{SUP}, desc::AbstractString) where {C<:Colorant,SUP<:Colorant} = convert(C, _parse_colorant(desc))::C

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

A literal Colorant will parse according to the `desc` string (usually returning an `RGB`); any more specific choice will return a color of the specified type.

# Returns

- an `RGB{N0f8}` color, or

- an `HSL` color if `hsl(h, s, l)` was used

- an `RGBA` color if `rgba(r, g, b, a)` was used

- an `HSLA` color if `hsla(h, s, l, a)` was used

- a specific `Colorant` type as specified in the first argument

!!! note
    The X11 color names with spaces (e.g. "sea green") are not recommended
    because they are not allowed in the SVG/CSS.
"""
Base.parse(::Type{C}, desc::AbstractString) where {C<:Colorant} = _parse_colorant(C, supertype(C), desc)
Base.parse(::Type{C}, desc::Symbol) where {C<:Colorant} = parse(C, string(desc))
Base.parse(::Type{C}, c::Colorant) where {C<:Colorant} = c

"""
    @colorant_str(ex)

Parse a literal color name as a Colorant.
"""
macro colorant_str(ex)
    isa(ex, AbstractString) || error("colorant requires literal strings")
    col = parse(Colorant, ex)
    :($col)
end

@noinline function ColorTypes.color(str::AbstractString)
    Base.depwarn("color(\"$str\") is deprecated, use colorant\"$str\" or parse(Colorant, \"$str\")", :color)
    parse(Colorant, str)
end
