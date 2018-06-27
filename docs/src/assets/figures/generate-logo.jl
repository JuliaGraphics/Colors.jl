using Luxor

@svg begin
    k = 35
    k1 = 220
    stepping = pi/10
    setopacity(0.9)
    for (n, theta) in enumerate(0:stepping:2pi)
        thickness = 15
        setline(0.5)
        i = k
        while i < k1
            thickness *= 1.1
            @layer begin
                rotate(rescale(i, k, k1, 0, 2pi))
                col = Colors.HSL(rescale(theta, 0, 2pi, 0, 360), 1, rescale(i, k, k1, 0.7, 0.5))
                sethue(col)
                sector(O, i, i + thickness-3, theta, theta + stepping - 0.05, 10, :fill)
                sethue("black")
                sector(O, i, i + thickness-3, theta, theta + stepping - 0.05, 10, :stroke)
            end
            i += thickness
        end
    end
end 500 500 "/tmp/colorslogo.svg"
