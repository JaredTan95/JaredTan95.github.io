#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# 替换图片
sed -i '' 's#!\[\](#\{\{\< figure link="#g' `egrep -rl '!\[\]\(' content/posts/`
sed -i '' 's#!\[image\](#\{\{\< figure link="#g' `egrep -rl '!\[\]\(' content/posts/`
sed -i '' 's#png)#png" >\}\}#g' `egrep -rl 'png)' content/posts/`
sed -i '' 's#jpg)#jpg" >\}\}#g' `egrep -rl 'jpg)' content/posts/`
sed -i '' 's#svg)#svg" >\}\}#g' `egrep -rl 'svg)' content/posts/`
sed -i '' 's#gif)#gif" >\}\}#g' `egrep -rl 'gif)' content/posts/`

# rm bundle js and css
cd github
git rm -r ./js/bundle*
git rm -r ./css/bundle*
cd ../coding
git rm -r ./js/bundle*
git rm -r ./css/bundle*
cd ..

# Build the project.
hugo -d github
hugo -d coding

# Commit changes
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# GitHub
cd github
git add .
git commit -m "$msg"
git push origin master

# Coding
cd ../coding
git add .
git commit -m "$msg"
git push origin master
cd ..

# Algolia
hugo-algolia -o ./algolia.json -p "title, uri, categories" -s