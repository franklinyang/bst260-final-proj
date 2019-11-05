# bst260-final-proj

lowercase all files:
```
$(ls | awk '{system("mv " $0 " " tolower($0))}')
```
