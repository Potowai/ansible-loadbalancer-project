#!/bin/bash

# Setup script for local Docker environment

echo "Creating SSH keys..."
mkdir -p keys
# Generate specific keypair for this lab if it doesn't exist
if [ ! -f keys/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f keys/id_rsa -N "" -C "ansible_lab"
    chmod 600 keys/id_rsa
fi

echo "Starting containers..."
docker-compose up -d --build

echo "Waiting for SSH services to be ready..."
sleep 10

echo "Copying public key to containers..."
PUB_KEY=$(cat keys/id_rsa.pub)

# Function to add key to container
add_key() {
    CONTAINER=$1
    echo "Adding key to $CONTAINER..."
    docker exec -i $CONTAINER bash -c "mkdir -p /home/ansible/.ssh && echo '$PUB_KEY' >> /home/ansible/.ssh/authorized_keys && chown -R ansible:ansible /home/ansible/.ssh && chmod 700 /home/ansible/.ssh && chmod 600 /home/ansible/.ssh/authorized_keys"
}

add_key web1
add_key web2
add_key lb1

echo "Installing Ansible on Control node..."
docker exec -i ansible_control bash -c "apt-get update && apt-get install -y ansible ssh iputils-ping curl"

echo "---------------------------------------------------"
echo "Environment Ready! To deploy, run:"
echo "docker exec -it ansible_control ansible-playbook -i inventory/docker_hosts.ini playbook.yml"
echo "---------------------------------------------------"
