# Color Differences

The `colordiff` function gives an approximate value for the difference between two colors.

```jldoctest example; setup = :(using Colors)
julia> colordiff(colorant"red", parse(Colorant, HSV(360, 0.75, 1)))
8.178248292426845
```

`colordiff(a::Color, b::Color; metric::DifferenceMetric=DE_2000())`

Evaluate the [CIEDE2000](http://en.wikipedia.org/wiki/Color_difference#CIEDE2000) color difference formula by default. This gives an approximate measure of the perceptual difference between two colors to a typical viewer. A larger number is returned for increasingly distinguishable colors.

Options for `DifferenceMetric` are as follows:

| Option                                                 | Action                                        |
| ----------                                             | -------                                       |
|`DE_2000(kl::Float64, kc::Float64, kh::Float64)`        | Specify the color difference using the recommended CIEDE2000 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation.|
|`DE_2000()`                                             | - when not provided, these parameters default to 1.                                                                                                         |
|`DE_94(kl::Float64, kc::Float64, kh::Float64)`          | Specify the color difference using the recommended CIEDE94 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation.  |
|`DE_94()`                                               | - hen not provided, these parameters default to 1.                                                                                                          |
|`DE_JPC79()`                                            | Specify McDonald's "JP Coates Thread Company" color difference formula.                                                                                     |
|`DE_CMC(kl::Float64, kc::Float64)`                      | Specify the color difference using the CMC equation, with weighting parameters `kl` and `kc`.                                                               |
|`DE_CMC()`                                              | - when not provided, these parameters default to 1.                                                                                                         |
|`DE_BFD(wp::XYZ, kl::Float64, kc::Float64)`             | Specify the color difference using the BFD equation, with weighting parameters `kl` and `kc`. Additionally, a white point can be specified, because the BFD equation must convert between `XYZ` and `LAB` during the computation.|
|`DE_BFD(kl::Float64, kc::Float64)`                      |                                                                   |
|`DE_BFD()`                                              | - when not specified, the constants default to 1, and the white point defaults to CIED65.                                                                   |
|`DE_AB()`                                               | Specify the original, Euclidean color difference equation.                                                                                                  |
|`DE_DIN99()`                                            | Specify the Euclidean color difference equation applied in the `DIN99` uniform colorspace.                                                                 |
|`DE_DIN99d()`                                           | Specify the Euclidean color difference equation applied in the `DIN99d` uniform colorspace.                                                                 |
|`DE_DIN99o()`                                           | Specify the Euclidean color difference equation applied in the `DIN99o` uniform colorspace.                                                                 |

```@docs
colordiff
```
