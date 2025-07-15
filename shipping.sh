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

# Disable Maven module
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Maven Installation"

# Add roboshop user
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
mkdir -p $SCRIPT_DIR/app &>>$LOG_FILE

# Download the shipping service code
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip    &>>$LOG_FILE
VALIDATE $? "Shipping Code Download"

# Unzip the downloaded code
rm -rf $SCRIPT_DIR/app/* &>>$LOG_FILE
cd $SCRIPT_DIR/app 
unzip /tmp/shipping.zip

# Mvn clean package
mvn clean package   &>>$LOG_FILE
VALIDATE $? "Maven Package Creation"

# Move the jar file to the app directory
mv $SCRIPT_DIR/app/target/shipping-1.0.jar $SCRIPT_DIR/app/shipping.jar


cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Shipping Service Copy"

# systemctl daemon-reload
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd Daemon Reload"

# Enable the shipping service
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Enable"

# Start the shipping service
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Start"

# We need to load the schema. To load schema we need to install mysql client.
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "MySQL Client Installation"

# Check if the shipping schema already exists'
echo -e "$Y Checking if shipping schema already exists... $N" | tee -a $LOG_FILE
mysql -h mysql.easydevops.fun -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE

if [ $? -ne 0 ];
then
    # Load the shipping schema
    mysql -h mysql.easydevops.fun -uroot -pRoboShop@1 < /app/db/schema.sql  &>>$LOG_FILE
    VALIDATE $? "Shipping Schema Load"

    # Create the application user for shipping
    mysql -h mysql.easydevops.fun -uroot -pRoboShop@1 < /app/db/app-user.sql    &>>$LOG_FILE
    VALIDATE $? "Shipping App User Creation"

    # Load the master data for shipping
    mysql -h mysql.easydevops.fun -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Shipping Master Data Load"
else
    echo -e "$G Shipping schema already exists, skipping schema load... SKIPPING $N" | tee -a $LOG_FILE
fi  

# Restart the shipping service to apply changes
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Restart"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE