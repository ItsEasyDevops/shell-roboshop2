#!/bin/bash

source ./common.sh
app_name="frontend"

check_root

# Disable Nginx module
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Nginx Module Disable"

# Download Nginx 1.24 repo file
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Nginx 1.24 Module Enable"

# Install Nginx
dnf install nginx -y
VALIDATE $? "Nginx Installation"

# Create roboshop user
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Nginx Service Enable"

# Start Nginx Service
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Nginx Service Start"

# Remove the default content that web server is serving.
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing the default content"

# Download the frontend content from S3 bucket
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend content"

cd /usr/share/nginx/html
VALIDATE $? "Changing directory to /usr/share/nginx/html"

# Unzip the downloaded content
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend content"

# Removing the nginx default configuration file
rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default nginx configuration file"

# Copy the custom nginx configuration file
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying custom nginx configuration file"

# Restart Nginx Service
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx Service"

print_time



