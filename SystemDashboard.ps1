Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "System + Network Dashboard"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

# Scrollable panel for network info
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'
$panel.AutoScroll = $true
$form.Controls.Add($panel)

# System Info Labels
$cpuLabel = New-Object System.Windows.Forms.Label
$cpuLabel.Font = New-Object System.Drawing.Font("Consolas",12,[System.Drawing.FontStyle]::Bold)
$cpuLabel.ForeColor = [System.Drawing.Color]::Lime
$cpuLabel.Location = New-Object System.Drawing.Point(20,20)
$cpuLabel.AutoSize = $true

$cpuBar = New-Object System.Windows.Forms.ProgressBar
$cpuBar.Width = 700
$cpuBar.Height = 20
$cpuBar.Location = New-Object System.Drawing.Point(20,50)
$cpuBar.Style = 'Continuous'
$cpuBar.Minimum = 0
$cpuBar.Maximum = 100

$ramLabel = New-Object System.Windows.Forms.Label
$ramLabel.Font = New-Object System.Drawing.Font("Consolas",12,[System.Drawing.FontStyle]::Bold)
$ramLabel.ForeColor = [System.Drawing.Color]::Cyan
$ramLabel.Location = New-Object System.Drawing.Point(20,85)
$ramLabel.AutoSize = $true

$ramBar = New-Object System.Windows.Forms.ProgressBar
$ramBar.Width = 700
$ramBar.Height = 20
$ramBar.Location = New-Object System.Drawing.Point(20,115)
$ramBar.Style = 'Continuous'
$ramBar.Minimum = 0
$ramBar.Maximum = 100

$sysLabel = New-Object System.Windows.Forms.Label
$sysLabel.Font = New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Bold)
$sysLabel.ForeColor = [System.Drawing.Color]::White
$sysLabel.Location = New-Object System.Drawing.Point(20,150)
$sysLabel.AutoSize = $true

$networkLabel = New-Object System.Windows.Forms.Label
$networkLabel.Font = New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Bold)
$networkLabel.ForeColor = [System.Drawing.Color]::Orange
$networkLabel.Location = New-Object System.Drawing.Point(20,220)
$networkLabel.AutoSize = $true

$panel.Controls.AddRange(@($cpuLabel,$cpuBar,$ramLabel,$ramBar,$sysLabel,$networkLabel))

# Cache network info
$netAdapters = Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $null}

# Update function (async-friendly)
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
    $networkText = ""
    foreach ($net in $netAdapters) {
        $name = $net.InterfaceAlias
        $status = $net.InterfaceOperationalStatus
        $mac = $net.InterfacePhysicalAddress
        $ips = ($net.IPv4Address | ForEach-Object {$_.IPAddress}) -join ", "
        $gateway = ($net.IPv4DefaultGateway | ForEach-Object {$_.NextHop}) -join ", "
        $dns = ($net.DnsServer | ForEach-Object {$_.Address}) -join ", "
        if ($net.InterfaceDescription -match "Wireless|Wi-Fi") {
            $ssidMatch = netsh wlan show interfaces | Select-String "SSID\s*:\s*(.+)$"
            $ssid = if ($ssidMatch) { $ssidMatch.Matches[0].Groups[1].Value } else { "Not connected" }
        } else {
            $ssid = ""
        }
        $networkText += "Adapter: $name`nStatus: $status`nMAC: $mac`nIP(s): $ips`nGateway: $gateway`nDNS: $dns`nWi-Fi: $ssid`n`n"
    }
    $networkLabel.Text = $networkText
}

# Timer optimized: smaller interval and async-friendly
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000  # 1 second for smoother feel
$timer.Add_Tick({ Update-Dashboard })
$timer.Start()

# Initial call
Update-Dashboard

$form.ShowDialog()
