#!/bin/bash

# 1. Install required tools (only if not already installed)
for svcs in git perl cpanminus sshpass whois geoip-bin tor nmap; do
    if ! dpkg -l | grep -q $svcs; then
        sudo apt install -y $svcs
    else
        echo "$svcs already installed"
    fi
done

# 2. Install Nipe (Tor routing tool) – only clone if not exists
if [ ! -d "~/nipe" ]; then
    git clone https://github.com/htrgouvea/nipe ~/nipe
    cd ~/nipe
    sudo cpanm --installdeps .
else
    cd ~/nipe
fi

# 3. Install Perl dependencies
sudo cpan install Switch JSON LWP::UserAgent Config::Simple

# 4. Install Nipe itself
sudo perl nipe.pl install

# 5. Start and verify anonymity
sudo perl nipe.pl restart
sudo perl nipe.pl status

# Check your current IP and location (should show Tor exit node)
curl ifconfig.co
curl ifconfig.co/country
geoiplookup $(curl -s ifconfig.co)

# Change directory back to current working directory
cd /home/kali/CCK4250916/NR/Project

# User to input URL/Address to SSH into and store as a variable
read -p "Please specify a IP Address to SSH into: " inputIP

# Configuration
remoteIP="$inputIP"
sshUSER="tc"          # change if you use another user

# Connect & Scan open ports on the remote server
echo "Scanning open ports on $remoteIP"
openPORTS=$(sshpass -p "tc" ssh "$sshUSER@$remoteIP" "ss -ltn | awk '{print \$4}' | grep -oE '[0-9]+$' | sort | uniq")
echo "Remote Server's Open Ports: " $openPORTS

# Get the public IP of the remote server 
publicIP=$(sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "curl -s ifconfig.io")
echo "Remote Server's Public IP: " $publicIP

# 2. Get country from the public IP we just fetched
countryIP=$(geoiplookup $publicIP)
echo $countryIP

# 3. Get uptime of remote server
remoteUPTIME=$(sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "uptime -p")
echo "Remote Server's Uptime: " $remoteUPTIME

# Generating log file in /var/www/html folder
function getLOGFILE()
{
	logFILE="/var/www/html/project.log"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "New Scan Started: $(TZ='Asia/Singapore' date)" | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "Target IP: $inputIP" | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo 'Local user & password: tc:tc' | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "Remote Server Open Ports: $openPORTS" | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "Remote Server Public IP: $publicIP" | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo $countryIP | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "Remote Server Uptime: $remoteUPTIME" | tee -a $logFILE"
	sshpass -p "tc" ssh -o StrictHostKeyChecking=no $sshUSER@$remoteIP "echo "===================================================================" | tee -a $logFILE"
}
getLOGFILE


# Download log file generated to local machine working directory
curl -O http://$inputIP/project.log

