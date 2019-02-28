#!/bin/bash

set -e

echo "==========Starting Anypoint Exchnage Sync=========="

if [[ -z "$ANYPOINT_TOKEN" ]]; then
	echo "Set the ANYPOINT_TOKEN env variable."
	exit 1
fi



echo "==========Finished Anypoint Exchnage Sync=========="