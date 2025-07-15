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

# NodeJS Installation Script
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Module Disable"

# Download NodeJS 20 repo file
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "NodeJS 20 Module Enable"

# Install NodeJS
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Installation"

# Create roboshop user
# This user will be used to run the application
# It is a system user, meaning it does not have a home directory or shell access
# The user is created with no login shell and no home directory
# This is a security measure to prevent unauthorized access
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ];
then
    echo -e "$Y roboshop user does not exist, creating it now... $N" | tee -a $LOG_FILE
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop user creation"
else
    echo -e "$G roboshop user already exists, skipping creation... SKIPPING $N" | tee -a $LOG_FILE
fi

# Create application directory
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Application directory creation"

# Download the application code
# The application code is downloaded from a remote server
# The code is downloaded as a zip file and extracted to the /app directory
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Catalogue application code download"


rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Catalogue application code download and extraction"

# Install NodeJS dependencies
npm install &&>>$LOG_FILE
VALIDATE $? "Catalogue application dependencies installation"

# Copy the systemd service file for the catalogue service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Catalogue service file copy"

# Reload systemd to recognize the new service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd daemon reload"

# Start the catalogue service
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Catalogue service enable"

# Start the catalogue service
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Catalogue service start"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "MongoDB repo file copy"

# Install MongoDB client
# The MongoDB client is a command-line interface for interacting with MongoDB databases
# It allows you to run queries, manage databases, and perform administrative tasks
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "MongoDB client installation"

STATUS=$(mongosh --host mongodb.easydevops.fun --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $STATUS -lt 0 ];
then
    echo -e "$Y Catalogue database does not exist, importing it now... $N" | tee -a $LOG_FILE
    # Import master data into MongoDB
    mongosh --host mongodb.easydevops.fun < /app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "MongoDB master data import"
else
    echo -e "$G Catalogue database already exists, skipping creation... SKIPPING $N" | tee -a $LOG_FILE
fi

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE


