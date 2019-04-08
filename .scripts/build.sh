#!/bin/bash
if [ "$1" = "" ]
then
    echo usage: $0 protocol [ protocol ... ]
    exit 0
fi

function build {
    echo building beamtest/beamtest-$x
    docker build -t beamtest/beamtest-$x $x
}


for x in $*
do
    build $x
done