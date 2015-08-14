
using Colors

# Test data from the DIN 6176 specification
const testdata = [
((50,  10,  10), (61.43,   9.70,   3.76)),
((50,  50,  50), (61.43,  28.64,  11.11)),
((50, -10,  10), (61.43,  -5.57,   7.03)),
((50, -50,  50), (61.43, -17.22,  21.75)),
((50, -10, -10), (61.43,  -9.70,  -3.76)),
((50, -50, -50), (61.43, -28.64, -11.11)),
((50,  10, -10), (61.43,   5.57,  -7.03)),
((50,  50, -50), (61.43,  17.22, -21.75)),
(( 0,   0,   0), ( 0,      0,      0)),
((100,  0,   0), (100,     0,      0))]

# A high error threshold has been chosen because converting from DIN99
# to CIELAB with only two decimal places of accuracy yields fairly inaccurate
# results due to the exponentiation.
const conveps = 0.05
const diffeps = 0.01
for (i, (a, b)) in enumerate(testdata)
    converted = convert(DIN99, Lab(a...))
    test = DIN99(b...)

    @assert (abs(converted.l - test.l) < conveps)
    @assert (abs(converted.a - test.a) < conveps)
    @assert (abs(converted.b - test.b) < conveps)

    converted = convert(Lab, DIN99(b...))
    test = Lab(a...)

    @assert (abs(converted.l - test.l) < conveps)
    @assert (abs(converted.a - test.a) < conveps)
    @assert (abs(converted.b - test.b) < conveps)

    # This is not a real test of the color difference metric, but at least
    # makes sure it isn't doing anything really crazy.
    metric = DE_DIN99()
    @assert (abs(colordiff(convert(DIN99, Lab(a...)), DIN99(b...), metric)) < diffeps)


end
