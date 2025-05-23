
module SampleImages

using Colors
using Base64
using WebP

struct BeadsImageSVG <: Main.SVG
    buf::IOBuffer
end

const beads = WebP.read_webp(joinpath(@__DIR__, "src", "assets", "figures", "beads.webp"))

# The following code is ad-hoc and highly depends on "beads.svg".
# Be careful when modifying the svg file or its code.
function BeadsImageSVG(caption::String; filter=nothing, width="64mm", height="36mm")
    io = IOBuffer()

    write(io, """<svg version="1.1" viewBox="0 0 1920 1080" """)
    write(io, """xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" """)
    write(io, """width="$width" height="$height" image-rendering="optimizeQuality" """)
    write(io, """style="display:inline; margin-left:1em; margin-bottom:1em">\n""")

    img = filter === nothing ? beads : filter.(beads)
    webp = WebP.encode(img, lossy=true, quality=85)

    write(io, """<image width="1920" height="1080" xlink:href="data:image/webp;base64,""")

    b64enc = Base64EncodePipe(io)
    write(b64enc, webp)
    close(b64enc)

    write(io, """" />\n""")

    for style in ("fill:white;stroke:white;stroke-width:20;opacity:0.2", "fill:black;opacity:0.9")
        write(io,"""<text x="16" y="1000" style="$style;font-size:80px;">$caption</text>\n""")
    end

    write(io, """</svg>\n""")

    BeadsImageSVG(io)
end

end
