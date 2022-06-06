#!/bin/bash

# Common functions for Twistlock initialization

# Only run once
if [ "$(type -t callapi)" != "function" ]; then

  # If a configuration directory is defined, read variables from the files located there
  if [ -n "$TWISTLOCK_CONFIG_DIR" ]; then
    mapfile -t FILES < <(find "$TWISTLOCK_CONFIG_DIR" -type f)
    for FILE in "${FILES[@]}"; do
      declare "$(basename "$FILE")"="$(cat "$FILE")"
    done
  fi

  TWISTLOCK_URL="$TWISTLOCK_CONSOLE_SERVICE:$TWISTLOCK_CONSOLE_SERVICE_PORT_HTTP_MGMT_HTTP"

  #######################################
  # Runs curl against the Twistlock API and returns the status code and response
  # Globals:
  #   TWISTLOCK_URL - the Twistlock endpoint
  #   TOKEN (optional) - the authz token for API access
  # Arguments (positional):
  #   1. request - "GET", "POST", or other HTTP request type
  #   2. endpoint - the API command/endpoint to use (http://twistlock/api/v1/<this is the endpoint>)
  #   3. data (optional) - additional data to send with the request
  #   4. ignorestatus - if set, do not exit on bad response status
  # Returns:
  #   RESP - the response data received from the API
  #   STATUS - the HTTP status code received from the API
  # Note: Status codes > 299 will trigger a program exit
  #######################################
  callapi() {
    local request=$1
    local endpoint=$2
    local data=$3
    local ignorestatus=$4
    local args=("-k" "-s" "-X" "$request" "-w" "%{http_code}" "-H" "Content-Type: application/json")

      # Add authz if defined
      if [ -n "$TOKEN" ]; then
        args+=("-H" "Authorization: Bearer $TOKEN")
      fi

      # Add data if defined
      if [ -n "$data" ]; then
        args+=("-d" "$data")
      fi

      # Send request
      local result; result=$(curl "${args[@]}" "$TWISTLOCK_URL/api/v1/$endpoint")

      # Parse response and status
      RESP=${result::-3}
      STATUS=$(printf "%s" "$result" | tail -c 3)
      if [ "$STATUS" -gt "299" ] && [ -z "$ignorestatus" ]; then
        logerror1 "API responded with status code $STATUS. (Response: $RESP)"
      fi
  }

  #######################################
  # Terminates Istio sidecar
  #######################################
  terminate_istio() {
    if [ -n "$ISTIO_SIDECAR" ]; then
      echo -n "Terminating Istio sidecar ... "
      curl -s -S -o /dev/null -X POST "http://localhost:15020/quitquitquit"
      logok ""
    fi
  }

  #######################################
  # Logs a green checkmark and "OK" before the provided string
  # Arguments:
  #   String to log
  # Outputs:
  #   Writes log to STDOUT
  #######################################
  logok() { echo -e "[\e[32m\xE2\x9C\x94\e[0m OK] $*"; }

  #######################################
  # Logs a red cross and "ERROR" before the provided string
  # Arguments:
  #   String to log
  # Outputs:
  #   Writes log to STDERR
  #######################################
  logerror() { echo -e "[\e[31m\xE2\x9C\x98\e[0m ERROR] $*" >&2; }

  #######################################
  # Logs an error, then exits with code 0
  # Arguments:
  #   String to log
  # Outputs:
  #   Writes log to STDOUT
  #######################################
  logerror0() { logerror "$*"; terminate_istio; exit 0; }

  #######################################
  # Logs an error, then exits with code 1
  # Arguments:
  #   String to log
  # Outputs:
  #   Writes log to STDERR
  #######################################
  logerror1() { logerror "$*"; terminate_istio; exit 1; }

fi