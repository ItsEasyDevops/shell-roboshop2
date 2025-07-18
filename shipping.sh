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
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G You are running this script with root access $N" | tee -a $LOG_FILE
fi

echo "Please enter the root password for MySQL:" | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD

VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# Install Maven
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Maven Installation"

# Add roboshop user if not exists
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo -e "$Y roboshop user does not exist, creating it now... $N" | tee -a $LOG_FILE
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop user creation"
else
    echo -e "$G roboshop user already exists, skipping creation... SKIPPING $N" | tee -a $LOG_FILE
fi

# Create application directory
mkdir -p /app &>>$LOG_FILE

# Download the shipping service code
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Shipping Code Download"

# Clean app directory and unzip
rm -rf /app/* &>>$LOG_FILE
cd /app
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Shipping Code Extraction"

# Maven build
mvn clean package &>>$LOG_FILE
VALIDATE $? "Maven Package Creation"

# Move jar file
mv /app/target/shipping-1.0.jar /app/shipping.jar

# Copy service file
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Shipping Service Copy"

# Reload systemd
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Systemd Daemon Reload"

# Enable and start shipping service
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Enable"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Start"

# Install MySQL client
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "MySQL Client Installation"

# Check if shipping schema exists
echo -e "$Y Checking if shipping schema already exists... $N" | tee -a $LOG_FILE
mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE

if [ $? -ne 0 ]; then
    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < $SCRIPT_DIR/app/db/schema.sql &>>$LOG_FILE
    VALIDATE $? "Shipping Schema Load"

    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < $SCRIPT_DIR/app/db/app-user.sql &>>$LOG_FILE
    VALIDATE $? "Shipping App User Creation"

    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < $SCRIPT_DIR/app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Shipping Master Data Load"
else
    echo -e "$G Shipping schema already exists, skipping schema load... SKIPPING $N" | tee -a $LOG_FILE
fi

# Restart shipping service to apply changes
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Restart"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script executed in $EXECUTION_TIME seconds $N" | tee -a $LOG_FILE
