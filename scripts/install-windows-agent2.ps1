<powershell>
Start-Transcript -Path "$env:ProgramData\wazuh_install.log" -Append
try {
    # Enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Variables
    $sysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
    $wazuhAgentUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi"
    $swiftConfig = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
    
    # Download Sysmon config
    Invoke-WebRequest -Uri $swiftConfig -OutFile "$env:TEMP\sysmonconfig.xml" -UseBasicParsing
    
    # Download and install Sysmon
    $sysmonZip = "$env:TEMP\Sysmon.zip"
    Invoke-WebRequest -Uri $sysmonUrl -OutFile $sysmonZip -UseBasicParsing
    Expand-Archive -Path $sysmonZip -DestinationPath "$env:TEMP\Sysmon" -Force
    & "$env:TEMP\Sysmon\Sysmon64.exe" -accepteula -i "$env:TEMP\sysmonconfig.xml"
    
    # Download and install Wazuh Agent
    $agentInstaller = "$env:TEMP\wazuh-agent.msi"
    Invoke-WebRequest -Uri $wazuhAgentUrl -OutFile $agentInstaller -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$agentInstaller`" /quiet"
    
    # Write manual config script to desktop (FIXED VERSION)
    $configScript = @"
# Configure Wazuh Agent Manager IP
# Replace the IP below with your actual manager private IP
`$ManagerIP = 'REPLACE_ME'

if (`$ManagerIP -eq 'REPLACE_ME') {
    Write-Host 'You must edit `$ManagerIP in this script before running.'
    Write-Host 'Change REPLACE_ME to your Wazuh Manager IP address'
    exit 1
}

`$confPath = 'C:\Program Files (x86)\ossec-agent\ossec.conf'

Write-Host "Configuring Wazuh Agent to connect to: `$ManagerIP"

# Read the config file
`$content = Get-Content `$confPath -Raw

# Replace the server address (from default 0.0.0.0)
`$content = `$content -replace '<address>0\.0\.0\.0</address>', "<address>`$ManagerIP</address>"

# Save the modified content
`$content | Set-Content `$confPath

Write-Host "Configuration updated successfully!"

# Optional: Register with Wazuh Manager
try {
    Write-Host "Attempting to register with Wazuh Manager..."
    Start-Process -FilePath "C:\Program Files (x86)\ossec-agent\agent-auth.exe" -ArgumentList "-m `$ManagerIP" -Wait
    Write-Host "Agent registration completed"
} catch {
    Write-Warning "Agent registration failed: `$_"
    Write-Host "You can register manually later if needed"
}

# Start the Wazuh service
Write-Host "Starting Wazuh service..."
Start-Service -Name "WazuhSvc"

# Check service status
Get-Service -Name "WazuhSvc"

Write-Host "Wazuh Agent configured and started with manager IP: `$ManagerIP"
Write-Host "Configuration complete!"
"@

    $configScript | Out-File -FilePath "C:\Users\Administrator\Desktop\configure-wazuh.ps1" -Encoding UTF8
    
    Write-Host "Wazuh Agent installed successfully!"
    Write-Host "Manager IP not configured yet - this is normal."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Find your Wazuh Manager IP address"
    Write-Host "2. Edit C:\Users\Administrator\Desktop\configure-wazuh.ps1"
    Write-Host "3. Replace 'REPLACE_ME' with your manager IP"
    Write-Host "4. Run the configuration script"
    Write-Host ""
    Write-Host "Installation completed successfully!"
    
} catch {
    Write-Error "Installation failed: $_"
}
Stop-Transcript
</powershell>