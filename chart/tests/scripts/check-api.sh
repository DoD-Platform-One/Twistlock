#!/bin/bash
set -ex
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
CYN='\033[0;36m'
NC='\033[0m'

sleep 1m
echo "TEST 1 Begin: Checking Twistlock API endpoint..."
token=`curl -sk -H "Content-Type: application/json" -d "{\"username\":\"$cypress_user\", \"password\":\"$cypress_password\"}" "$twistlock_host/api/v1/authenticate" | jq '.token' | tr -d '"'`

if [[ -z "$token" ]] || [ "$token" = "null" ]; then
  echo "TEST 1 ${RED}FAILURE${NC}: Cannot hit Twistlock endpoint."
  echo "Debug information (curl response):"
  echo $(curl -sSk -H "Content-Type: application/json" -u $cypress_user:$cypress_password "$twistlock_host/api/v1/authenticate")
  echo "token: $token"
  exit 1
fi
echo "TEST 1 ${GRN}Success${NC}: Twistlock API is up."

# echo "Getting License info:"
# echo `curl -sSk -H "Authorization: Bearer $token" -X GET "$twistlock_host/api/v1/settings/license"`


echo "TEST 2 Begin: Checking Twistlock defender connection"

defenders_list=`curl -sSk -H "Authorization: Bearer $token" -X GET "$twistlock_host/api/v1/defenders/download" | tail -n +2`
defenders_count=`curl -sSk -H "Authorization: Bearer $token" -X GET "$twistlock_host/api/v1/defenders/download" | tail -n +2 | cut -d "," -f 1 | wc -l`

echo "Found $defenders_count connected Defenders"
echo "List Defenders:"
echo "Hostname,Type,Version,Connected,Cluster,Account ID"
echo $defenders_list

if !(( $defenders_count > 0)); then
  echo "TEST 2 ${RED}FAILURE${NC}: no connected Defenders"
  exit 1
fi
echo "TEST 2 ${GRN}Success${NC}: $defenders_count Twistlock Defenders are connected."
echo "List Defenders:"
echo "Hostname,Type,Version,Connected,Cluster,Account ID"
echo $defenders_list

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
