Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "System Dashboard"
$form.Size = New-Object System.Drawing.Size(500,500)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Font = New-Object System.Drawing.Font("Consolas",10)

function Get-SystemInfo {

    # CPU Usage
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

    # RAM Usage
    $ram = (Get-CimInstance Win32_OperatingSystem)
    $usedRam = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory)/1MB,2)

    # Network Info
    $netAdapters = Get-NetAdapter | Where-Object Status -eq 'Up'
    $networkText = ""
    foreach ($adapter in $netAdapters) {
        $name = $adapter.Name
        $status = $adapter.Status
        $mac = $adapter.MacAddress

        $ips = (Get-NetIPAddress -InterfaceAlias $name | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object -ExpandProperty IPAddress) -join ", "

        # Wi-Fi SSID (if Wi-Fi)
        if ($adapter.MediaType -eq "802.3") {
            $ssid = ""
        } elseif ($adapter.MediaType -like "*Wireless*") {
            $ssidMatch = netsh wlan show interfaces | Select-String "SSID\s*:\s*(.+)$"
            $ssid = if ($ssidMatch) { $ssidMatch.Matches[0].Groups[1].Value } else { "" }
        } else {
            $ssid = ""
        }

        $networkText += "Adapter: $name`nStatus: $status`nMAC: $mac`nIP(s): $ips`nWi-Fi: $ssid`n`n"
    }

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

$form.Controls.Add($label)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Get-SystemInfo })
$timer.Start()

Get-SystemInfo

$form.ShowDialog()
