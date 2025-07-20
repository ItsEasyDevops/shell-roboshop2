#!/bin/bash

source ./common.sh
app_name="catalogue"


# Check if the script is run as root
check_root

# Application Setup
app_setup

# NodeJS Setup
nodejs_setup

# Setup the application
system_setup


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

print_time


