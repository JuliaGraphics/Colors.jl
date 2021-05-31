# Colors

| **Documentation**                       | **Build Status**                          | **Code Coverage**               |
|:---------------------------------------:|:-----------------------------------------:|:-------------------------------:|
| [![][docs-stable-img]][docs-stable-url] | [![Build Status][action-img]][action-url] | [![][codecov-img]][codecov-url] |
| [![][docs-dev-img]][docs-dev-url]       | [![PkgEval][pkgeval-img]][pkgeval-url]    |                                 |

This library provides a wide array of functions for dealing with color. This
includes conversion between colorspaces, measuring distance between colors,
simulating color blindness, parsing colors, and generating color scales for graphics.

The core color types, along with some simple utilities, are defined and documented in [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl).
You can use ColorTypes as a standalone package if you do not need the more extensive color-manipulation utilities defined here.

Basic color arithmetic is available with `using ColorVectorSpace`; see [its documentation](https://github.com/JuliaGraphics/ColorVectorSpace.jl) for why it's a separate package.

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://juliagraphics.github.io/Colors.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliagraphics.github.io/Colors.jl/stable/

[action-img]: https://github.com/JuliaGraphics/Colors.jl/workflows/Unit%20test/badge.svg
[action-url]: https://github.com/JuliaGraphics/Colors.jl/actions

[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/Colors.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html

[codecov-img]: https://codecov.io/gh/JuliaGraphics/Colors.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/JuliaGraphics/Colors.jl
