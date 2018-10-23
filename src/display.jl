# Displaying color swatches
# -------------------------

const max_width = 180
const max_height = 150
const max_pixel_size = 25

function Base.show(io::IO, ::MIME"image/svg+xml", c::Color)
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="25mm" height="25mm" viewBox="0 0 1 1">
             <rect width="1" height="1"
                   fill="#$(hex(c))" stroke="none"/>
        </svg>
        """)
end

function Base.show(io::IO, ::MIME"image/svg+xml",
                   cs::AbstractVector{T}) where T <: Color
    show(io, MIME"image/svg+xml"(), Base.ReshapedArray(cs, (1, length(cs)), ()))
end

function Base.show(io::IO, ::MIME"image/svg+xml",
                           cs::AbstractMatrix{T}) where T <: Color
    m, n = size(cs)
    apsect_ratio = clamp(n / m,
                         max_pixel_size / max_height,
                         max_width / max_pixel_size)
    pixel_aspect = apsect_ratio / (n / m)
    scale_factor = min(max_width / (n * max_pixel_size * pixel_aspect),
                       max_height / (m * max_pixel_size),
                       1)
    ysize = max_pixel_size * scale_factor
    xsize = ysize * pixel_aspect

    xpad = n > 50 ? 0 : 1
    ypad = m > 28 ? 0 : 1

    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(n*xsize)mm" height="$(m*ysize)mm"
             shape-rendering="crispEdges">
        """)

    for i in 1:m, j in 1:n
        c = ndims(cs) == 2 ? cs[i, j] : cs[j]
        write(io,
            """
            <rect x="$((j-1)*xsize)mm" y="$((i-1)*ysize)mm"
                  width="$(xsize - xpad)mm" height="$(ysize - ypad)mm"
                  fill="#$(hex(c))" stroke="none" />
            """)
    end

    write(io, "</svg>")
end
