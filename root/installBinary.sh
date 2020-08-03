#!/bin/bash

. /plex-common.sh

addVarToConf "version" "${TAG}"
addVarToConf "plex_build" "${PLEX_BUILD}"
addVarToConf "plex_distro" "${PLEX_DISTRO}"

if [ ! -z "${URL}" ]; then
  echo "Attempting to install from URL: ${URL}"
  installFromRawUrl "${URL}"
else
  getVersionInfo "${TAG}" "" remoteVersion remoteFile

  if [ -z "${remoteVersion}" ] || [ -z "${remoteFile}" ]; then
    echo "Could not get install version"
    exit 1
  fi

  echo "Attempting to install: ${remoteVersion}"
  installFromUrl "${remoteFile}"
fi
