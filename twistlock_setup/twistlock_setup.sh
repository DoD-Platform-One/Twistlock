#!/bin/bash

#The "Bearer" token can be found in the twistlock application Manage/Authorization/User Certificates.  Alternatively, run the following commands

TWISTLOCK_CONSOLE_USER=Administrator
TWISTLOCK_CONSOLE_PASSWORD=Passw0rd! # Don't use thes
TWISTLOCK_EXTERNAL_ROUTE=twistlock.fences.dsop.io

# set Twistlock console user/pass

if ! curl -k -H 'Content-Type: application/json' -X POST \
     -d "{\"username\": \"$TWISTLOCK_CONSOLE_USER\", \"password\": \"$TWISTLOCK_CONSOLE_PASSWORD\"}" \
     https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/signup; then

    echo "Error creating Twistlock Console user $TWISTLOCK_CONSOLE_USER"
    exit 1
fi

# Set Twistlock license. Using default user/pass

if ! curl -k \
  -u $TWISTLOCK_CONSOLE_USER:$TWISTLOCK_CONSOLE_PASSWORD \
  -H 'Content-Type: application/json' \
  -X POST \
  -d "{\"key\": \"$TWISTLOCK_LICENSE\"}" \
  https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/settings/license; then 

    echo "Error uploading Twistlock license to console"
    exit 1
fi



curl -sSLk  -u $TWISTLOCK_CONSOLE_USER:$TWISTLOCK_CONSOLE_PASSWORD https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/util/twistcli > twistcli

chmod +x ./twistcli

# Change the image tag to reflect Platform One registry:
# registry.dsop.io/platform-one/apps/twistlock/defender:20.04.169

./twistcli defender export kubernetes --namespace twistlock --privileged --cri --monitor-service-accounts --monitor-istio --user $TWISTLOCK_CONSOLE_USER --password $TWISTLOCK_CONSOLE_PASSWORD --address https://$TWISTLOCK_EXTERNAL_ROUTE --cluster-address twistlock-console:8084

# kubectl apply -f ./defender
#setup logging to stdout
if ! curl -k \
  -u $TWISTLOCK_CONSOLE_USER:$TWISTLOCK_CONSOLE_PASSWORD \
  -H 'Content-Type: application/json' \
  -X POST \
  -d \
  '{
   "stdout": {
     "enabled": true,
     "verboseScan": true,
     "allProcEvents": true,
     }
  }' \
  https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/settings/logging; then

    echo "Error editing syslog settings on console"
    exit 1
fi

