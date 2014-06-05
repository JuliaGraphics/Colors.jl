# Displaying color swatches
# -------------------------

function writemime(io::IO, ::MIME"image/svg+xml", c::ColorValue)
    write(io,
        """
        <?xml version"1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="25mm" height="25mm" viewBox="0 0 1 1">
             <rect width="1" height="1"
                   fill="#$(hex(c))" stroke="none"/>
        </svg>
        """)
end


function writemime{T <: ColorValue}(io::IO, ::MIME"image/svg+xml",
                                    cs::AbstractVector{T})
    n = length(cs)
    if n > 18
        swatch_size = 5
    elseif n > 12
        swatch_size = 10
    else
        swatch_size = 15
    end

    pad = 1
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(n*swatch_size)mm" height="25mm"
             shape-rendering="crispEdges">
        """)

    for (i, c) in enumerate(cs)
        write(io,
            """
            <rect x="$((i-1)*swatch_size)mm" width="$(swatch_size - pad)mm" height="100%"
                  fill="#$(hex(c))" stroke="none" />
            """)
    end

    write(io, "</svg>")
end


function writemime{T <: ColorValue}(io::IO, ::MIME"image/svg+xml",
                                    cs::AbstractMatrix{T})
    m, n = size(cs)

    if n > 18
        swatch_size = 5
    elseif n > 12
        swatch_size = 10
    else
        swatch_size = 15
    end

    pad = 1
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(n*swatch_size)mm" height="$(m*swatch_size)mm"
             shape-rendering="crispEdges">
        """)

    for i in 1:m, j in 1:n
        c = cs[i, j]
        write(io,
            """
            <rect x="$((j-1)*swatch_size)mm" y="$((i-1)*swatch_size)mm"
                  width="$(swatch_size - pad)mm" height="$(swatch_size - pad)mm"
                  fill="#$(hex(c))" stroke="none" />
            """)
    end

    write(io, "</svg>")
end

