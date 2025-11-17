#!/bin/bash

# --- 1. CONFIGURATION (EDIT THESE) ---
OLD_CLUSTER_NET="10.123.2.0/24" 
NEW_CLUSTER_NET="10.123.1.0/24" 
CONFIG_FILE="/etc/pve/ceph.conf"

echo "Starting Ceph Cluster Network Migration Script on $(hostname)..."
echo "Old Cluster Network: $OLD_CLUSTER_NET"
echo "New Cluster Network: $NEW_CLUSTER_NET"

# --- 2. STEP 1: ADD BOTH SUBNETS TO CEPH.CONF (Using awk for robustness) ---
echo -e "\n--- 1. Updating $CONFIG_FILE to include both OLD and NEW cluster subnets ---"

if grep -q "cluster_network.*$NEW_CLUSTER_NET" $CONFIG_FILE; then
    echo "New cluster subnet is already configured in ceph.conf. Skipping update."
else
    # Use awk to find the line and append the new network.
    awk -v old="$OLD_CLUSTER_NET" -v new="$NEW_CLUSTER_NET" \
        '{
            if ($1 == "cluster_network") {
                # Append the new network to the existing line
                $0 = $0 ", " new
            }
            print
        }' $CONFIG_FILE > temp_ceph.conf && mv temp_ceph.conf $CONFIG_FILE

    echo "Configuration updated. Checking changes:"
    grep "cluster_network" $CONFIG_FILE
fi

# --- 3. STEP 2: RESTART OSDs ON THIS NODE ---
echo -e "\n--- 2. Restarting Ceph OSDs on this node: $(hostname) ---"
systemctl restart ceph-osd.target

echo -e "\n--- ⚠️ ACTION REQUIRED: OSD Restart Done on $(hostname) ---"
echo "1. Verify that all OSDs on this node are UP and IN."
echo "2. Run 'ceph -s' on any node to ensure cluster health is **HEALTH_OK** (or better)."
echo "   You must ensure stability before running the script on the next node."
echo "Press [Enter] to continue with the next phase (Cleanup)..."
read

# --- 4. STEP 3: FINAL CLEANUP (REMOVE OLD SUBNET) ---
echo -e "\n--- 3. Final Cleanup: Removing OLD cluster subnet ($OLD_CLUSTER_NET) from $CONFIG_FILE ---"

if grep -q "cluster_network.*$OLD_CLUSTER_NET" $CONFIG_FILE; then
    awk -v old_net="$OLD_CLUSTER_NET" -v new_net="$NEW_CLUSTER_NET" \
        '{
            if ($1 == "cluster_network") {
                # Remove the old network (handles 'OLD, NEW', 'NEW, OLD', or 'OLD' by itself)
                gsub(old_net ", ", "", $0);
                gsub(", " old_net, "", $0);
                # This only replaces if the old_net is still present and the only item
                if ($0 ~ old_net) {
                    gsub(old_net, new_net, $0); 
                }
            }
            print
        }' $CONFIG_FILE > temp_ceph.conf && mv temp_ceph.conf $CONFIG_FILE

    echo "Old cluster network references removed. Checking final configuration:"
    grep "cluster_network" $CONFIG_FILE
else
    echo "Old cluster network ($OLD_CLUSTER_NET) appears to be removed. Skipping cleanup."
fi

# Final Restart of Ceph Services
echo -e "\n--- 4. Final Restart of all Ceph services on this node for full binding ---"
systemctl restart ceph-mon.target ceph-mgr.target ceph-osd.target

# --- 5. OPTIONAL: Final Host Reboot ---
echo -e "\n--- 5. 🚨 HOST REBOOT RECOMMENDED ---"
echo "Due to system-level network changes, a full host reboot is highly recommended"
echo "to ensure all components and the kernel fully bind to the new cluster network."
echo "Ensure 'ceph -s' is HEALTH_OK before rebooting."
echo "Do you wish to reboot this node now? (yes/no)"
read -r REBOOT_CONFIRM

if [[ "$REBOOT_CONFIRM" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    echo "Rebooting in 10 seconds..."
    sleep 10
    reboot
else
    echo "Reboot skipped. You must perform the reboot manually later for full stability."
fi
