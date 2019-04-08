#!/bin/bash
if [ "$1" = "" ]
then
    echo usage: $0 protocol [ ... ]
    exit 1
fi

$(aws ecr get-login --no-include-email) || exit 1

accountid=$(aws sts get-caller-identity --query Account --output text) || exit 2
region=$AWS_DEFAULT_REGION

for x in $*
do
    echo --- registering beamtest/$x
    echo 1. checking image digest between local and remote
    local_digest=$(docker image inspect beamtest/beamtest-$x:latest | jq -r '.[0].RepoDigests[0]' | cut -d @ -f 2)
    remote_digest=$(docker image inspect $accountid.dkr.ecr.ap-northeast-1.amazonaws.com/beamtest/beamtest-$x:latest | jq -r '.[0].RepoDigests[0]' | cut -d @ -f 2)
    if [ "$local_digest" = "$remote_digest" ] 
    then
        echo same image exists. skipping...
    else
        echo 2. tagging and register new image.
        docker tag beamtest/beamtest-$x:latest $accountid.dkr.ecr.$region.amazonaws.com/beamtest/beamtest-$x:latest || exit 3
        docker push $accountid.dkr.ecr.$region.amazonaws.com/beamtest/beamtest-$x:latest || exit 4
        echo 3. update service to replace tasks.
        aws ecs update-service --cluster beamtest --service beamtest-$x --force-new-deployment --query service.deployments
    fi

done

