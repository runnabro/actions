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

ANYPOINT_TOKEN=$(curl --silent ${ANYPOINT_URL}/accounts/login -XPOST -d "username=${ANYPOINT_USERNAME}&password=${ANYPOINT_PASSWORD}" | jq -r '.access_token')

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

LAST_TAG=$(git describe --abbrev=0 --tags || echo "0.0.0")


increment_version() {
   local usage=" USAGE: $FUNCNAME [-l] [-t] <version> [<position>] [<leftmost>]
           -l : remove leading zeros
           -t : drop trailing zeros
    <version> : The version string.
   <position> : Optional. The position (starting with one) of the number 
                within <version> to increment.  If the position does not 
                exist, it will be created.  Defaults to last position.
   <leftmost> : The leftmost position that can be incremented.  If does not
                exist, position will be created.  This right-padding will
                occur even to right of <position>, unless passed the -t flag."

   # Get flags.
   local flag_remove_leading_zeros=0
   local flag_drop_trailing_zeros=0
   while [ "${1:0:1}" == "-" ]; do
      if [ "$1" == "--" ]; then shift; break
      elif [ "$1" == "-l" ]; then flag_remove_leading_zeros=1
      elif [ "$1" == "-t" ]; then flag_drop_trailing_zeros=1
      else echo -e "Invalid flag: ${1}\n$usage"; return 1; fi
      shift; done

   # Get arguments.
   if [ ${#@} -lt 1 ]; then echo "$usage"; return 1; fi
   local v="${1}"             # version string
   local targetPos=${2-last}  # target position
   local minPos=${3-${2-0}}   # minimum position

   # Split version string into array using its periods. 
   local IFSbak; IFSbak=IFS; IFS='.' # IFS restored at end of func to                     
   read -ra v <<< "$v"               #  avoid breaking other scripts.

   # Determine target position.
   if [ "${targetPos}" == "last" ]; then 
      if [ "${minPos}" == "last" ]; then minPos=0; fi
      targetPos=$((${#v[@]}>${minPos}?${#v[@]}:$minPos)); fi
   if [[ ! ${targetPos} -gt 0 ]]; then
      echo -e "Invalid position: '$targetPos'\n$usage"; return 1; fi
   (( targetPos--  )) || true # offset to match array index

   # Make sure minPosition exists.
   while [ ${#v[@]} -lt ${minPos} ]; do v+=("0"); done;

   # Increment target position.
   v[$targetPos]=`printf %0${#v[$targetPos]}d $((10#${v[$targetPos]}+1))`;

   # Remove leading zeros, if -l flag passed.
   if [ $flag_remove_leading_zeros == 1 ]; then
      for (( pos=0; $pos<${#v[@]}; pos++ )); do
         v[$pos]=$((${v[$pos]}*1)); done; fi

   # If targetPosition was not at end of array, reset following positions to
   #   zero (or remove them if -t flag was passed).
   if [[ ${flag_drop_trailing_zeros} -eq "1" ]]; then
        for (( p=$((${#v[@]}-1)); $p>$targetPos; p-- )); do unset v[$p]; done
   else for (( p=$((${#v[@]}-1)); $p>$targetPos; p-- )); do v[$p]=0; done; fi

   echo "${v[*]}"
   IFS=IFSbak
   return 0
}

NEW_INC_VERSION=$(increment_version $LAST_TAG)


echo "Git latest tags: ${LAST_TAG}"
echo "New version: ${NEW_INC_VERSION}"

## if push the version is latest tag + '-NEXT'
if [[ $GITHUB_EVENT_NAME == "push" ]]; then
  echo "handle push"
  ASSET_VERSION="$NEW_INC_VERSION-SNAPSHOT"
fi
## if release ASSET version is from the release
if [[ $GITHUB_EVENT_NAME == "release" ]]; then
  echo "handle release"
  TAG="$(jq -r ".release.tag_name" "$GITHUB_EVENT_PATH")"
  ACTION="$(jq -r ".action" "$GITHUB_EVENT_PATH")"
  if [ "$ACTION" != "published"]
    then
      echo "Nothing to do for action $ACTION"
      exit 78
    fi
  ASSET_VERSION="$TAG"
fi
## if pull request the version is latest tag + '-PR-{NUMBER}'
if [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
  echo "handle pull_request"
  ACTION=$(jq -r ".action" "$GITHUB_EVENT_PATH")
  if [ "$ACTION" != "opened" ] && [ "$ACTION" != "synchronize" ]
    then
      echo "Nothing to do for action $ACTION"
      exit 78
    fi
  PR_NUMBER="$(jq -r ".number" "$GITHUB_EVENT_PATH")"
  ASSET_VERSION="$NEW_INC_VERSION-PR-$PR_NUMBER-SNAPSHOT"
fi

echo "New asset version is $ASSET_VERSION"

zip -j -r raml.zip ${RAML_PATH}

echo "Created Zip Archive"

AUTH_HEADER="Authorization: bearer ${ANYPOINT_TOKEN}"

status_code=$(curl --verbose -X POST \
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

echo "resp ${status_code}"
# if [[ "$status_code" -ne 201 ]] ; then
#   echo "Errored while pushing to Exchange. Status code: $status_code"
#   exit 3
# fi


exchange_url="${ANYPOINT_URL}/exchange/${ORG_ID}/${ASSET_ID}/"
echo "Published to ${exchange_url}"

designer_url="${ANYPOINT_URL}/designcenter/designer/#/exchange/${ORG_ID}/${ASSET_ID}/${ASSET_VERSION}"

echo "Open in the designer ${designer_url}"

echo "Publish tags. Start."
TAGS_URI="${ANYPOINT_URL}/exchange/api/v1/organizations/${ORG_ID}/assets/${ORG_ID}/${ASSET_ID}/${ASSET_VERSION}/tags"

tags_resp=$(curl --data "[{\"key\":\"github_commit\", \"value\": \"github_commit:$GITHUB_SHA\", \"mutable\": false}, {\"key\":\"github_user\", \"value\": \"github_user:$GITHUB_ACTOR\", \"mutable\": false}, {\"key\":\"github_repo\", \"value\": \"github_repo:$GITHUB_REPOSITORY\", \"mutable\": false}]" -X PUT -s -H "Content-Type:application/json" -H "${AUTH_HEADER}" ${TAGS_URI})

echo "$tags_resp"
echo "Publish tags for assets. Done."


# if [[ "$status_code" -ne 201 ]] ; then
#   echo "Errored while pushing to Exchange. Status code: $status_code"
#   exit 3
# else
#   echo "==========Finished Anypoint Exchange Sync=========="
#   exit 0
# fi