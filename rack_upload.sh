#!/bin/bash
# Upload directory contents to Rackspace container
export WHEELHOUSE_UPLOADER_USERNAME=travis-worker
export WHEELHOUSE_UPLOADER_SECRET=$(cat ~/.scikit_creds | grep api_key | cut -d" " -f3)
if [ -z "$1" ]; then
    echo Specify directory to upload
    exit 1
fi
local_folder=$1
shift
if [ -z "$1" ]; then
    echo Specify rackspace container
    exit 2
fi
container=$1
shift
upload_args="$@"
if [ "$container" == "wheels" ] || [ "$container" == "extra-wheels" ]; then
    upload_args="$upload_args --no-update-index"
fi
python -m wheelhouse_uploader upload --local-folder=$local_folder $upload_args $container

