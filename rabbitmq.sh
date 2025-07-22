#!/bin/bash

source ./common.sh
app_name="rabbitmq"

check_root

echo "Please enter the root password for RABBITMQ:" | tee -a $LOG_FILE
read -s RABBITMQ_ROOT_PASSWORD


# RabbitMQ Repository setup
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
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

# Check if the roboshop user exists
rabbitmqctl list_users | grep -w roboshop &>>$LOG_FILE

if [ $? -ne 0 ];
then
    # Add roboshop user to RabbitMQ
    rabbitmqctl add_user roboshop $RABBITMQ_ROOT_PASSWORD &>>$LOG_FILE
    VALIDATE $? "RabbitMQ User Creation"

    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
    VALIDATE $? "RabbitMQ User Permissions"
else
    echo -e "$G roboshop user already exists, skipping creation... SKIPPING $N" | tee -a $LOG_FILE
fi

print_time