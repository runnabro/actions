#!/bin/bash

set -e

echo "==========Starting Anypoint Exchnage Sync=========="

if [[ -z "$ANYPOINT_TOKEN" ]]; then
	echo "Set the ANYPOINT_TOKEN env variable."
	exit 1
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -o|--org-id)
    ORG_ID="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--asset-id)
    ASSET_ID="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--resource-path)
    RAML_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--main-file)
    MAIN_FILE="$2"
    shift # past argument
    shift # past value
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo ${ORG_ID}
echo ${ASSET_ID}
echo ${RAML_PATH}
echo ${MAIN_FILE}

zip -j -r raml.zip ${RAML_PATH}

echo "Created Zip Archive"

status_code=$(curl --silent --output /dev/null --write-out %{http_code} -i -X POST \
   -H "Authorization:Bearer ${ANYPOINT_TOKEN}" \
   -H "Content-Type:multipart/form-data" \
   -F "name=${ASSET_ID}" \
   -F "apiVersion=v1" \
   -F "classifier=raml" \
   -F "groupId=${ORG_ID}" \
   -F "assetId=${ASSET_ID}" \
   -F "version=1.0.1-SNAPSHOT" \
   -F "main=${MAIN_FILE}" \
   -F "organizationId=${ORG_ID}" \
   -F "someFileName=@\"raml.zip\";type=application/zip;filename=\"raml.zip\"" \
 https://qax.anypoint.mulesoft.com/exchange/api/v1/assets)

if [[ "$status_code" -ne 201 ]] ; then
  echo "Site status changed to $status_code"
  exit 3
else
  echo "==========Finished Anypoint Exchnage Sync=========="
  exit 0
fi
