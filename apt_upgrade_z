#!/bin/bash

# Create a timestamped log file
logfile=$(date "+%Y%m%d_%H%M%S")_$(uname -n)_apt_upgrade.log

# Execute the commands and redirect output to the log file
{
    echo "--- STARTING SYSTEM UPDATE @ $(date) ---"
    
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
    echo "--- PROCEEDING WITH APT UPGRADE ---"
    apt upgrade -y
    
    # Run apt update again in case new dependencies were needed (good practice)
    apt update
    
    echo "--- SYSTEM UPGRADE COMPLETE ---"
    
    # --- PACKAGE CLEANUP LOGIC ---
    echo "--- Cleaning up old packages ---"
    # Remove packages that were installed as dependencies but are no longer needed
    if sudo apt autoremove -y; then
        echo "SUCCESS: Autoremove complete."
    else
        echo "WARNING: Autoremove failed." >&2
    fi
    # Clear the local repository of retrieved package files (.deb)
    if sudo apt autoclean; then
        echo "SUCCESS: Autoclean complete."
    else
        echo "WARNING: Autoclean failed." >&2
    fi
    echo "--- PACKAGE CLEANUP COMPLETE ---"
    # --- END PACKAGE CLEANUP LOGIC ---
    
    
    # --- ZABBIX SERVICE RESTART LOGIC ---
    echo "--- CHECKING FOR ZABBIX SERVICES ---"

    # Check if any Zabbix services are running.
    if systemctl list-units --type=service --state=running 'zabbix-*.service' | grep -q 'zabbix-'; then
        
        echo "One or more Zabbix services were detected as running. Restarting them now to apply potential updates..."

        # Restart all services matching the pattern 'zabbix-*.service'
        if sudo systemctl restart 'zabbix-*.service'; then
            echo "SUCCESS: Zabbix services (zabbix-*.service) successfully restarted."
        else
            echo "WARNING: Failed to restart one or more Zabbix services." >&2
        fi

    else
        echo "No Zabbix services detected as running (matching zabbix-*.service). Skipping restart."
    fi

    echo "--- ZABBIX SERVICE CHECK COMPLETE ---"
    # --- END ZABBIX RESTART LOGIC ---
    
    echo "--- SCRIPT FINISHED @ $(date) ---"
    
} 2>&1 | tee "$logfile" # Redirect both stdout and stderr to tee for logging
