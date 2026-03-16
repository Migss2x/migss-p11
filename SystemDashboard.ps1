Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "System Dashboard"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Font = New-Object System.Drawing.Font("Consolas",10)

function Get-SystemInfo {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $ram = (Get-CimInstance Win32_OperatingSystem)
    $usedRam = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory)/1MB,2)

    $text = @"
Computer: $env:COMPUTERNAME
User: $env:USERNAME

CPU Usage: $([math]::Round($cpu,2)) %

RAM Used: $usedRam GB

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