# Displaying color swatches
# -------------------------

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

function Base.show{T <: Color}(io::IO, ::MIME"image/svg+xml",
                                       cs::AbstractVecOrMat{T})
    m,n = ndims(cs) == 2 ? size(cs) : (1,length(cs))

    xsize,xpad = n > 50 ? (250/n,0) : n > 18 ? (5.,1) : n > 12 ? (10.,1) : n > 1 ? (15.,1) : (25.,0)
    ysize,ypad = m > 28 ? (150/m,0) : m > 14 ? (5.,1) : m > 9 ? (10.,1) : m > 1 ? (15.,1) : (25.,0)

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
