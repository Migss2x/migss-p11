Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System + Network Dashboard"
$form.Size = New-Object System.Drawing.Size(600,600)
$form.StartPosition = "CenterScreen"

# Create a label to hold the text
$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Font = New-Object System.Drawing.Font("Consolas",10)

# Function to update the dashboard
function Get-SystemInfo {

    # CPU Usage
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

    # RAM Usage
    $ram = Get-CimInstance Win32_OperatingSystem
    $usedRam = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory)/1MB,2)

    # Network Info
    $netConfigs = Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $null}
    $networkText = ""

    foreach ($net in $netConfigs) {
        $name = $net.InterfaceAlias
        $status = $net.InterfaceOperationalStatus
        $mac = $net.InterfacePhysicalAddress
        $ips = ($net.IPv4Address | ForEach-Object {$_.IPAddress}) -join ", "
        $gateway = ($net.IPv4DefaultGateway | ForEach-Object {$_.NextHop}) -join ", "
        $dns = ($net.DnsServer | ForEach-Object {$_.Address}) -join ", "

        # Wi-Fi SSID detection (if Wireless)
        if ($net.InterfaceDescription -match "Wireless|Wi-Fi") {
            $ssidMatch = netsh wlan show interfaces | Select-String "SSID\s*:\s*(.+)$"
            $ssid = if ($ssidMatch) { $ssidMatch.Matches[0].Groups[1].Value } else { "Not connected" }
        } else {
            $ssid = ""
        }

        $networkText += "Adapter: $name`nStatus: $status`nMAC: $mac`nIP(s): $ips`nGateway: $gateway`nDNS: $dns`nWi-Fi: $ssid`n`n"
    }

    # Combine all info
    $text = @"
Computer: $env:COMPUTERNAME
User: $env:USERNAME

CPU Usage: $([math]::Round($cpu,2)) %
RAM Used: $usedRam GB

NETWORK INFO:
$networkText

OS: $($ram.Caption)
"@

    $label.Text = $text
}

# Add label to the form
$form.Controls.Add($label)

# Timer to refresh every 2 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Get-SystemInfo })
$timer.Start()

# Initial update
Get-SystemInfo

# Show the form
$form.ShowDialog()
