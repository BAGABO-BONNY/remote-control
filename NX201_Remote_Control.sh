#!/bin/bash

# Project Details
# Student Name: Bagabo Bonny
# Student Code: s11
# Program Code: NX201
# Class Code: RW-CODING-Academy-1
# Lecturer: Celestin

# Utility functions
function install_if_needed {
    # Function to check and install necessary applications
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. Installing..."
        sudo apt-get install -y $1
    else
        echo "$1 is already installed."
    fi
}

# Install necessary tools
install_if_needed "sshpass"
install_if_needed "tor"
install_if_needed "nmap"
install_if_needed "whois"
install_if_needed "torsocks"

# Start Tor service
echo "Starting Tor service..."
sudo systemctl start tor

# Function to check anonymity
function check_anonymity {
    echo "Checking anonymity..."
    if ! torsocks curl -s https://check.torproject.org | grep -q "Congratulations"; then
        echo "Anonymity check failed. Not connected via Tor. Exiting..."
        exit 1
    else
        echo "Anonymity confirmed."
        country=$(torsocks curl -s https://ipinfo.io/country)
        echo "Spoofed location: $country"
    fi
}

# Checking network anonymity
check_anonymity

# User input for target address
echo "Enter the IP address or domain to scan:"
read target_address

# Connecting to remote server and executing commands
REMOTE_USER="remote_user"
REMOTE_IP="remote_server_ip"
REMOTE_PASS="remote_password"

# Automatically connecting and executing commands on the remote server via SSH over Tor
function connect_and_execute {
    echo "Connecting to remote server $REMOTE_IP through Tor..."
    torsocks sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" << EOF
        echo "Connected to server at country: \$(torsocks curl -s https://ipinfo.io/country)"
        echo "Server IP: \$(torsocks curl -s https://ipinfo.io/ip)"
        echo "Server Uptime: \$(uptime -p)"
EOF
}

# Execute remote commands
connect_and_execute

# Locally fetch WHOIS information
echo "Fetching WHOIS information for $target_address..."
torsocks whois $target_address > whois_$target_address.txt
echo "WHOIS data saved to whois_$target_address.txt."

# Check Nmap availability and run the scan
if command -v nmap &> /dev/null; then
    echo "Running Nmap scan on $target_address through Tor..."
    torsocks nmap -sS $target_address -oN nmap_$target_address.txt

    # Check if Nmap output is empty
    if [ ! -s nmap_$target_address.txt ]; then
        echo "Warning: Nmap output is empty. Please check if the target is reachable or if there are network restrictions."
    else
        echo "Nmap scan completed. Results saved to nmap_$target_address.txt."
    fi
else
    echo "Nmap is not available. Please install it."
    exit 1
fi

# Create log for audit purposes
echo "Creating audit log..."
echo "Target: $target_address" > audit_log.txt
echo "Scan Date: $(date)" >> audit_log.txt
echo "Whois and Nmap data collected." >> audit_log.txt

# Display completion message
echo "Automation completed successfully. Data and log files are saved locally."
