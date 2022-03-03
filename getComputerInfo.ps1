# 1: Traigo el GUID del registro, si existe lo asigno, caso contrario se crea y se asigna al registro
try{$registryGuid = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid -ErrorAction Stop}
catch{Write-Output "GUID did not exist or couldn't access registry."}

if ( !$registryGuid ){
  $guid = New-Guid
  $guid =  $guid.guid
  try {
    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid -PropertyType String -Value $PSHome -ErrorAction Stop
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name Guid -Value $guid -ErrorAction Stop
    Write-Output "GUID added to registry"
  }
  catch{Write-Output "Couldn't access registry"}
}
else {
  Write-Output "GUID was found on registry"
  $guid=$registryGuid.guid}
# 2: Veo si se reconoce teclado y mouse conectado
$hasMouse    = $false
$hasKeyboard = $false
if (get-WmiObject win32_PointingDevice) {$hasMouse = $true}
if (get-WmiObject win32_Keyboard) {$hasKeyboard = $true}
# 3: Traigo la informacion
$cpu          = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property name
$manufacturer = Get-CimInstance -ClassName  Win32_ComputerSystem | Select-Object -Property manufacturer,model
$windows      = Get-CimInstance -ClassName  Win32_OperatingSystem | Select-Object -Property Caption
$disk         = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -Property size,freespace
$ramSpeed     = Get-CimInstance -ClassName Win32_PhysicalMemory | select-object speed
$ram          = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
# 4: Creo el objeto y asigno la informacion
$systemInfo = [PSCustomObject]@{
  cpu          = $cpu.name
  manufacturer = $manufacturer.manufacturer
  model        = $manufacturer.model
  ramCount     = $ram.count
  ramSum       = $ram.sum/1Gb
  ramSpeed     = $ramSpeed.speed
  windows      = $windows.Caption
  hddSize      =  [math]::Round($disk.size/1Gb,2)
  hddFreeSpace =  [math]::Round($disk.freespace/1Gb,2)
  hasMouse     = $hasMouse
  hasKeyboard  = $hasKeyboard
}
# 5: Paso el objeto a JSON y lo guardo. Además, guardo una copia del GUID en la carpeta C:\Users como archivo .json
$systemInfo = $systemInfo | ConvertTo-Json 
# $systemInfo | Out-File ".\systemInfo.json"
try{
  $systemInfo.guid  | ConvertTo-Json | Out-File "C:\Users\guid.json" -ErrorAction Stop
  Write-Output "Info stored at C:\Users\guid.json" -ErrorAction Stop
}
catch{Write-Output "Couldn't store info"}
Write-Output "GUID: "$guid
# 6:Subo el resultado a la API
$Params = @{
  Method = "Put"
  Uri = "https://inventario-de-pcs-default-rtdb.firebaseio.com/$guid.json"
  Body = $systemInfo
  ContentType = "application/json"
}
try{
  Invoke-RestMethod @Params -ErrorAction Stop
  Write-Output "Info uploaded to the database"
}
catch{
  Write-Output "Couldn't upload info to the database"
}
