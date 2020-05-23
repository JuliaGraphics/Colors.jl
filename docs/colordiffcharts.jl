
module ColorDiffCharts

using Colors

struct ColorDiffChartSVG <: Main.SVG
    buf::IOBuffer
end

const c = Lab.((Colors.JULIA_LOGO_COLORS.green,
                Colors.JULIA_LOGO_COLORS.red,
                Colors.JULIA_LOGO_COLORS.purple))

function ColorDiffChartSVG(metric::Colors.DifferenceMetric)
    io = IOBuffer()

    id = nameof(typeof(metric))

    d12 = colordiff(c[1], c[2], metric=metric)
    d23 = colordiff(c[2], c[3], metric=metric)
    d31 = colordiff(c[3], c[1], metric=metric)

    dn = 2*d31^2 - d23^2 + 2*d12^2
    ds0 = -(d31-d23-d12) * (d31-d23+d12) * (d31+d23-d12) * (d31+d23+d12)
    # `ds0` should be non-negative in metric systems.
    # However, DE_CMC is not metric but quasimetric.
    ds = max(ds0, 0)

    x = [0,
         -sqrt(ds/dn)/2,
          sqrt(ds/dn)/2]

    y = [-sqrt(dn) / 3,
         (( -d31^2 - d23^2 + 5*d12^2) * sqrt(dn)) / 6dn,
         ((5*d31^2 - d23^2 -   d12^2) * sqrt(dn)) / 6dn]

    # verification
    if ds0 >= 0
        d12 ≈ hypot(x[1] - x[2], y[1] - y[2]) || error("distance mismatch: d12")
        d23 ≈ hypot(x[2] - x[3], y[2] - y[3]) || error("distance mismatch: d23")
        d31 ≈ hypot(x[3] - x[1], y[3] - y[1]) || error("distance mismatch: d31")
    end

    scale = 7.5 / abs(y[1])

    sx = scale .* x
    sy = scale .* y
    r = scale * 20

    mx12, my12 = (sx[1] + sx[2]) * 0.5, (sy[1] + sy[2]) * 0.5
    mx23, my23 = (sx[2] + sx[3]) * 0.5, (sy[2] + sy[3]) * 0.5
    mx31, my31 = (sx[3] + sx[1]) * 0.5, (sy[3] + sy[1]) * 0.5

    a = atan(sy[2] - sy[3], sx[2] - sx[3])
    dy23, dx23 = 8 .* sincos(a)

    simplify(x) = replace(string(round(x, sigdigits=3)), r"\.0+$"=>"")
    rd12, rd23, rd31 = simplify.((d12, d23, d31))

    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             viewBox="-15 -12 30 30" width="30mm" height="30mm"
             stroke="none" stroke-linejoin="round"
             style="display:inline; margin-left:2em; margin-bottom:2em">
        <defs>
          <marker id="marker_s_$id" orient="auto" style="overflow:visible">
            <path d="M 7,-30 l -7,4 7,4 M 0,-26 h 9 M 0,-3 v -27"
                  style="fill:none;stroke:currentColor;stroke-opacity:0.7;" />
          </marker>
          <marker id="marker_e_$id" orient="auto" style="overflow:visible">
            <path d="M -7,-30 l 7,4 -7,4 M 0,-26 h -9 M 0,-3 v -27"
                  style="fill:none;stroke:currentColor;stroke-opacity:0.7;" />
          </marker>
        </defs>
        <g>
          <circle cx="$(sx[3])" cy="$(sy[3])" fill="#$(hex(c[3]))" r="$r" />
          <circle cx="$(sx[2])" cy="$(sy[2])" fill="#$(hex(c[2]))" r="$r" />
          <circle cx="$(sx[1])" cy="$(sy[1])" fill="#$(hex(c[1]))" r="$r" />
        </g>
        <g style="stroke:currentColor;stroke-width:0.2;stroke-opacity:0.4;
           marker-start:url(#marker_s_$id);marker-end:url(#marker_e_$id)">
          <path d="M$(sx[3]),$(sy[3]) L$(sx[2]),$(sy[2])"/>
          <path d="M$(sx[2]),$(sy[2]) L$(sx[1]),$(sy[1])"/>
          <path d="M$(sx[1]),$(sy[1]) L$(sx[3]),$(sy[3])"/>
        </g>
        <g fill="currentColor" style="font-size:2.8px;">
          <text x="$(mx12-3)" y="$my12" text-anchor="end">$rd12</text>
          <text x="$(mx23+dy23)" y="$(my23-dx23+1)" text-anchor="middle">$rd23</text>
          <text x="$(mx31+3)" y="$my31" text-anchor="start">$rd31</text>
          <text x="-14" y="17" style="font-size:2.5px;">$id</text>
        </g>
        </svg>""")
    ColorDiffChartSVG(io)
end

end
