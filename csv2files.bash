#!/bin/bash

while IFS=, read -r bid address code
do
	dir="$(($bid/1000000))xxxxxx"
	mkdir -p "$dir"
	echo "$code" | sed 's/0x//' > "$dir/$bid-$address.hex"
done < codes.csv
