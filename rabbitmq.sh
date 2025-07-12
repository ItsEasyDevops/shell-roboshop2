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

# RabbitMQ Repository setup
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/ &>>$LOG_FILE
VALIDATE $? "RabbitMQ Repo Copy"

# Install rabbitmq-server
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "RabbitMQ Installation"

# Enable RabbitMQ service
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "RabbitMQ Enable"

# Start RabbitMQ service
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "RabbitMQ Start"

# Add roboshop user to RabbitMQ
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "RabbitMQ User Creation"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "RabbitMQ User Permissions"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE