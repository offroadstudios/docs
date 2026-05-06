#!/bin/bash
# MDM post-boot cleanup script
# Run from Terminal on the desktop (not Recovery Mode):
#   curl -L https://raw.githubusercontent.com/offroadstudios/docs/main/fix-mdm-postboot.sh | sudo bash
# WARNING: Only use on your legally owned device.

set +e

echo "==> Disabling MDM client daemons..."
launchctl disable system/com.apple.ManagedClient
launchctl disable system/com.apple.ManagedClientAgent.enrollagent
launchctl disable system/com.apple.mdmclient.daemon
launchctl disable system/com.apple.mdmclient.agent

echo "==> Stopping any running MDM processes..."
launchctl bootout system/com.apple.ManagedClient 2>/dev/null
launchctl bootout system/com.apple.mdmclient.daemon 2>/dev/null
killall ManagedClient 2>/dev/null
killall mdmclient 2>/dev/null

echo "==> Removing installed/pending profiles..."
profiles -P 2>/dev/null
profiles remove -all 2>/dev/null
profiles -D 2>/dev/null

echo "==> Wiping configuration profile cache..."
rm -rf /var/db/ConfigurationProfiles/* 2>/dev/null
rm -rf /private/var/db/ConfigurationProfiles/* 2>/dev/null
mkdir -p /var/db/ConfigurationProfiles/Settings
touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled

echo "==> Restoring clean /etc/hosts with MDM blocks..."
cat > /etc/hosts <<'EOF'
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.
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

echo "==> Flushing DNS cache..."
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "==> Dismissing notifications..."
killall NotificationCenter 2>/dev/null
killall usernoted 2>/dev/null

echo ""
echo "==> Done!"
echo "Now disconnect Wi-Fi/Ethernet, then run: sudo reboot"
