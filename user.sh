#!/bin/bash

source ./common.sh
app_name="user"


# Check if the script is run as root
check_root

# Application Setup
app_setup

# NodeJS Setup
nodejs_setup

# Setup the application
system_setup

print_time


