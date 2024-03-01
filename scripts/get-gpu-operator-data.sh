#!/bin/bash

CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')
echo "using $CHANNEL GPU Operator channel"

CSV=$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')
echo "using $CSV as the starting csv for the GPU Operator"

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg channel "$CHANNEL" --arg csv "$CSV" '{"channel":$channel, "csv":$csv}'