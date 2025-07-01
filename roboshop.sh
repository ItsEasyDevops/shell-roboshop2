#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0aa27df1889c9933e"
ZONE_ID="Z09260871ALCRUTIR75TM"
DOMAIN_NAME="easydevops.fun"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")


for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-09c813fb71547fc4f \
        --instance-type t2.micro \
        --security-group-ids sg-0aa27df1889c9933e \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test}]' --query "Instances[0].InstanceId" --output text)

    if [ $instance -ne "frontend" ]
    then
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
    else
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    fi

    echo "$instance instance created with IP Address: $INSTANCE_ID"
done

