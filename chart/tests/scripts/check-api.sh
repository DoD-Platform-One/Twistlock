#!/bin/bash
set -ex
sleep 1m
echo "Hitting Twistlock API endpoint..."
curl -sISk -H 'Authorization: Basic "${api_auth}"' "${twistlock_host}/" &>/dev/null || export TW_DOWN="true"
if [[ ${TW_DOWN} == "true" ]]; then
  echo "Test 1 Failure: Cannot hit Twistlock endpoint."
  echo "Debug information (curl response):"
  echo $(curl -k -H 'Authorization: Basic "${api_auth}"' "${twistlock_host}/")
  exit 1
fi
echo "Test 1 Success: Twistlock API is up."

# A license is required to do more
#echo "Creating admin user for further testing"
#curl -k -H 'Content-Type: application/json' -XPOST -d '{"username": "admin", "password": "admin"}' "${twistlock_host}/api/v1/signup" &>/dev/null
#echo "Created admin user for further testing."
#
#echo "Hitting Twistlock API Version endpoint..."
#version_response=$(curl -k -H 'Content-Type: application/json' -H 'Authorization: Basic YWRtaW46YWRtaW4=' "${twistlock_host}/api/v1/version" 2>/dev/null)
#current_version=$(echo ${version_response} | xargs)
#if [ ! ${desired_version} == ${current_version} ]; then
#  echo "Test 2 Failure: Twistlock version does not match."
#  echo "Debug information (curl response):"
#  echo $(curl -k -H 'Content-Type: application/json' -H 'Authorization: Basic "${api_auth}"' "${twistlock_host}/api/v1/version")
#  exit 1
#fi
#echo "Test 2 Success: Twistlock Version Matches."
