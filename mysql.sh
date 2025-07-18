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

echo "Pleaes enter the root password for MySQL:"
read -s MYSQL_ROOT_PASSWORD


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

# Install MySQL
dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "MySQL Installation"

# Enable MySQL service
systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "MySQL Enable"

# Start MySQL service
systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "MySQL Start"

# Set MySQL root password
mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$LOG_FILE
VALIDATE $? "MySQL Secure Installation"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE