#!/bin/sh

set -eu

TEMP=$(mktemp)

cleanup() {
	rm "$TEMP"
}
trap cleanup EXIT

ftp -o "$TEMP" https://freedict.org/freedict-database.json

for l in $(jq '.[] | [.name, .edition, .status] | @sh' "$TEMP" | tr ' ' _); do
	name="${l#\"\'}"
	name="${name%%\'_*}"
	if [ "$name" = '"null_null_null"' ]; then
		break;
	fi
	edition="${l##\"\'*([!\'])\'_\'}"
	edition="${edition%%\'_*}"
	reason="${l##*_\'}"
	reason="${reason%\'\"}"
	if [ -d "/usr/ports/education/freedict/$name" ]; then
		port="$(make -C "/usr/ports/education/freedict/$name" -V V)"
		if [ "$port" != "$edition" ]; then
			echo "$name: $port vs $edition"
			sed -i "s/$port/$edition/g" \
			    "/usr/ports/education/freedict/$name/Makefile"
		fi
	else
	    echo "$name: missing, $(echo "$reason" | tr _ ' ')"
	fi
done
