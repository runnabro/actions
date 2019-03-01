#!/bin/bash

set -e

echo "==========Starting Anypoint Exchange Sync=========="

echo "Handle ${GITHUB_EVENT_NAME} event and ref: ${GITHUB_REF}"

if [[ -z "$ANYPOINT_USERNAME" ]]; then
	echo "Set the ANYPOINT_USERNAME env variable."
	exit 1
fi

if [[ -z "$ANYPOINT_PASSWORD" ]]; then
	echo "Set the ANYPOINT_PASSWORD env variable."
	exit 1
fi

ANYPOINT_URL="https://qax.anypoint.mulesoft.com"

ANYPOINT_TOKEN=$(curl --silent ${ANYPOINT_URL}/accounts/login -XPOST -d "username=${ANYPOINT_USERNAME}&password=${ANYPOINT_PASSWORD}" | jq '.access_token')

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

LAST_TAG=$(git describe --abbrev=0 --tags || echo "0.0.1")

echo "Git latest tags: ${LAST_TAG}"

## if push the version is latest tag + '-NEXT'
if [[ $GITHUB_EVENT_NAME == "push" ]]; then
  echo "handle push"
  ASSET_VERSION="${LAST_TAG}-NEXT"
fi
## if release ASSET version is from the release
if [[ $GITHUB_EVENT_NAME == "release" ]]; then
  echo "handle release"
  TAG="$(jq -r ".release.tag_name" "$GITHUB_EVENT_PATH")"
  ACTION="$(jq -r ".action" "$GITHUB_EVENT_PATH")"
  if [ $ACTION != "published"]
    then
      echo "Nothing to do for action ${ACTION}"
      exit 78
    fi
  ASSET_VERSION=TAG
fi
## if pull request the version is latest tag + '-PR-{NUMBER}'
if [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
  echo "handle pull_request"
  ACTION=$(jq -r ".action" "$GITHUB_EVENT_PATH")
  if [ "$ACTION" != "opened" ] && [ "$ACTION" != "synchronize" ]
    then
      echo "Nothing to do for action ${ACTION}"
      exit 78
    fi
  PR_NUMBER="$(jq -r ".number" "$GITHUB_EVENT_PATH")"
  ASSET_VERSION="${LAST_TAG}-PR-${PR_NUMBER}"
  # TODO check that action is sync or open
fi

zip -j -r raml.zip ${RAML_PATH}

echo "Created Zip Archive"

AUTH_HEADER="Authorization: bearer ${ANYPOINT_TOKEN}"

status_code=$(curl -v -i -X POST \
   -H "${AUTH_HEADER}" \
   -H "Content-Type:multipart/form-data" \
   -F "name=${ASSET_ID}" \
   -F "apiVersion=v1" \
   -F "classifier=raml" \
   -F "groupId=${ORG_ID}" \
   -F "assetId=${ASSET_ID}" \
   -F "version=${ASSET_VERSION}" \
   -F "main=${MAIN_FILE}" \
   -F "organizationId=${ORG_ID}" \
   -F "someFileName=@\"raml.zip\";type=application/zip;filename=\"raml.zip\"" \
 ${ANYPOINT_URL}/exchange/api/v1/assets)

if [[ "$status_code" -ne 201 ]] ; then
  echo "Errored while pushing to Exchange. Status code: $status_code"
  exit 3
fi


exchange_url="${ANYPOINT_URL}/exchange/${ORG_ID}/${ASSET_ID}/"
echo "Published to ${exchange_url}"

echo "Publish tags. Start."
TAGS_URI="${ANYPOINT_URL}/exchange/api/v1/organizations/${ORG_ID}/assets/${ORG_ID}/${ASSET_ID}/1.0.1-SNAPSHOT/tags"

tags_resp=$(curl --data "[{\"key\":\"github_commit\", \"value\": \"github_commit:$GITHUB_SHA\", \"mutable\": false}, {\"key\":\"github_user\", \"value\": \"github_user:$GITHUB_ACTOR\", \"mutable\": false}, {\"key\":\"github_repo\", \"value\": \"github_repo:$GITHUB_REPOSITORY\", \"mutable\": false}]" -X PUT -s -H "Content-Type:application/json" -H "${AUTH_HEADER}" ${TAGS_URI})

echo "$tags_resp"
echo "Publish tags for assets. Done."


if [[ "$status_code" -ne 201 ]] ; then
  echo "Errored while pushing to Exchange. Status code: $status_code"
  exit 3
else
  echo "==========Finished Anypoint Exchange Sync=========="
  exit 0
fi