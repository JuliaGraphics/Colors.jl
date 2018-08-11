using Luxor

function main()
    Drawing(500, 500, "/tmp/colorslogo.png")
    # transparent background
    origin()
    juliadarkercolors = [Luxor.darker_green, Luxor.darker_purple, Luxor.darker_red]
    julialightercolors = [Luxor.lighter_green, Luxor.lighter_purple, Luxor.lighter_red]
    pts = ngon(O + (0, 30), 110, 3, -pi/2, vertices=true)
    # I don't think I can draw it with compositing modes
    diskradius = 140
    # basic circles
    for (n, p) in enumerate(pts)
        sethue(juliadarkercolors[n])
        circle(pts[mod1(n-1, 3)], diskradius, :fill)
        sethue(julialightercolors[n])
        circle(pts[mod1(n-1, 3)], diskradius-15, :fill)
    end
    @layer begin
        for (n, p) in enumerate(pts)
            circle(p, diskradius, :clip)
            sethue(["cyan", "magenta", "yellow"][mod1(n, 3)])
            circle(pts[mod1(n+1, 3)], diskradius, :fill)
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
