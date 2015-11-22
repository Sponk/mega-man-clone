#!/bin/bash
rm -rf docs
mkdir docs

echo -n - > README.lua
cat README.md | \
while read CMD; do
	echo -n -- >> README.lua
    echo -n $CMD >> README.lua
	echo >> README.lua
done

echo -- Example: >> README.lua
echo -- /code >> README.lua
cat test/test.lua | \
while read CMD; do
	echo -n -- >> README.lua
    echo -n $CMD >> README.lua
	echo >> README.lua
done
echo -- /endcode >> README.lua

cat README.lua

mondoc -i README.lua src/tllut.lua -o docs
rm README.lua
