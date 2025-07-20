#!/bin/bash

source ./common.sh
app_name="redis"

check_root

# Disable Redis module
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Redis Module Disable"

# Download Redis 7 repo file   
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Redis 7 Module Enable"

# Install Redis
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Redis Installation"

# Update Redis Configuration
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "Edit redis.conf file for remote access & disable protected mode"

# Enable Redis Service
systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Redis Service Enable"  

# Start Redis Service
systemctl start redis &>>$LOG_FILE
VALIDATE $? "Redis Service Start"

print_time