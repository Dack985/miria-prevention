#!/bin/bash

# Mirai Malware Prevention and Remediation Script
# Author: [Your Name]

LOGFILE="/var/log/mirai_protection.log"

echo "=== Mirai Malware Protection Script ===" | tee -a $LOGFILE
echo "Logfile: $LOGFILE" | tee -a $LOGFILE

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE
}

# Function to check for infection
check_infection() {
    log_message "Checking for Mirai malware indicators..."

    # Known file paths used by Mirai
    MIRAI_PATHS=(
        "/home/landley/aboriginal/aboriginal/build/temp-armv7l/gcc-core/gcc/config/arm/lib1funcs.asm"
        "/home/landley/aboriginal/aboriginal/build/temp-armv7l/gcc-core/gcc/config/arm/ieee754-df.S"
    )

    # Check for files
    for path in "${MIRAI_PATHS[@]}"; do
        if [ -f "$path" ]; then
            log_message "Malware indicator found: $path"
            INFECTED=true
        fi
    done

    # Check for wget-based infection
    if grep -q "http://79.124.8.24/fetch.sh" /var/log/*; then
        log_message "Malware infection vector detected in logs: fetch.sh download"
        INFECTED=true
    fi

    if [ "$INFECTED" = true ]; then
        log_message "System appears to be infected!"
        return 0
    else
        log_message "No signs of Mirai malware detected."
        return 1
    fi
}

# Function to remove infection
remove_infection() {
    log_message "Attempting to remove malware..."

    # Remove known files
    for path in "${MIRAI_PATHS[@]}"; do
        if [ -f "$path" ]; then
            log_message "Deleting file: $path"
            rm -f "$path"
        fi
    done

    # Kill malicious processes
    pkill -f "wget.*fetch.sh"
    pkill -f "landley"

    # Remove any wget-downloaded scripts
    find /tmp -type f -name "fetch.sh" -exec rm -f {} \;

    log_message "Infection removal complete."
}

# Function to implement preventive measures
implement_prevention() {
    log_message "Implementing preventive measures..."

    # Restrict wget execution
    chmod 700 /usr/bin/wget
    log_message "Restricted wget execution for non-admin users."

    # Disable execution in the suspected directories
    if [ -d "/home/landley/aboriginal" ]; then
        chmod -R o-w /home/landley/aboriginal
        log_message "Secured /home/landley/aboriginal directory."
    fi

    # Add firewall rules to block malicious IPs
    MALICIOUS_IP="79.124.8.24"
    if ! iptables -L INPUT -v -n | grep -q "$MALICIOUS_IP"; then
        iptables -A INPUT -s "$MALICIOUS_IP" -j DROP
        log_message "Blocked malicious IP address: $MALICIOUS_IP"
    fi

    # Ensure TLS keep-alives are logged for monitoring
    if ! grep -q "LogLevel DEBUG" /etc/ssh/sshd_config; then
        echo "LogLevel DEBUG" >> /etc/ssh/sshd_config
        systemctl restart sshd
        log_message "Enabled SSH debugging for suspicious TLS keep-alives."
    fi

    log_message "Preventive measures implemented."
}

# Main execution flow
INFECTED=false

check_infection
if [ $? -eq 0 ]; then
    log_message "System infected! Proceeding with removal..."
    remove_infection
else
    log_message "System is clean."
fi

log_message "Applying preventive measures..."
implement_prevention

log_message "Mirai protection script completed successfully."
echo "Script execution complete. Check $LOGFILE for details."
