# Introduction

This library provides a wide array of functions for dealing with color.

Supported colorspaces include:

- RGB, BGR, RGB1, RGB4, RGB24, plus transparent versions ARGB, RGBA, ABGR, BGRA, and ARGB32
- HSV, HSL, HSI, plus all 6 transparent variants (AHSV, HSVA, AHSL, HSLA, AHSI, HSIA)
- XYZ, xyY, LMS and all 6 transparent variants
- Lab, Luv, LCHab, LCHuv and all 8 transparent variants
- DIN99, DIN99d, DIN99o and all 6 transparent variants
- Storage formats YIQ, YCbCr and their transparent variants
- Gray, Gray24, and the transparent variants AGray, GrayA, and AGray32.

You can supply colors using names (eg `"red"`) or hex triplets (eg `#7aa457`)

Support is also provided for:

- color differences
- white balance
- color deficiency ("color blindness")
- colormaps and colorscales
