#!/bin/bash -eux

# Upgrade
apt-get -y update
apt-get -y upgrade

# Install Ansible repository.
apt-get -y install software-properties-common
apt-add-repository ppa:ansible/ansible
apt-get -y update

# Install Ansible.
apt-get -y install ansible
