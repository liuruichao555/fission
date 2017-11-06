#!/bin/bash

set -euo pipefail

ROOT=$(dirname $0)/../..

fn=python-hello-$(date +%N)

# Create a hello world function in python, test it with an http trigger
echo "Pre-test cleanup"
fission env delete --name python || true

echo "Creating nodejs env"
fission env create --name python --image fission/python-env
trap "fission env delete --name python" EXIT

echo "Creating function"
fission fn create --name $fn --env python --code $ROOT/examples/python/hello.py
trap "fission fn delete --name $fn" EXIT

echo "Creating route"
fission route create --function $fn --url /$fn --method GET

echo "Waiting for router to catch up"
sleep 3

echo "Doing an HTTP GET on the function's route"
response=$(curl http://$FISSION_ROUTER/$fn)

echo "Checking for valid response"
echo $response | grep -i hello

# crappy cleanup, improve this later
kubectl get httptrigger -o name | tail -1 | cut -f2 -d'/' | xargs kubectl delete httptrigger

echo "All done."
