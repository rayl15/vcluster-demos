#!/bin/bash

VCLUSTER_NAME=$1
HOSTED_ZONE_ID=$2
TARGET_DOMAIN=$3
HOSTCLUSTERTYPE=$4

# The domain
DOMAIN="$VCLUSTER_NAME.arc-saas.net"


# Function to create DNS record in Route 53
create_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    local ttl=300

    cat > change-batch.json << EOF
{
    "Comment": "Creating DNS record for $name",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$DOMAIN",
                "Type": "CNAME",
                "TTL": $ttl,
                "ResourceRecords": [
                    {
                        "Value": "$content"
                    }
                ]
            }
        }
    ]
}
EOF

    response=$(aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://change-batch.json)

    if echo $response | grep -q '"ChangeInfo": {"Status": "PENDING"'; then
        echo "$type record created successfully for $name."
    else
        echo "Failed to create $type record for $name."
        echo "Response: $response"
    fi

    rm change-batch.json
}

# Choose DNS record type based on cluster type
case $HOSTCLUSTERTYPE in
    eks)
        create_dns_record "CNAME" "$DOMAIN" "$TARGET_DOMAIN" 300
        ;;
    gke)
        create_dns_record "A" "$DOMAIN" "$TARGET_DOMAIN" 300
        ;;
    aks)
        # Placeholder for AKS, adjust as needed
        echo "AKS configuration not implemented yet."
        ;;
    *)
        echo "Unsupported HOSTCLUSTERTYPE: $HOSTCLUSTERTYPE"
        ;;
esac
