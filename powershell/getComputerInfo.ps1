$registryGuid = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid
if ( !$registryGuid )
{
  $guid = New-Guid
  New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid -PropertyType String -Value $PSHome
  Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid -Value $guid
  Write-Output "guid added to registry"
}
else {
  $guid=$registryGuid
}
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property name
$manufacturer = Get-CimInstance -ClassName  Win32_ComputerSystem | Select-Object -Property manufacturer,model
$windows = Get-CimInstance -ClassName  Win32_OperatingSystem | Select-Object -Property Caption
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -Property size,freespace
$ram = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$systemInfo = [PSCustomObject]@{
  guid         = $guid.guid
  cpu          = $cpu.name
  manufacturer = $manufacturer.manufacturer
  model        = $manufacturer.model
  ramCount     = $ram.count
  ramSum       = $ram.sum/1Gb
  windows      = $windows.Caption
  hddSize      = $disk.size/1Gb
  hddFreeSpace = $disk.freespace/1Gb
}

Write-Output $systemInfo
$systemInfo | Export-Csv -Path .\systemInfo.csv -NoTypeInformation
$csv =[PSCustomObject]@{
  guid = $guid.guid
}
$csv  | Export-Csv -Path "C:\Users\guid.csv" -NoTypeInformation