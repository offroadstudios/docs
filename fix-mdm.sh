#!/bin/bash
# MDM bypass script - run from Recovery Mode Terminal
#   curl -L https://raw.githubusercontent.com/offroadstudios/docs/main/fix-mdm.sh | bash
# WARNING: Only use on your legally owned device.

set +e

DATA_NAME="Macintosh HD - Data"
DATA_MOUNT=""

echo "==> Locating Data volume..."

# Try mounting by name (works in newer Recovery)
diskutil mount "$DATA_NAME" 2>/dev/null

# Find mount point
if [ -d "/Volumes/$DATA_NAME" ]; then
    DATA_MOUNT="/Volumes/$DATA_NAME"
fi

# If not mounted, try to find the Data volume identifier from diskutil apfs list
if [ -z "$DATA_MOUNT" ]; then
    echo "==> Mount by name failed. Searching APFS volumes..."
    DATA_ID=$(diskutil apfs list | awk '/Name:.*Data/{getline; getline; print}' | grep -oE 'disk[0-9]+s[0-9]+' | head -n1)
    if [ -z "$DATA_ID" ]; then
        # Alternative parse
        DATA_ID=$(diskutil apfs list | grep -B1 "Data)" | grep -oE 'disk[0-9]+s[0-9]+' | head -n1)
    fi
    if [ -n "$DATA_ID" ]; then
        echo "==> Found Data volume: $DATA_ID"
        echo "==> If FileVault-locked, you'll be prompted for password..."
        diskutil apfs unlockVolume "$DATA_ID" 2>/dev/null
        diskutil mount "$DATA_ID" 2>/dev/null
    fi
fi

# Re-check mount
for vol in /Volumes/*; do
    if [ -d "$vol/private/var/db" ]; then
        DATA_MOUNT="$vol"
        break
    fi
done

if [ -z "$DATA_MOUNT" ] || [ ! -d "$DATA_MOUNT/private/var/db" ]; then
    echo ""
    echo "ERROR: Could not mount Data volume."
    echo "Run these commands manually:"
    echo "  diskutil list"
    echo "  diskutil apfs list"
    echo "  diskutil apfs unlockVolume <diskXsY>   # if FileVault encrypted"
    echo "  diskutil mount <diskXsY>"
    echo "Then re-run this script."
    exit 1
fi

echo "==> Data volume mounted at: $DATA_MOUNT"

echo "==> Wiping configuration profile cache..."
rm -rf "$DATA_MOUNT/var/db/ConfigurationProfiles/"* 2>/dev/null
rm -rf "$DATA_MOUNT/private/var/db/ConfigurationProfiles/"* 2>/dev/null

echo "==> Creating cloud config 'not found' marker..."
mkdir -p "$DATA_MOUNT/var/db/ConfigurationProfiles/Settings"
mkdir -p "$DATA_MOUNT/private/var/db/ConfigurationProfiles/Settings"
touch "$DATA_MOUNT/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"
touch "$DATA_MOUNT/private/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"

echo "==> Skipping Setup Assistant..."
mkdir -p "$DATA_MOUNT/private/var/db"
touch "$DATA_MOUNT/private/var/db/.AppleSetupDone"

echo "==> Writing clean /etc/hosts with MDM blocks..."
mkdir -p "$DATA_MOUNT/private/etc"
cat > "$DATA_MOUNT/private/etc/hosts" <<'EOF'
##
# Host Database
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost

# MDM/DEP blocks
127.0.0.1 mdmenrollment.apple.com
127.0.0.1 deviceenrollment.apple.com
127.0.0.1 iprofiles.apple.com
127.0.0.1 configuration.apple.com
127.0.0.1 gdmf.apple.com
127.0.0.1 albert.apple.com
127.0.0.1 acmdm.apple.com
127.0.0.1 humb.apple.com
127.0.0.1 static.ips.apple.com
127.0.0.1 tbsc.apple.com
EOF

echo ""
echo "==> Done!"
echo "Disconnect Wi-Fi/Ethernet, then run: reboot"
