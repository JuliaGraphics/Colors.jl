# Migrating from Color.jl

Colors.jl was forked from an original repository called `Color.jl` created
by Daniel Jones.

The following script can be helpful if you intending to migrate from `Color.jl` to `Colors.jl`.

```sh
# Intended to be run from the top directory in a package
# Do not run this twice on the same source tree without discarding
# the first set of changes.
sed -i 's/\bColor\b/Colors/g' REQUIRE

fls=$(find . -name "*.jl")
sed -i 's/\bColor\b/Colors/g' $fls               # Color -> Colors
sed -i -r 's/\bcolor\("(.*?)"\)/colorant\"\1\"/g' $fls   # color("red") -> colorant"red"
sed -i 's/AbstractAlphaColorValue/TransparentColor/g' $fls
sed -i 's/AlphaColorValue/TransparentColor/g' $fls   # might mean ColorAlpha
sed -i 's/ColorValue/Color/g' $fls
sed -i 's/ColourValue/Color/g' $fls
sed -i -r 's/\bLAB\b/Lab/g' $fls
sed -i -r 's/\bLUV\b/Luv/g' $fls
sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.c\.(\w)\b/\1\.\2/g' $fls      # colval.c.r -> colval.c
# This next one is quite dangerous, esp. for LCHab types...
# ...on the other hand, git diff is nice about showing the things we should fix
sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.c\b/color(\1)/g' $fls

# These are not essential, but they generalize to RGB24 better
# However, they are too error-prone to use by default since other color
# types like Lab have fields with the same names
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.r\b/red(\1)/g' $fls          # c.r -> red(c)
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.g\b/green(\1)/g' $fls
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.b\b/blue(\1)/g' $fls
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.alpha\b/alpha(\1)/g' $fls     # c.alpha -> alpha(c)
```

You are strongly advised to check the results carefully; for example,
any object `obj` with a field named `c` will get converted from
`obj.c` to `color(obj)`, and if `obj` is not a `Colorant` this is
surely not what you want.  You can use `git add -p` to review/edit
each change individually.
