# Colormap parameters

# To avoid over-specialization, we use `Any` as the value type,
# but the actual type should be exactly as used here.
const colormaps_sequential = Dict{String, Any}(
    #single hue
    #name         hue    w     d     c     s     b     wcolor              dcolor
    "blues"   => (255.0, 0.3,  0.25, 0.88, 0.6,  0.75, RGB(1.0, 1.0, 0.0), RGB(0.0, 0.0, 1.0)),
    "greens"  => (120.0, 0.15, 0.18, 0.88, 0.55, 0.9,  RGB(1.0, 1.0, 0.0), RGB(0.0, 0.0, 1.0)),
    "grays"   => (  0.0, 0.0,  0.0,  1.0,  0.0,  0.75, RGB(1.0, 1.0, 0.0), RGB(0.0, 0.0, 1.0)),
    "oranges" => ( 20.0, 0.5,  0.4,  0.83, 0.95, 0.85, RGB(1.0, 1.0, 0.0), RGB(1.0, 0.0, 0.0)),
    "purples" => (265.0, 0.15, 0.2,  0.88, 0.5,  0.7,  RGB(1.0, 0.0, 1.0), RGB(1.0, 0.0, 0.0)),
    "reds"    => ( 12.0, 0.15, 0.25, 0.8,  0.85, 0.6,  RGB(1.0, 1.0, 0.0), RGB(0.3, 0.1, 0.1)),
)

const colormaps_diverging = Dict{String, Any}(
    #name          h1     h2     w     d1    d2    c     s     b     wcolor              dcolor1             dcolor2
    "rdbu"     => ( 12.0, 255.0, 0.2,  0.6,  0.0,  0.85, 0.6,  0.65, RGB(1.0, 1.0, 0.0), RGB(1.0, 0.0, 0.0), RGB(0.0, 0.0, 1.0)),
)
