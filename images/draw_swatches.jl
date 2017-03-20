using Colors

function compare_colors(color_a, color_b)
    # compare two colors, looking just at their LUV luminance values
    luv1 = convert(Luv, RGB(color_a[1]/255, color_a[2]/255, color_a[3]/255))
    luv2 = convert(Luv, RGB(color_b[1]/255, color_b[2]/255, color_b[3]/255))
    luv1.l > luv2.l
end

function draw_swatch(colorname, x, y, swatchwidth, swatchheight, color_values)
    r, g, b = color_values
    toplabel = """<text x="$(x)" y="$(y - 3)" fill="black" font-size="5px" font-family="Helvetica-Bold">$colorname</text>\n"""
    bottomlabel = """<text x="$(x)" y="$(y + swatchheight + 3)" font-size="3px" font-family="Helvetica">($r, $g, $b)</text>\n"""
    return  toplabel *
    bottomlabel *
    """<rect rx="2" ry="2" x="$(x)" y="$(y)" width="$(swatchwidth)" height="$(swatchheight)" fill="rgb($r, $g, $b)" /> \n """
end

function draw_synonym(colorname, x, y, swatchwidth, swatchheight)
    # add a synonym below the swatch
    return """<text x="$(x)" y="$(y + swatchheight + 3)" fill="black" font-size="3px" font-family="Helvetica-Bold">$colorname</text>\n"""
end

function make_color_table(image_width, image_height, output_file)
    # prepare synonym lists
    synonyms = Dict{Tuple, Array}()
    for color in Colors.color_names
        col_name  = color[1]
        col_value = color[2]
        if haskey(synonyms, col_value)
            push!(synonyms[col_value], col_name)
        else
            synonyms[col_value] = [col_name]
        end
    end

    # calculate sizes of swatches
    aspect = image_width/image_height
    if aspect > 1
        n_rows = ceil(sqrt(length(synonyms)/aspect))
    else
        n_rows = ceil(sqrt(length(synonyms) * aspect))
    end
    n_cols = ceil(length(synonyms)/n_rows)

    margin = 30
    row_space = 25
    col_space = 15

    swatchwidth  = ((image_width  - margin - margin - (col_space * n_cols )) / n_cols)
    swatchheight = ((image_height - margin - margin - (row_space * n_rows )) / n_rows)

    # send output to file
    f = open(output_file, "w")

    # write svg header
    println(f, """<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="$(image_width)" height="$(image_height)"> \n
    <rect x="0" y="0" width="$(image_width)" height="$(image_height)" fill="white" /> \n """)

    # title
    println(f, """<text x="$(margin)" y="$(margin - margin/2)" font-size="14px" font-family="Helvetica-Bold">Color names in Colors.jl, sorted by luminance</text>\n""")

    # x and y track position
    x = margin
    y = margin

    for color_values in sort(collect(keys(synonyms)), lt = (x,y) -> compare_colors(x,y))
        color_synonyms = sort(synonyms[color_values])
        print(f, draw_swatch(color_synonyms[1], x, y, swatchwidth, swatchheight, color_values))
        oldy = y # save the current position during excursion
        for synonym in color_synonyms[2:end]
            # draw the other names for this color
            y += 3
            print(f, draw_synonym(string("also: " * synonym), x, y, swatchwidth, swatchheight))
        end
        y = oldy
        if x > (image_width - swatchwidth - margin - margin)
            x = margin # next row
            y += swatchheight + row_space # gap between rows
        else
            x += swatchwidth + col_space  # gap between columns
        end
    end
    println(f, "</svg>")
    close(f)
end


make_color_table(1400, 1400, "/tmp/color_names_sorted.svg")
