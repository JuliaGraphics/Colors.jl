using PyPlot

function dinplot()
for x = -100:20:100

    return a=convert(DIN99o,LAB(50,0,x))
    return b=convert(DIN99o,LAB(50,x,0))
    return c=convert(DIN99o,LAB(50,100,x))
    return d=convert(DIN99o,LAB(50,-100,x))
    return e=convert(DIN99o,LAB(50,x,100))
    return f=convert(DIN99o,LAB(50,x,-100))

    plot((a.a,a.b),(b.a,b.b),(c.a,c.b),(d.a,d.b),(e.a,e.b),(f.a,f.b)"ro")
end
end
