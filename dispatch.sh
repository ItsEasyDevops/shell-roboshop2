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

# Install golang and dependencies
dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Golang Installation"

# Check if the roboshop user exists
id roboshop &>>$LOG_FILE

# Add roboshop user
if [ $? -ne 0 ];
then
    echo -e "$Y roboshop user does not exist, creating it now... $N" | tee -a $LOG_FILE
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop user creation"
else
    echo -e "$G roboshop user already exists, skipping creation... SKIPPING $N" | tee -a $LOG_FILE
fi

# Create application directory
mkdir -p $SCRIPT_DIR/app &>>$LOG_FILE
VALIDATE $? "Application directory creation"

# Download the dispatch service code
curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
VALIDATE $? "Dispatch service code download"

# Unzip the downloaded file to the application directory
cd /app &>>$LOG_FILE
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Dispatch service code extraction"

# Lets download the dependencies & build the software.
go mod init dispatch
go get &>>$LOG_FILE
go build &>>$LOG_FILE
VALIDATE $? "Dispatch service build"

# Copy the systemd service file to the appropriate directory
cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "Dispatch service systemd file copy"

# Reload the systemd daemon to recognize the new service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd daemon reload"

# Enable the dispatch service to start on boot
systemctl enable dispatch &>>$LOG_FILE
VALIDATE $? "Dispatch service enable"

# Start the dispatch service
systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Dispatch service start"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE