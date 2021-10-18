#!/bin/bash

while IFS=, read -r fork address code
do
	mkdir -p "$fork"
	echo "$code" | sed 's/0x//' > "$fork/$address.hex"
done < codes.csv
