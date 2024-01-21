#!/bin/bash

# Define the software to check
SOFTWARE="jq"

# Check which package manager is available
if command -v apt-get &> /dev/null; then
	# Add dots to represent the checking progress
	for (( i=1; i<=20; i++ )); do
		echo -n "."
		sleep 0.1  # Adjust sleep duration as needed
	done
	# Use apt-get to check if the software is installed
	if ! dpkg -s $SOFTWARE &> /dev/null; then
		
		# Install the software using apt-get
		sudo apt-get -qq update
		sudo apt-get -qq install -y $SOFTWARE
		echo "$SOFTWARE was successfully installed"
	#else
		# The software is already installed
		#echo "$SOFTWARE is already installed"
	fi
	
elif command -v yum &> /dev/null; then
	# Add dots to represent the checking progress
	for (( i=1; i<=20; i++ )); do
		echo -n "."
		sleep 0.1  # Adjust sleep duration as needed
	done
	# Use yum to check if the software is installed
	if ! yum list installed $SOFTWARE &> /dev/null; then
		echo -n "."
		sleep 1
		# Install the software using yum
		sudo yum update -q
		sudo yum install -q -y $SOFTWARE
		echo "$SOFTWARE was successfully installed"
	#else
		# The software is already installed
		#echo "$SOFTWARE is already installed"
	fi

#else
	# Neither apt-get nor yum is available
	#echo "Neither apt-get nor yum is available"
fi


# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# Read IPs from the input file into an array
input_file=$1
ips=($(cat "$input_file"))

# Array to store request IDs
request_ids=()

# Use the first API to get the request_id for each IP
for ip in "${ips[@]}"; do
  # Indicate that the code is checking the first API
  echo "Checking first API for IP: $ip ..."

  api_result=$(curl -s -H "Accept: application/json" \
    "https://check-host.net/check-ping?host=$ip&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net")

  # Extract request_id from the API response
  request_id=$(echo "$api_result" | jq -r '.request_id')
  
  # Check if request_id is not empty before adding it to the array
  if [ -n "$request_id" ]; then
    request_ids+=("$request_id")
  fi
done

# Iterate through each request_id
for request_id in "${request_ids[@]}"; do
  # Indicate that the code is checking the second API
  echo "Checking second API for request_id: $request_id ..."

  # Use the second API to get the ping results for the request_id
  ping_request=$(curl -s -H "Accept: application/json" "https://check-host.net/check-result/$request_id")

  # Retry until the ping results are available
  while [[ $ping_request == *null* ]]; do
    ping_request=$(curl -s -H "Accept: application/json" "https://check-host.net/check-result/$request_id")
    sleep 1
  done


# Parse the JSON response and extract IPs
  #ips2=$(echo "$ping_request" | jq -r '.[][][] |.[2]')

# Output IPs with "TIMEOUT" separately
  timeout_ips=$(echo "$ping_request" | grep "TIMEOUT" | cut -d'"' -f6 | sort -u)
  echo $timeout_ips >> timeout_ips.txt
# Output IPs with "OK" separately
  ok_ips=$(echo "$ping_request" | grep -v "TIMEOUT" | cut -d'"' -f6 | sort -u)
  echo $ok_ips >> ok_ips.txt
done

