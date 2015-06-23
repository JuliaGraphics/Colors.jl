#!/Applications/Julia-0.3.9.app/Contents/Resources/julia/bin/julia

using Color

function compare_colors(color_a, color_b)
    # compare two colors, looking just at their LUV luminance values
    rx, gx, bx = color_a
    ry, gy, by = color_b
    hslx = convert(LUV, RGB(rx, gx, bx))
    hsly = convert(LUV, RGB(ry, gy, by))
    hslx.l > hsly.l
end

function draw_swatch(colorname, x, y, swatchwidth, swatchheight, color_values)
    r, g, b = color_values
    toplabel = """<text x="$(x)" y="$(y - 3)" fill="black" font-size="5px" font-family="Helvetica-Bold">$colorname</text>\n"""
    bottomlabel = """<text x="$(x)" y="$(y + swatchheight + 3)" font-size="3px" font-family="Helvetica">($r, $g, $b)</text>\n"""
    return  toplabel *
            bottomlabel *
            """<rect rx="2" ry="2" x="$(x)" y="$(y)" width="$(swatchwidth)" height="$(swatchheight)" fill="rgb($r, $g, $b)" /> \n """
end

function make_color_table(image_width, image_height, output_file)
    colordict = Color.color_names
    sorted_colors = sort(collect(keys(colordict)), by = x -> colordict[x], lt = (x,y) -> compare_colors(x,y))
    # calculate sizes of swatches
    aspect = image_width/image_height
    if aspect > 1
        n_rows = ceil(sqrt(length(sorted_colors)/aspect))
    else
        n_rows = ceil(sqrt(length(sorted_colors) * aspect))
    end
    n_cols = ceil(length(sorted_colors)/n_rows)

    margin = 25
    row_space = 15
    col_space = 15

    swatchwidth  = ((image_width  - margin - margin - (col_space * n_cols )) / n_cols)
    swatchheight = ((image_height - margin - margin - (row_space * n_rows )) / n_rows)

    # send output to file
    f = open(output_file, "w")

    # write svg header
    println(f, """<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="$(image_width)" height="$(image_height)"> \n
    <rect x="0" y="0" width="$(image_width)" height="$(image_height)" fill="white" /> \n
    """)

    # title
    println(f, """<text x="$(margin)" y="$(margin - margin/2)" font-size="14px" font-family="Helvetica-Bold">Color names in Color.jl, sorted by luminance</text>\n""")

    # x and y track position
    x = margin
    y = margin

    for colorname in sorted_colors
        color_values = colordict[colorname] # eg (255, 255, 255)
        print(f, draw_swatch(colorname, x, y, swatchwidth, swatchheight, color_values))
        if x > (image_width - swatchwidth - margin - margin)
            x = margin # next row
            y += swatchheight + row_space # gap between rows
        else
            x += swatchwidth + col_space  # gap between columns
        end
    end

    @printf f "</svg>"
    close(f)
end

make_color_table(1400, 1400, "/tmp/color_names_sorted.svg")
