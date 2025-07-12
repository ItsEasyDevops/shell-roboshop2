#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[32m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER
echo -e "Script Name: $SCRIPT_NAME executing at $(date)" | tee -a $LOG_FILE

# To check if the user has root privileges
# If the user ID is not 0, it means the script is not being run as root
# If the user ID is 0, it means the script is being run as root
if [ $USERID -ne 0 ];
then
    echo -e "$R ERROR: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 # Giving other than 0 to 127 for error
else
    echo -e "$G You are running this script with root access $N" | tee -a $LOG_FILE
fi

# VALIDATE function to check the exit status of the last command executed
# $1 - Exit status of the last command
# $2 - Name of the service being installed
# Usage: VALIDATE $? <service_name>
# Example: VALIDATE $? mongodb
# This function will print a success or failure message based on the exit status
# and log it to the specified log file.
VALIDATE() {
    if [ $1 -eq 0 ]; 
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1 # Giving other than 0 to 127 for error
    fi
}

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
rm -rf $SCRIPT_DIR/usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing the default content"

# Download the frontend content from S3 bucket
curl -o $SCRIPT_DIR/tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend content"

cd $SCRIPT_DIR/usr/share/nginx/html
VALIDATE $? "Changing directory to /usr/share/nginx/html"

# Unzip the downloaded content
unzip $SCRIPT_DIR/tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend content"

# Removing the nginx default configuration file
rm -rf $SCRIPT_DIR/etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default nginx configuration file"

# Copy the custom nginx configuration file
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying custom nginx configuration file"

# Restart Nginx Service
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx Service"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE



