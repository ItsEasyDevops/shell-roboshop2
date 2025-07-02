#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0aa27df1889c9933e"
ZONE_ID="Z09260871ALCRUTIR75TM"
DOMAIN_NAME="easydevops.fun"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")


for instance in ${INSTANCES[@]}
do
    if [ "$instance" = "frontend" ]; 
    then
        tag_value="frontend"
    else
        tag_value="$instance"
    fi

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-09c813fb71547fc4f \
        --instance-type t2.micro \
        --security-group-ids sg-0aa27df1889c9933e \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$tag_value}]' --query "Instances[0].InstanceId" --output text)

    if [ $instance = "frontend" ];
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    echo "$instance instance created with IP Address: $IP"

    if [ $instance = "frontend" ];
    then
        record_name=$DOMAIN_NAME
    else
        record_name=$instance.$DOMAIN_NAME
    fi

    aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{
        "Comment": "Creating record set for '$instance'",
        "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
        "Name": "'$record_name'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [{
            "Value": "'$IP'"
          }]
        }
        }]
    }'    
  
done

