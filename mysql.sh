#!/bin/bash

source ./common.sh
app_name="mysql"

check_root

echo "Please enter the root password for MySQL:"
read -s MYSQL_ROOT_PASSWORD


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

print_time