#!/bin/bash

source ./common.sh
app_name="shipping"

check_root

echo "Please enter the root password for MySQL:" | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD


app_setup
maven_setup 
system_setup


# Install MySQL client
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "MySQL Client Installation"

# Check if shipping schema exists
echo -e "$Y Checking if shipping schema already exists... $N" | tee -a $LOG_FILE
mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE

if [ $? -ne 0 ]; then
    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    VALIDATE $? "Shipping Schema Load"

    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    VALIDATE $? "Shipping App User Creation"

    mysql -h mysql.easydevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Shipping Master Data Load"
else
    echo -e "$G Shipping schema already exists, skipping schema load... SKIPPING $N" | tee -a $LOG_FILE
fi

# Restart shipping service to apply changes
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Shipping Service Restart"

print_time
