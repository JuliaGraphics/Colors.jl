# This file was derived from "docs/src/assets/figures/generate-named-color-charts.jl" (v0.9.6).

module NamedColorCharts

using Colors

struct ColorChartSVG <: Main.SVG
    buf::IOBuffer
end

function ColorChartSVG(colorcategory)
    io = IOBuffer()

    colornames = colordictionary[colorcategory]
    numbercells = length(colornames)
    numbercols = 10
    colwidth = 14.8 #mm
    rowheight = 15 # mm
    swatchheight = 9 # mm
    pagewidth = 150 # mm
    margin = round(pagewidth - colwidth * numbercols) / 2
    numberrows = convert(Int, ceil(numbercells/numbercols))
    headerheight = 15 # mm
    pageheight = headerheight + numberrows * rowheight + margin
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             viewBox="0 0 $pagewidth $pageheight"
             width="$(pagewidth)mm" height="$(pageheight)mm"
             style="width:100%; height:auto;"
             shape-rendering="crispEdges" stroke="none">
        <defs>
            <style><![CDATA[
                @import url('https://fonts.googleapis.com/css?family=IBM+Plex+Sans+Condensed&display=swap');
                g text:last-child {
                    font-size: 2px;
                    fill: #000;
                }
                g text {
                    text-anchor: middle;
                    font-size: 2.5px;
                    font-weight: 500;
                    font-family: 'IBM Plex Sans Condensed', 'Futura Condensed Medium', 'Segoe UI', 'Roboto Condensed', sans-serif;
                    fill: currentColor;
                }
                .header {
                    font-size: 5px;
                    text-anchor: start;
                    font-family: 'Lato', 'Helvetica Neue', 'Arial', sans-serif;
                    font-weight: bold;
                    fill: currentColor;
                }
                .w {
                    fill: #fff !important;
                }
            ]]></style>
        </defs>
        """)
    write(io,
        """
        <text x="$margin" y="10" class="header">$(titlecase(colorcategory))</text>
        <path d="M0,12 h$(pagewidth)" stroke="#888" stroke-width="0.25" />
        """)

    for n = 1:numbercells
        name = colornames[n]
        col = parse(RGB, name)
        x = round(margin + colwidth * ((n - 1) % numbercols), digits=1)
        y = round(headerheight + rowheight * ((n - 1) ÷ numbercols), digits=1)
        cx = round(colwidth / 2, digits=1)

        write(io, """<g transform="translate($x,$y)">""")
        write(io, """<rect y="5" width="$colwidth" height="$swatchheight" fill="#$(hex(col))" />""")
        write(io, "<text>")

        len = length(name)
        if len <= 12
            write(io, """<tspan x="$cx" y="4.2">$name</tspan>""")
        else
            m = match(r"^(dark|pale|light|lemon|medium|blanched|(?:.+(?=white|blue|purple|blush)))(.+)$", name)
            if m != nothing
                write(io, """<tspan x="$cx" y="2.3">$(m.captures[1])</tspan>""")
                write(io, """<tspan x="$cx" y="4.5">$(m.captures[2])</tspan>""")
            else
                write(io, """<tspan x="$cx" y="2.3">$(name[1:(len÷2)])</tspan>""")
                write(io, """<tspan x="$cx" y="4.5">$(name[(len÷2+1):end])</tspan>""")
            end
        end
        write(io, "</text>")

        vec = string(round(red(col), digits=2), ", ",
                     round(green(col), digits=2), ", ",
                     round(blue(col), digits=2))
        veccol = convert(Lab, col).l > 60 ? "" : " class=\"w\""
        write(io, """<text x="$cx" y="13"$veccol>$vec</text>""")
        write(io, "</g>\n")
    end

    write(io, "</svg>")
    ColorChartSVG(io)
end

function compare_colors(colorname_a, colorname_b)
    # compare two colors, looking just at their LUV luminance values
    luv1 = parse(Luv, colorname_a)
    luv2 = parse(Luv, colorname_b)
    luv1.l == luv2.l ? colorname_a < colorname_b : luv1.l > luv2.l
end

# sort colors into categories
# these are very bikesheddable
function classifycolornames(colornames)
    colorcategories = Dict{String, Array{String, 1}}(
        "whites" => [],
        "pinks" => [],
        "reds" => [],
        "oranges" => [],
        "yellows" => [],
        "greens" => [],
        "cyans" => [],
        "blues" => [],
        "purples" => [],
        "browns" => [],
        "grays" => [])
    for colorname in colornames
        if occursin(r"(^grey)|(^gray)", colorname)
            push!(colorcategories["grays"], colorname)
        elseif occursin(r"turquoise|^aqua$|teal|cyan", colorname)
            push!(colorcategories["cyans"], colorname)
        elseif occursin(r"lemon|khaki|wheat", colorname)
            push!(colorcategories["yellows"], colorname)
        elseif occursin(r"orange", colorname)
            push!(colorcategories["oranges"], colorname)
        elseif occursin(r"chartreuse|olive|marine|lime|green", colorname)
            push!(colorcategories["greens"], colorname)
        elseif occursin(r"maroon|violetred|pink", colorname)
            push!(colorcategories["pinks"], colorname)
        elseif occursin(r"mistyrose|plum|thistle|lavender|violet|orchid|magenta|fuchsia|purple", colorname)
            push!(colorcategories["purples"], colorname)
        elseif occursin(r"azure|gains|slate|navy|indigo|blue", colorname)
            push!(colorcategories["blues"], colorname)
        elseif occursin(r"gold|yellow", colorname)
            push!(colorcategories["yellows"], colorname)
        elseif occursin(r"chocolate|sienna|wood|moccasin|bisque|peru|peach|papaya|almond|tan|brown", colorname)
            push!(colorcategories["browns"], colorname)
        elseif occursin(r"crimson|firebrick|salmon|coral|tomato|red", colorname)
            push!(colorcategories["reds"], colorname)
        elseif occursin(r"honey|mint|beige|linen|corn|sea|silver|lace|ivory|snow|white", colorname)
            push!(colorcategories["whites"], colorname)
        elseif occursin(r"grey|gray|black", colorname)
            push!(colorcategories["grays"], colorname)
        else
            error(colorname)
        end
    end
    # sort the RGB values in Luv.l format
    # TODO perhaps do this conversion just once instead of 1000s of times :)
    for k in keys(colorcategories)
        vals = colorcategories[k]
        sort!(vals, lt = compare_colors)
        colorcategories[k] = vals
    end
    return colorcategories
end

function makecolordictionary()
    colornames = collect(keys(Colors.color_names))
    colordictionary = classifycolornames(colornames)
    checkclassified = String[]
    for category in keys(colordictionary)
        for c in colordictionary[category]
            push!(checkclassified, c)
        end
    end
    stilltodo = setdiff(colornames, checkclassified)
    length(stilltodo) > 0 && error("gotta catch them all!")
    return colordictionary
end

const colordictionary = makecolordictionary()

end
