#!/usr/bin/env bash

set -euox pipefail
export LC_ALL=C

CMDNAME=$( basename "$0" )

while getopts i:f: opt
do
  case $opt in
    "i" ) image_tag="${OPTARG}" ;;
    "f" ) error_level="${OPTARG}" ;;
      * ) echo "Usage: $CMDNAME [-i docker-image-tag] [-f error_level]" 1>&2
          echo "  -i : stop error level" 1>&2
          echo "  -f : docker image tag" 1>&2
          exit 1 ;;
  esac
done

dockle_latest=$(
    curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"v([^"]+)".*/\1/' \
)

not_output=$(
    curl -L -o dockle.deb https://github.com/goodwithtech/dockle/releases/download/v${dockle_latest}/dockle_${dockle_latest}_Linux-64bit.deb
    sudo dpkg -i dockle.deb
    rm dockle.deb
)

scan_result=$(
    dockle -f json ${image_tag}
)

# NOTE: git hub action上で実行すると「failed to analyze image」が発生する
#scan_result=$(
#    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
#    goodwithtech/dockle:v${dockle_latest} -f json ${image_tag}
#)

fatal_count=$(echo ${scan_result} | jq -r .summary.fatal)
if [ "x${fatal_count}" = "xnull" ]; then
  fatal_count=0
fi

warn_count=$(echo ${scan_result} | jq -r .summary.warn)
if [ "x${warn_count}" = "xnull" ]; then
  warn_count=0
fi

info_count=$(echo ${scan_result} | jq -r .summary.info)
if [ "x${info_count}" = "xnull" ]; then
  info_count=0
fi

error_count=0
case ${error_level,,} in
  "fatal")
    error_count=$(( ${fatal_count} ));;
  "warn")
    error_count=$((  ${fatal_count} + ${warn_count} ));;
  "info")
    error_count=$((  ${fatal_count} + ${warn_count} + ${info_count} ));;
  *)
    echo "Usage: $CMDNAME [-e error_level] Set the level to fatal or warn or info" 1>&2
    exit 1 ;;
esac

echo "FATAL : ${fatal_count} WARN : ${warn_count} INFO : ${info_count}"

# 指定されたレベルの脆弱性が存在する場合はエラーを返す
if [ ${error_count} -gt 0 ]; then
  exit 1
fi