# Check if the correct number of arguments is provided
if ($args.Length -ne 1) {
  Write-Host "Usage: $($MyInvocation.MyCommand.Name) <input_file>"
  exit 1
}

# Read IPs from the input file into an array
$inputFile = $args[0]
$ips = Select-String -Path $inputFile -Pattern "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | ForEach-Object { $_.Matches.Value }

# Array to store request IDs
$requestIds = @()

# Use the first API to get the request_id for each IP
foreach ($ip in $ips) {
  # Indicate that the code is checking the first API
  Write-Host "Checking first API for IP: $ip ..."

  #$apiResult = Invoke-RestMethod -Uri "https://check-host.net/check-ping?host=$ip&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net"
  $apiResult =curl -s -H "Accept: application/json" "https://check-host.net/check-ping?host=$ip&node=ir1.node.check-host.net&node=ir3.node.check-host.net&node=ir5.node.check-host.net&node=ir6.node.check-host.net"

  # Parse JSON
  $jsonObject = $apiResult | ConvertFrom-Json

  # Extract request_id
  $requestId = $jsonObject.request_id

  # Extract request_id from the API response
  #$requestId = $apiResult.request_id
  
  # Check if request_id is not empty before adding it to the array
  if ($requestId -ne $null) {
    $requestIds += $requestId
  }
}

# Iterate through each request_id
foreach ($requestId in $requestIds) {
  # Indicate that the code is checking the second API
  Write-Host "Checking second API for request_id: $requestId ..."

  # Use the second API to get the ping results for the request_id
  do {
    $pingRequest = curl -s -H "Accept: application/json" "https://check-host.net/check-result/$requestId"
    Start-Sleep -Seconds 1
  } while ($pingRequest -eq $null)

  # Output IPs with "TIMEOUT" separately
  $timeoutIps = $pingRequest | Where-Object { $_ -like '*"TIMEOUT"*' } | ForEach-Object { $_.Split('"')[5] } | Sort-Object -Unique
  $timeoutIps | Out-File -Append -FilePath "timeout_ips.txt"

  # Output IPs with "OK" separately
  $okIps = $pingRequest | Where-Object { $_ -notlike '*"TIMEOUT"*' } | ForEach-Object { $_.Split('"')[5] } | Sort-Object -Unique
  $okIps | Out-File -Append -FilePath "ok_ips.txt"
}
