# Helper data for color parsing
include("names_data.jl")


# Color Parsing
# -------------

const col_pat_hex1 = r"(#|0x)([[:xdigit:]])([[:xdigit:]])([[:xdigit:]])"
const col_pat_hex2 = r"(#|0x)([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})"
const col_pat_rgb  = r"rgb\((\d+%?),(\d+%?),(\d+%?)\)"
const col_pat_hsl  = r"hsl\((\d+%?),(\d+%?),(\d+%?)\)"
const col_pat_rgba = r"rgba\((\d+%?),(\d+%?),(\d+%?),(\d+(?:\.\d*)?%?)\)"
const col_pat_hsla = r"hsla\((\d+%?),(\d+%?),(\d+%?),(\d+(?:\.\d*)?%?)\)"

# Parse a number used in the "rgb()" or "hsl()" color.
function parse_rgb_hsl_num(num::String)
    if num[end] == '%'
        return parseint(num[1:end-1], 10) / 100
    else
        return parseint(num, 10) / 255
    end
end

# Parse a number used in the alpha field of "rgba()" and "hsla()".
function parse_alpha_num(num::String)
    if num[end] == '%'
        return parsefloat(num[1:end-1]) / 100
    else
        return parsefloat(num)
    end
end


# Parse a color description.
#
# This parses subset of HTML/CSS color specifications. In particular, everything
# is supported but: "currentColor".
#
# It does support named colors (though it uses X11 named colors, which are
# slightly different than W3C named colors in some cases), "rgb()", "hsl()",
# "#RGB", and "#RRGGBB' syntax.
#
# Args:
#   desc: A color name or description.
#
# Returns:
#   An RGB color, unless "hsl()" was used, in which case an HSL color.
#
function color(desc::String)
    desc_ = replace(desc, " ", "")
    mat = match(col_pat_hex2, desc_)
    if mat != nothing
        return RGB(parseint(mat.captures[2], 16) / 255,
                   parseint(mat.captures[3], 16) / 255,
                   parseint(mat.captures[4], 16) / 255)
    end

    mat = match(col_pat_hex1, desc_)
    if mat != nothing
        return RGB((16 * parseint(mat.captures[2], 16)) / 255,
                   (16 * parseint(mat.captures[3], 16)) / 255,
                   (16 * parseint(mat.captures[4], 16)) / 255)
    end

    mat = match(col_pat_rgb, desc_)
    if mat != nothing
        return RGB(parse_rgb_hsl_num(mat.captures[1]),
                   parse_rgb_hsl_num(mat.captures[2]),
                   parse_rgb_hsl_num(mat.captures[3]))
    end

    mat = match(col_pat_hsl, desc_)
    if mat != nothing
        return HSL(parse_rgb_hsl_num(mat.captures[1]),
                   parse_rgb_hsl_num(mat.captures[2]),
                   parse_rgb_hsl_num(mat.captures[3]))
    end

    mat = match(col_pat_rgba, desc_)
    if mat != nothing
        return RGBA(parse_rgb_hsl_num(mat.captures[1]),
                    parse_rgb_hsl_num(mat.captures[2]),
                    parse_rgb_hsl_num(mat.captures[3]),
                    parse_alpha_num(mat.captures[4]))
    end

    mat = match(col_pat_hsla, desc_)
    if mat != nothing
        return HSLA(parse_rgb_hsl_num(mat.captures[1]),
                    parse_rgb_hsl_num(mat.captures[2]),
                    parse_rgb_hsl_num(mat.captures[3]),
                    parse_alpha_num(mat.captures[4]))
    end


    desc_ = lowercase(desc_)

    if desc_ == "transparent"
        return RGBA(0.0, 0.0, 0.0, 0.0)
    end

    if !haskey(color_names, desc_)
        error("Unknown color: ", desc)
    end

    c = color_names[desc_]
    return RGB(c[1] / 255, c[2] / 255, c[3] / 255)
end

color(c::ColorValue) = c

