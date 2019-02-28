#!/bin/bash

set -e

echo "==========Starting Anypoint Exchange Sync=========="

if [[ -z "$ANYPOINT_TOKEN" ]]; then
	echo "Set the ANYPOINT_TOKEN env variable."
	exit 1
fi

# parse args
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

AUTH_HEADER="Authorization: token ${ANYPOINT_TOKEN}"

status_code=$(curl -v -i -X POST \
   -H "${AUTH_HEADER}" \
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

exchange_url="https://qax.anypoint.mulesoft.com/exchange/${ORG_ID}/${ASSET_ID}/"
echo "Published to ${exchange_url}"

echo "Publish tags"

TAGS_URI="https://anypoint.mulesoft.com/exchange/api/v1/assets/${ORG_ID}/${ASSET_ID}/v1/tags"


tags_resp=$(curl --data "[{\"key\":\"github_commit\", \"value\": \"$GITHUB_REF\", \"mutable\": false}]" -X PUT -s -H "${AUTH_HEADER}" ${TAGS_URI})

echo "$tags_resp"
echo "set tags for assets"

if [[ "$status_code" -ne 201 ]] ; then
  echo "Errored while pushing to Exchange. Status code: $status_code"
  exit 3
else
    
  echo "==========Finished Anypoint Exchange Sync=========="
  exit 0
fi
