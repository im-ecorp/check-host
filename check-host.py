import subprocess
import json
import time

# Check if the correct number of arguments is provided
import sys

if len(sys.argv) != 2:
    print("Usage: {} <input_file>".format(sys.argv[0]))
    sys.exit(1)

# Read IPs from the input file into a list
input_file = sys.argv[1]
with open(input_file, 'r') as file:
    ips = [ip.strip() for ip in file.readlines()]

# List to store request IDs
request_ids = []

# Use the first API to get the request_id for each IP
for ip in ips:
    # Indicate that the code is checking the first API
    print("Checking first API for IP:", ip, "...")

    api_result = subprocess.check_output([
        'curl',
        '-s',
        '-H', 'Accept: application/json',
        f'https://check-host.net/check-ping?host={ip}&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net'
    ], text=True)

    # Extract request_id from the API response
    request_id = json.loads(api_result).get('request_id')

    # Check if request_id is not empty before adding it to the list
    if request_id is not None:
        request_ids.append(request_id)

# Iterate through each request_id
for request_id in request_ids:
    # Indicate that the code is checking the second API
    print("Checking second API for request_id:", request_id, "...")

    # Use the second API to get the ping results for the request_id
    ping_request = subprocess.check_output([
        'curl',
        '-s',
        '-H', 'Accept: application/json',
        f'https://check-host.net/check-result/{request_id}'
    ], text=True)

    # Retry until the ping results are available
    while "null" in ping_request:
        ping_request = subprocess.check_output([
            'curl',
            '-s',
            '-H', 'Accept: application/json',
            f'https://check-host.net/check-result/{request_id}'
        ], text=True)
        time.sleep(1)

    # Output IPs with "TIMEOUT" separately
    timeout_ips = sorted(set(line.split('"')[5] for line in ping_request.splitlines() if "TIMEOUT" in line))
    with open("timeout_ips.txt", 'a') as timeout_file:
        timeout_file.write("\n".join(timeout_ips) + "\n")

    # Output IPs with "OK" separately
    ok_ips = sorted(set(line.split('"')[5] for line in ping_request.splitlines() if "TIMEOUT" not in line))
    with open("ok_ips.txt", 'a') as ok_file:
        ok_file.write("\n".join(ok_ips) + "\n")
