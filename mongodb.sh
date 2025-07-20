#!/bin/bash

source ./common.sh
app_name=mongodb

check_root

# MongoDB Installation Script
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "MongoDB Repo File Copy"

# Install MongoDB
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "MongoDB Installation"

# Enable MongoDB Service
systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "MongoDB Service Enable"

# Start MongoDB Service
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "MongoDB Service Start"

# Update MongoDB Configuration
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "Edit mongod.conf file for remote access"

# Restart MongoDB Service to apply changes
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "MongoDB Service Restart"

print_time