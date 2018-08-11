using Colors, Luxor

function compare_colors(color_a, color_b)
    # compare two colors, looking just at their LUV luminance values
    luv1 = convert(Luv, RGB(color_a[1]/255, color_a[2]/255, color_a[3]/255))
    luv2 = convert(Luv, RGB(color_b[1]/255, color_b[2]/255, color_b[3]/255))
    luv1.l > luv2.l
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
        "greens" => ["lime"],
        "cyans" => [],
        "blues" => ["navy", "indigo", "teal"],
        "purples" => ["fuchsia"],
        "browns" => [],
        "grays" => ["black", "dimgrey", "lightgrey", "darkgrey"])
    for colorname in colornames
        if occursin(r"(^grey)|(^gray)", colorname)
            push!(colorcategories["grays"], colorname)
        elseif occursin(r"turquoise|azure|gains|blue|slate", colorname)
            push!(colorcategories["blues"], colorname)
        elseif occursin(r"lemon|khaki|wheat", colorname)
            push!(colorcategories["yellows"], colorname)
        elseif occursin(r"chartreuse|olive|aqua|green", colorname)
            push!(colorcategories["greens"], colorname)
        elseif occursin(r"mistyrose|plum|thistle|lavender|maroon|violet|orchid|magenta|maroon", colorname)
            push!(colorcategories["purples"], colorname)
        elseif occursin(r".*gold.*", colorname)
            push!(colorcategories["yellows"], colorname)
        elseif occursin(r"chocolate|sienna|wood|moccasin|bisque|peru|peach|papaya|almond|tan", colorname)
            push!(colorcategories["browns"], colorname)
        elseif occursin(r"crimson|firebrick|salmon|coral|tomato", colorname)
            push!(colorcategories["reds"], colorname)
        elseif occursin(r"honey|mint|beige|linen|corn|sea|silver|lace|ivory|snow|white", colorname)
            push!(colorcategories["whites"], colorname)
        else
            # some colors obviously belong to categories
            # ie "deeppink" is in "pinks"
            for k in keys(colorcategories)
                if occursin(replace(k, "s" => ""), colorname)
                    push!(colorcategories[k], colorname)
                end
            end
        end
    end
    # sort the RGB values in Luv.l format
    # TODO perhaps do this conversion just once instead of 1000s of times :)
    for k in keys(colorcategories)
        vals = colorcategories[k]
        sort!(vals, lt = (color1, color2) ->
            compare_colors(Colors.color_names[color1] ./ 255,
                Colors.color_names[color2] ./ 255))
        colorcategories[k] = unique(vals)
    end
    return colorcategories
end

"""
find a readable color for text placed on top of another color
"""
function inversecolor(foregroundcolor, backgroundcolor;
        tolerance = 20)
    foreground = foregroundcolor
    if colordiff(parse(Colorant, foreground), parse(Colorant, backgroundcolor)) < tolerance
        tempcolor = parse(Colorant, backgroundcolor)
        clab = convert(Lab, parse(Colorant, tempcolor))
        if clab.l > 50
            labelbrightness = 0
        else
            labelbrightness = 100
        end
        foreground = convert(RGB, Lab(labelbrightness, clab.b, clab.a))
    end
    return foreground
end

function main()
    colornames = collect(keys(Colors.color_names))
    colordictionary = classifycolornames(colornames)
    categoryorder = ["whites", "yellows", "greens", "cyans", "blues", "purples", "pinks", "reds", "oranges",  "browns", "grays"]
    checkclassified = String[]
    for category in categoryorder
        for c in colordictionary[category]
            push!(checkclassified, c)
        end
    end
    stilltodo = setdiff(colornames, checkclassified)
    length(stilltodo) > 0 && (@show stilltodo; @warn "gotta catch them all!")
    for colorcategory in categoryorder
        numbercells = length(keys(colordictionary[colorcategory]))
        numbercols = 10
        colwidth = 150
        rowheight = 100
        pagewidth = 800
        margin = 15
        numberrows = convert(Int, ceil(numbercells/numbercols) + 1)
        Drawing(pagewidth - margin, margin + (numberrows * rowheight),
            "/tmp/namedcolorchart-$(colorcategory).svg")
        origin()
        background("white")
        setcolor("black")
        fontsize(24)
        fontface("Helvetica-Bold")
        text(titlecase(colorcategory), BoundingBox()[1] + (margin, 30), halign=:left)
        setline(0.5)
        line(Point(-pagewidth/2 + margin, 40 + -currentdrawing.height/2), Point(pagewidth/2 - margin, 40 + -currentdrawing.height/2), :stroke)
        table = Table(numberrows, numbercols,
            (pagewidth - 2margin)/numbercols, # cell width
            rowheight, # row height
            O + (0, 3margin) # initial center position
            )
        pts = first.(collect(table))
        n = 1
        for col in colordictionary[colorcategory]
            backgroundcolor = Colors.RGB(Colors.color_names[col] ./ 255 ...)
            setcolor(backgroundcolor)
            # draw swatch
            box(pts[n], table.colwidths[1], table.rowheights[1]/2, :fill)
            # if overlapping text on swatch, choose color wisely
            # sethue(inversecolor("white", backgroundcolor, tolerance=60))
            sethue("black")
            fontface("DINNextLTPro-BoldCondensed")
            fontsize(12)
            text(col, pts[n] + (0, -table.rowheights[1]/3), halign=:center)
            fontsize(9)
            fontface("InputMonoCompressed-Regular")
            text(string(round(backgroundcolor.r, digits=2), " ",
                        round(backgroundcolor.g, digits=2), " ",
                        round(backgroundcolor.b, digits=2)),
                        pts[n] + (0, table.rowheights[1]/3), halign=:center)
            n += 1
        end
        finish()
    end
    return colordictionary
end

main()
