#!/bin/bash

while IFS=, read -r bid address code
do
	dir="runtime/$(($bid/1000000))xxxxxx"
	mkdir -p "$dir"
	echo "$code" | sed 's/0x//' > "$dir/$bid-$address.hex"
done < runtime.csv

while IFS=, read -r bid address code
do
	dir="deployment/$(($bid/1000000))xxxxxx"
	mkdir -p "$dir"
	echo "$code" | sed 's/0x//' > "$dir/$bid-$address.hex"
done < deployment.csv
