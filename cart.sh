#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
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
    exit 1 #Giving other that 0 to 127 for error
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
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1 #Giving other that 0 to 127 for error
    fi
}

# Disable NodeJS module
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Module Disable"

# Download NodeJS 20 repo file
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "NodeJS 20 Module Enable"

# Install NodeJS
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Installation"

# Create roboshop user
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Roboshop User Creation"

# Create application directory
mkdir -p /app

# Download Cart Application
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Download Cart Application"

# Extract Cart Application
cd $SCRIPT_DIR/app
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzip Cart Application"

# Download NodeJS dependencies
npm install &>>$LOG_FILE
VALIDATE $? "NPM Install Cart Application"

# Configure Cart Application
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Copy Cart Service File"

# Reload Systemd Daemon
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reload Systemd Daemon"

# Start Cart Service
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Cart Service Enable"

# Start Cart Service
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Cart Service Start"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE

