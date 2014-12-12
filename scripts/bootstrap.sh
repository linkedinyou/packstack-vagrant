#!/bin/bash

if [[ -z "$1" ]]; then
    p=1
else
    p=$1
fi

run() {
    number=$1
    shift
    python scripts/get_hosts.py | grep -v controller | xargs -n 1 -P $number \
        -I BOX sh -c "echo - BOX && (vagrant $* BOX 2>&1 >> log/BOX.log)"
}

if [[ ! -e config.yaml ]]; then
    echo "error: configuration file 'config.yaml' does not exist"
    exit 1
fi

echo "$(date) cleaning up"
rm -f log/*
vagrant destroy

echo "$(date) bringign up, provisioning and reloading the controller VM"
vagrant up controller >> log/controller.log
vagrant reload controller >> log/controller.log

echo "$(date) brining up all VMs"
run $p up --no-provision

echo "$(date) provisioning all other VMs"
run $p provision

echo "$(date) reloading all other VMs"
run $p reload

echo "$(date) initializing the controller node"
vagrant ssh controller -c '/home/vagrant/scripts/initialize.sh' 2>&1 >> log/controller.log
