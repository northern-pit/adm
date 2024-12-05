#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

# Variables
USERNAME="shershua"
PASSWORD="temporary_password"
SSH_KEY_FILE="ssh_public_key.txt"

# Check if the SSH key file exists
if [ ! -f "$SSH_KEY_FILE" ]; then
  echo "SSH key file $SSH_KEY_FILE not found!"
  exit 1
fi

# Read the SSH key from the file
SSH_KEY=$(cat $SSH_KEY_FILE)

# Create the user with a home directory and set the password
useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Force password change on first login
chage -d 0 $USERNAME

# Create .ssh directory and set permissions
mkdir -p /home/$USERNAME/.ssh
echo $SSH_KEY > /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Add user to sudo group
usermod -aG sudo $USERNAME

echo "User $USERNAME created and configured successfully."
