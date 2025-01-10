#!/bin/sh

set -eu

TEMP=$(mktemp)

cleanup() {
	rm "$TEMP"
}
trap cleanup EXIT

ftp -o "$TEMP" https://freedict.org/freedict-database.json

for ne in $(jq '.[] | [.name, .edition] | @sh' "$TEMP" | tr -d ' '); do
	name="${ne#\"\'}"
	name="${name%\'\'*}"
	if [ "$name" = '"nullnull"' ]; then
		break;
	fi
	edition="${ne##\"\'*([!\'])\'\'}"
	edition="${edition%\'\"}"
	if [ -d "/usr/ports/education/freedict/$name" ]; then
		port="$(make -C "/usr/ports/education/freedict/$name" -V V)"
		if [ "$port" != "$edition" ]; then
			#echo "$name: $port vs $edition"
			sed -i "s/$port/$edition/g" \
			    "/usr/ports/education/freedict/$name/Makefile"
		fi
	else
	    echo "$name: missing"
	fi
done
