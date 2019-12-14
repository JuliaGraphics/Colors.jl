# This file is the successor to "images/GenerateImages.jl" (v0.5.1).
module Colormaps

using Colors

struct ColormapSVG <: Main.SVG
    buf::IOBuffer
end

function ColormapSVG(cm::AbstractVector{T}, w="96mm", h="4mm") where T<:Color
    io = IOBuffer()
    n = length(cm)
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$w" height="$h"
             viewBox="0 0 $n 1" preserveAspectRatio="none"
             shape-rendering="crispEdges" stroke="none">
        """)
    for i in 1:n
        c = hex(cm[i])
        write(io,
            """
            <rect width="$(n+1-i)" height="1" x="$(i-1)" y="0" fill="#$c" />
            """)
    end
    write(io, "</svg>")
    ColormapSVG(io)
end

end
