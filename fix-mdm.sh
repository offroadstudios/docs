#!/bin/bash
# MDM bypass script - run from Recovery Mode Terminal
# WARNING: Only use on your legally owned device.

# Mount data volume
diskutil apfs mount "Macintosh HD - Data"

# Remove configuration profiles
rm -rf /Volumes/Macintosh\ HD\ -\ Data/var/db/ConfigurationProfiles/*

# Skip Setup Assistant
touch /Volumes/Macintosh\ HD\ -\ Data/private/var/db/.AppleSetupDone

# Remove cloud config cache
rm -f /Volumes/Macintosh\ HD\ -\ Data/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
rm -f /Volumes/Macintosh\ HD\ -\ Data/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
rm -f /Volumes/Macintosh\ HD\ -\ Data/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound

# Block MDM servers via hosts file
cat <<EOF >> /Volumes/Macintosh\ HD\ -\ Data/private/etc/hosts
127.0.0.1 mdmenrollment.apple.com
127.0.0.1 deviceenrollment.apple.com
127.0.0.1 iprofiles.apple.com
127.0.0.1 configuration.apple.com
127.0.0.1 gdmf.apple.com
127.0.0.1 albert.apple.com
127.0.0.1 acmdm.apple.com
EOF

echo "Done. Reboot without internet connection."
