# bst260-final-proj

lowercase all files:
```
$(ls | awk '{system("mv " $0 " " tolower($0))}')
```

print out the first few lines of each csv
```
$(find $PWD | grep csv | xargs head > heads.csv)
```
