Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System + Network Dashboard"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

# Scrollable Panel for all content
$scrollPanel = New-Object System.Windows.Forms.Panel
$scrollPanel.Dock = "Fill"
$scrollPanel.AutoScroll = $true
$form.Controls.Add($scrollPanel)

# Function to create styled labels
function New-ColoredLabel($text, $fontSize=10, $color='White') {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.AutoSize = $true
    $lbl.Font = New-Object System.Drawing.Font("Consolas",$fontSize,[System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::$color
    $lbl.Text = $text
    return $lbl
}

# Function to create progress bars
function New-ProgressBar($width, $height, $color) {
    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Width = $width
    $pb.Height = $height
    $pb.Style = 'Continuous'
    $pb.ForeColor = [System.Drawing.Color]::$color
    $pb.Minimum = 0
    $pb.Maximum = 100
    return $pb
}

# CPU Label & Progress Bar
$cpuLabel = New-ColoredLabel "CPU Usage: 0%" 12 'Lime'
$cpuBar = New-ProgressBar 600 20 'Lime'
$cpuLabel.Location = New-Object System.Drawing.Point(20,20)
$cpuBar.Location = New-Object System.Drawing.Point(20,45)
$scrollPanel.Controls.Add($cpuLabel)
$scrollPanel.Controls.Add($cpuBar)

# RAM Label & Progress Bar
$ramLabel = New-ColoredLabel "RAM Usage: 0GB" 12 'Cyan'
$ramBar = New-ProgressBar 600 20 'Cyan'
$ramLabel.Location = New-Object System.Drawing.Point(20,75)
$ramBar.Location = New-Object System.Drawing.Point(20,100)
$scrollPanel.Controls.Add($ramLabel)
$scrollPanel.Controls.Add($ramBar)

# System Info Label
$sysLabel = New-ColoredLabel "" 10 'White'
$sysLabel.Location = New-Object System.Drawing.Point(20,140)
$scrollPanel.Controls.Add($sysLabel)

# Network Info Label
$netLabel = New-ColoredLabel "" 10 'Orange'
$netLabel.Location = New-Object System.Drawing.Point(20,260)
$scrollPanel.Controls.Add($netLabel)

# Function to update all data
function Update-Dashboard {
    # CPU
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $cpuLabel.Text = "CPU Usage: $([math]::Round($cpu,2))%"
    $cpuBar.Value = [math]::Round($cpu)

    # RAM
    $ram = Get-CimInstance Win32_OperatingSystem
    $totalRam = [math]::Round($ram.TotalVisibleMemorySize/1MB,2)
    $freeRam = [math]::Round($ram.FreePhysicalMemory/1MB,2)
    $usedRam = $totalRam - $freeRam
    $ramLabel.Text = "RAM Usage: $usedRam GB / $totalRam GB"
    $ramBar.Value = [math]::Round(($usedRam/$totalRam)*100)

    # System Info
    $sysLabel.Text = "Computer: $env:COMPUTERNAME`nUser: $env:USERNAME`nOS: $($ram.Caption)"

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

        # Wi-Fi SSID
        if ($net.InterfaceDescription -match "Wireless|Wi-Fi") {
            $ssidMatch = netsh wlan show interfaces | Select-String "SSID\s*:\s*(.+)$"
            $ssid = if ($ssidMatch) { $ssidMatch.Matches[0].Groups[1].Value } else { "Not connected" }
        } else {
            $ssid = ""
        }

        $networkText += "Adapter: $name`nStatus: $status`nMAC: $mac`nIP(s): $ips`nGateway: $gateway`nDNS: $dns`nWi-Fi: $ssid`n`n"
    }
    $netLabel.Text = $networkText
}

# Timer to refresh every 2 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Update-Dashboard })
$timer.Start()

# Initial update
Update-Dashboard

$form.ShowDialog()
