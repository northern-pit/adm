#!/bin/bash

# Create a timestamped log file
logfile=$(date "+%Y%m%d_%H%M%S")_$(uname -n)_apt_upgrade.log

# Execute the commands and redirect output to the log file
{
    date
    apt update
    apt list --upgradable

    # Pause and prompt the user to continue or cancel
    while true; do
        read -p "Do you want to continue with the upgrade? (yes/no): " choice
        case "$choice" in
            yes|y ) break;;  # Continue script execution
            no|n ) echo -e "\n--------------------------\nScript execution cancelled.\n\n"; exit;;  # Exit script with a message split over two lines
            * ) echo "Please answer yes or no.";;
        esac
    done

    # Proceed with the upgrade if the user chooses to continue
    apt upgrade -y
    apt update
} | tee "$logfile"
