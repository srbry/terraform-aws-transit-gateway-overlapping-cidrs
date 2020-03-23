#!/usr/bin/env bash

set -euo pipefail

cd "${HOME}"
sudo yum -y update aws*
sudo yum -y install aws-cli
sudo yum -y install sipcalc --enablerepo=epel
sudo sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
sudo service network restart
chmod a+x /home/ec2-user/health_monitor.sh
# TODO: FIX Logging for first run (works fine from reboot), convert to systemd?
echo '@reboot /home/ec2-user/health_monitor.sh >> /tmp/health_monitor.log' | crontab
at now -f /home/ec2-user/health_monitor.sh >> /tmp/health_monitor.log 2>&1
chmod a+x /home/ec2-user/tgw_monitor.sh
# TODO: FIX Logging for first run (works fine from reboot), convert to systemd?
(crontab -l ; echo '@reboot /home/ec2-user/tgw_monitor.sh >> /tmp/tgw_monitor.log') | crontab
at now -f /home/ec2-user/tgw_monitor.sh >> /tmp/tgw_monitor.log 2>&1
