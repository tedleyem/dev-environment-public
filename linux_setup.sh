#!/bin/bash 
# Script to kick-off ansible playbook 
# and setup dev-environment  

sudo apt-get update 
sudo apt-get install -y ansible-core python3 python3-pip 

# Start Ansible Playbook 
ansible-playbook playbook.yml
