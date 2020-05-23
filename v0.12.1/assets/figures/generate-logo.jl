using Luxor

function main()
    Drawing(500, 500, "/tmp/colorslogo.png")
    # transparent background
    origin()
    juliacolors = [Luxor.julia_green, Luxor.julia_purple, Luxor.julia_red]
    pts = ngon(O + (0, 30), 110, 3, -pi/2, vertices=true)
    # I don't think I can draw it with compositing modes
    diskradius = 140
    # basic circles
    for (n, p) in enumerate(pts)
        sethue(juliacolors[n])
        circle(pts[mod1(n-1, 3)], diskradius, :fill)
    end
    @layer begin
        for (n, p) in enumerate(pts)
            circle(p, diskradius, :clip)
            sethue(["cyan", "magenta", "yellow"][mod1(n, 3)])
            circle(pts[mod1(n + 1, 3)], diskradius, :fill)
            clipreset()
        end
    end
    # center
    sethue("azure")
    circle(pts[1], diskradius, :clip)
    circle(pts[2], diskradius, :clip)
    circle(pts[3], diskradius, :fill)
    clipreset()
    finish()
    preview()
end

main()
