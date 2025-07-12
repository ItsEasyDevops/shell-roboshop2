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
SCRIPT_DIR=$pwd

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

# Enable NodeJS 20 repo file
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "NodeJS 20 Module Enable"

# Install NodeJS
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Installation"

# Create application user - roboshop
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop    &>>$LOG_FILE
VALIDATE $? "Roboshop User Creation"

mkdir /app &>>$LOG_FILE
VALIDATE $? "Application Directory Creation"

# Download the user application code
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "User Application Download"  

# Unzip the user application code
cd $SCRIPT_DIR/app 
unzip $SCRIPT_DIR/tmp/user.zip &>>$LOG_FILE
VALIDATE $? "User Application Unzip"

# Install NodeJS dependencies
npm install &>>$LOG_FILE
VALIDATE $? "User Application Dependencies Installation"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "User Service File Copy"

# Reload systemd to recognize the new service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd Daemon Reload"

# Enable User Service
systemctl enable user &>>$LOG_FILE
VALIDATE $? "User Service Enable"

# Start User Service
systemctl start user &>>$LOG_FILE
VALIDATE $? "User Service Start"


END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE
