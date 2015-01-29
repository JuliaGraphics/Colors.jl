using Color
using Color, ColorBrewer

function out_image(name, color_list)
  total_width = 12.
  elt_width = total_width/length(color_list)
  elt_height = 0.5
  width, height = "$(elt_width)cm", "0.5cm"
  path = "$git_path/images"
  svg_filename = "$path/$name.svg"
  png_filename = "$path/$name.png"
  f = open(svg_filename, "w")
  @printf f "%s\n" "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"$(total_width)cm\" height=\"$height\">"
  for (x, color) in zip(0:length(color_list), color_list)
    r = int(round(color.r*255))
    g = int(round(color.g*255))
    b = int(round(color.b*255))
    position = "x=\"$(x*elt_width)cm\" width=\"$width\" height=\"$height\""
    fill = "fill=\"rgb($r, $g, $b)\""
    stroke = "stroke=\"rgb($r, $g, $b)\""
    print(f, "<rect $position $fill $stroke/>\n")
  end
  @printf f "</svg>"
  close(f)
  run(`svg2png $svg_filename $png_filename`)
  run(`rm $svg_filename`)
end

function main()
  for name in ["Blues", "Greens", "Grays", "Oranges", "Purples", "Reds", "RdBu"]
    try
      out_image(name, colormap(name, 32))
    catch ex
      @printf "Colormap %s failed: %s\n" name ex
    end
  end
end

nothing
