#!/bin/bash

# Script to list FortiAnalyzer AMIs (PAYG and BYOL) across all AWS regions or a specific region
# Usage: ./list_faz_amis.sh [version] [region]
# Default version: 7.6
# Default region: all regions

FAZ_VERSION="${1:-7.6}"
SPECIFIC_REGION="$2"

if [ -n "$SPECIFIC_REGION" ]; then
    echo "Listing FortiAnalyzer PAYG and BYOL AMIs for version $FAZ_VERSION in region $SPECIFIC_REGION..."
    regions="$SPECIFIC_REGION"
else
    echo "Listing FortiAnalyzer PAYG and BYOL AMIs for version $FAZ_VERSION across all AWS regions..."
    # Get all AWS regions
    regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
fi

echo "=================================================================================="

# Loop through each region
for region in $regions; do
    echo ""
    echo "Region: $region"
    echo "----------------"

    # List FortiAnalyzer PAYG AMIs in this region
    echo "PAYG:"
    payg_output=$(aws ec2 describe-images \
        --owners aws-marketplace \
        --filters \
            "Name=name,Values=FortiAnalyzer-VM64-AWSONDEMAND*$FAZ_VERSION*" \
            "Name=virtualization-type,Values=hvm" \
            "Name=architecture,Values=x86_64" \
            "Name=state,Values=available" \
        --query 'Images[*].{ID:ImageId,"Description":Name}' \
        --output text \
        --region $region 2>/dev/null)

    if [ -n "$payg_output" ]; then
        echo "$payg_output"
    else
        echo "No PAYG AMIs found for version $FAZ_VERSION in $region"
    fi

    echo ""
    echo "BYOL:"
    # List FortiAnalyzer BYOL AMIs in this region
    byol_output=$(aws ec2 describe-images \
        --owners aws-marketplace \
        --filters \
            "Name=name,Values=FortiAnalyzer-VM64-AWS *$FAZ_VERSION*" \
            "Name=virtualization-type,Values=hvm" \
            "Name=architecture,Values=x86_64" \
            "Name=state,Values=available" \
        --query 'Images[*].{ID:ImageId,"Description":Name}' \
        --output text \
        --region $region 2>/dev/null)

    if [ -n "$byol_output" ]; then
        echo "$byol_output"
    else
        echo "No BYOL AMIs found for version $FAZ_VERSION in $region"
    fi
done

echo ""
echo "=================================================================================="
echo "Script completed."
