#!/bin/bash
declare -A NODE_VALS

RAW_DATA="$(clush -a "smartctl -A /dev/nvme0 | grep 'Data Units Written:' | awk '{print \$4}' | sed -e 's/\.//g' -e 's/,//g'")"

while IFS= read -r line; do
	WRT="${line/*: /}"
	NODE="${line/:*/}"
	WRT="${WRT}-${NODE}"
	NODE_VALS[$WRT]="$NODE"
done <<< "$RAW_DATA"

W=1
for i in $(printf '%s\n' "${!NODE_VALS[@]}" | sort -n); do
	#echo scontrol update NodeName="${NODE_VALS[$i]}" Weight="$W"
	FW="$W"
	NN="${NODE_VALS[$i]}"
	[[ "$NN" == nodeg* ]] && FW="$(( $W + 100 ))"
	scontrol update NodeName="$NN" Weight="$FW"
	W=$(( $W + 1 ))
done
