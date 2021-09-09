module ColormapParams

using Colors
using Main.PNG16x16

struct ColormapParamSVG <: Main.SVG
    buf::IOBuffer
end

function ColormapParamSVG(target::Symbol)
    io = IOBuffer()
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             version="1.1"
             width="45mm" height="45mm"
             viewBox="0 0 270 270" preserveAspectRatio="none"
             shape-rendering="crispEdges" stroke="none" stroke-width="1">
        """)
    write(io,
        """
        <rect width="270" height="270" fill="#aaa" opacity="0.2" />
        """)
    if target in (:c, :s, :b)
        write_chart_csb(io, target)
    elseif target in (:w, :d)
        write_chart_wd(io, target)
    end
    write(io, "</svg>")
    ColormapParamSVG(io)
end

function write_chart_csb(io, target::Symbol)
    pp = (0.1, 0.5, 0.9)
    pc = map(_ -> 0.88, pp)
    ps = map(_ -> 0.60, pp)
    pb = map(_ -> 0.75, pp)
    markers = ("m -5,-5 v 10 h 10 v -10 z",
               "m 0,-5 l -5,9 h 10 z",
               "m 0,-4 l -4,4 4,4 4,-4 z")
    if target === :c
        col = Colors.JULIA_LOGO_COLORS.purple
        label = "contrast"
        pc = pp
    elseif target === :s
        col = Colors.JULIA_LOGO_COLORS.red
        label = "saturation"
        ps = pp
    elseif target === :b
        col = Colors.JULIA_LOGO_COLORS.green
        label = "brightness"
        pb = pp
    end
    h = round(Int, hue(convert(Luv, col)))
    n = 16
    ls = (100/2/n):(100/n):100
    cs = (175/2/n):(175/n):175
    mc(l) = Colors.find_maximum_chroma(LCHuv(l, 0.0, h))
    plane = [LCHuv(100.0 - l, min(c, mc(l)), h) for l in ls, c in cs]
    write(io,
        """
        <g transform="translate(80, 20)" fill="none" stroke-width="1.5"
           style="font-size: 18px; font-style: italic;">
            <image width="100" height="100" transform="scale(1.75, 2)" xlink:href=\"""")
    write_png_as_data(io, plane)
    write(io, "\" />\n")
    mc_coords = join(string(round(Int, mc(100 - l)), ",", 2l, " ") for l = 0:2:100)
    write(io,
        """
            <path d="m 175,0 L $mc_coords 175,200 z" fill="#aaa" />
            <path d="m 0,200 v -215 l 5,10 m -10,0 l 5,-10" stroke="currentColor" />
            <path d="m 0,200 h  185 l -10,5 m 0,-10 l 10,5" stroke="currentColor" />
            <text fill="currentColor" x="150" y="220">C*</text>
            <text fill="currentColor" x="-25" y="10" >L*</text>
        """)
    write(io, "</g>")
    for i = 1:3
        colors= sequential_palette(h, 7, c=pc[i], s=ps[i], b=pb[i], w=0, d=0)
        write_colormap(io, 25 * i - 20, pp[i], colors, markers[i])
    end
    tcolors = (sequential_palette(h, 25, c=pc[i], s=ps[i], b=pb[i], w=0, d=0) for i = 1:3)
    write_stroke(io, tcolors, markers)
    write(io,
        """
        <text fill="currentColor" y="260" style="font-size: 18px;">
            <tspan x="70" style="font-style: italic;">$target</tspan>
            <tspan x="90">- $label [0,1]</tspan>
        </text>
        """)
end

function write_chart_wd(io, target::Symbol)
    pp = 0.0:0.2:1.0
    pw = map(_ -> 0.15, pp)
    pd = map(_ -> 0.0, pp)

    if target === :w
        col = Colors.JULIA_LOGO_COLORS.blue
        cy = 40
        pw = pp
        kcol = "#ff0"
    elseif target === :d
        col = Colors.JULIA_LOGO_COLORS.green
        cy = 200
        pd = pp
        kcol = "#00f"
    end
    h = round(Int, hue(convert(Luv, col)))
    for i in eachindex(pp)
        colors = sequential_palette(h, 9, w=pw[i], d=pd[i])
        write_colormap(io, 30 * i - 10, pp[i], colors)
    end
    write(io,
        """
        <rect x="205" y="$cy" width="20" height="20" fill="$kcol" />
        """)
    write(io,
        """
        <text fill="currentColor" y="260" style="font-size: 18px;">
            <tspan x="20" style="font-style: italic;">$target</tspan>
            <tspan x="40">- strength of $(target)color [0,1]</tspan>
            <tspan x="195" y="$(cy-5)" style="font-style: italic;">$(target)color</tspan>
        </text>
        """)
end

function write_colormap(io, x, p, colors, marker="")
    y = 0
    write(io,
        """
        <g transform="translate($x, 40)" stroke-opacity="0.5">
        """)
    for col in colors
        write(io,
            """
                <rect x="0" y="$y" width="20" height="20" fill="#$(hex(col))" />
            """)
        y += 20
    end
    if !isempty(marker)
        y += 10
        write(io,
            """
                <path d="m 10,$y $marker" fill="#$(hex(last(colors)))" stroke="white" />
            """)
    end
    y += 20
    write(io,
        """
            <text x="0" y="$y" fill="currentColor" style="font-size: 15px;">$p</text>
        """)
    write(io, "</g>")
end

function write_stroke(io, tcolors, markers)
    write(io,
        """
        <g transform="translate(80, 20)" stroke="white" stroke-opacity="0.5">
        """)
    coord(c) = string(round(Int, c.c), ",", round(Int, 2 * (100 - c.l)), " ")
    for (i, colors) in enumerate(tcolors)
        coords = join(map(coord, LCHuv.(colors)))
        op = (0.4, 0.6, 1.0)[i]
        sw = (10, 4, 1)[i]
        write(io,
            """
                <path d="M $coords" fill="none" stroke-opacity="$op" stroke-width="$sw" />
            """)
    end
    for (i, colors) in enumerate(tcolors)
        mk = markers[i]
        hx = hex(last(colors))
        write(io,
            """
            <path d="M $(coord(LCHuv(first(colors))))$mk" fill="#$hx" />
            <path d="M $(coord(LCHuv(last( colors))))$mk" fill="#$hx" />
            """)
    end
    write(io, "</g>")
end

end # module
