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

# Install Python3 and dependencies
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Python3 and dependencies installation"


# Create a system user for roboshop with no login shell and home directory
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Roboshop user creation"


mkdir -p $SCRIPT_DIR/app

# Download the payment service code
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Payment service code download" 

# Unzip the downloaded file to the application directory
cd $SCRIPT_DIR/app     &>>$LOG_FILE  
unzip $SCRIPT_DIR/tmp/payment.zip  &>>$LOG_FILE          
VALIDATE $? "Payment service code extraction"

# Install the required Python dependencies
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Payment service dependencies installation"

# Copy the systemd service file to the appropriate directory
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Payment service systemd file copy"

# Reload the systemd daemon to recognize the new service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd daemon reload"

# Start the payment service
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Payment service enable"

# Start the payment service
systemctl start payment &>>$LOG_FILE
VALIDATE $? "Payment service start"


END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE