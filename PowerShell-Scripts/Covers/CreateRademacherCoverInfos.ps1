# basepath - working directory
$basepath = "D:\temp\rademacher"
# Name of json-File from homepilot, get it from http://[Homepilot IP]/devices and save it
$devicesJSONFileName = "Rademacher-Devices.json"
# parts of devicenames, that should be excluded, e.g. switche, ligths, ...
$excludeNamesContaining = @("stecker", "duofern", "licht", "leucht")
# Homepilot-IP
$homepilotIP = "192.168.66.99"

# debugmode
$debug = $true
#region templates
$templateSensor = "- platform: rest" + [environment]::NewLine +
"  name: '{{sensorName}}_position'" + [environment]::NewLine +
"  resource: 'http://$($homepilotIP)/devices/{{deviceID}}'" + [environment]::NewLine +
"  value_template: >-" + [environment]::NewLine +
"    {% for item in value_json.payload.device.capabilities %}" + [environment]::NewLine +
"      {%- if item.name == `"CURR_POS_CFG`" -%}" + [environment]::NewLine +
"        {{ 100 - float(item.value) }}" + [environment]::NewLine +
"      {%- endif -%}" + [environment]::NewLine +
"    {% endfor %}" + [environment]::NewLine +
"  scan_interval: 10"

$templateCover = "- platform: template" + [environment]::NewLine +
"  covers:" + [environment]::NewLine +
"    {{sensorName}}:" + [environment]::NewLine +
"      device_class: shutter" + [environment]::NewLine +
"      friendly_name: `"{{deviceName}}`"" + [environment]::NewLine +
"      unique_id: `"{{sensorName}}`"" + [environment]::NewLine +
"      position_template: `"{{ states('sensor.{{sensorName}}_position') }}`"" + [environment]::NewLine +
"      open_cover:" + [environment]::NewLine +
"        - service: rest_command.belt_winder_up" + [environment]::NewLine +
"          data:" + [environment]::NewLine +
"            did: {{deviceID}}" + [environment]::NewLine +
"      close_cover:" + [environment]::NewLine +
"        - service: rest_command.belt_winder_down" + [environment]::NewLine +
"          data:" + [environment]::NewLine +
"            did: {{deviceID}}" + [environment]::NewLine +
"      stop_cover:" + [environment]::NewLine +
"        - service: rest_command.belt_winder_stop" + [environment]::NewLine +
"          data:" + [environment]::NewLine +
"            did: {{deviceID}}" + [environment]::NewLine +
"      set_cover_position:" + [environment]::NewLine +
"        - service: rest_command.belt_winder_set_position" + [environment]::NewLine +
"          data_template:" + [environment]::NewLine +
"            did: {{deviceID}}" + [environment]::NewLine +
"            position: `"{{position}}`"" + [environment]::NewLine
#endregion
#region functions
$scriptPath = Get-Location
$helpersModulePath = [System.IO.Path]::Combine($scriptPath, "Helpers_Rademacher.psm1")
if (-not (Test-Path $helpersModulePath)) {
    Write-Error "Helpers-Module not found"
    return
}
else {
    if ($debug) {
        $HelperModule = Get-Module -Name "Helpers_Rademacher"
        if ($HelperModule) { 
            try {        
                Remove-Module $HelperModule
            }
            catch {
                Write-Error "Fehler beim Entfernen des Moduls '$($HelperModule)'"
                Write-Error $_.Exception.Message
            }   
        }
    }
    Import-Module $helpersModulePath 
}
#endregion
#region Script Variables
$deviceSensors = @()
$deviceCovers = @()
$allDevices = @() #TODO: collecting deviceinformation as object
#endrgion

#region Magic
$path = "$($basepath.TrimEnd("\"))\$($devicesJSONFileName)"
$devices = Get-Content -Path $path -Raw -Encoding UTF8| ConvertFrom-Json
if ($null -ne $devices -and $devices.error_code -eq 0) {
    write-host "found '$($devices.payload.devices.Count)' devices"
    foreach ($device in $devices.payload.devices) {
        $deviceID = ($device.capabilities | Where-Object { $_.name -eq "ID_DEVICE_LOC" }).value
        $deviceName = ($device.capabilities | Where-Object { $_.name -eq "NAME_DEVICE_LOC" }).value    
        $exclude = $false
        foreach ($val in $excludeNamesContaining) {
            if ( $deviceName -like "*$($val)*") {
                $exclude = $true
                break
            }
        }    
        if (-not $exclude) {
            write-host "'$($deviceName)' has id '$($deviceID)'" -ForegroundColor Yellow
            $sensorName = Set-SpecialCharactersDE $deviceName.ToLower() 
            #((((($deviceName.ToLower() -replace " ","_") -replace "ü","ue") -replace "ä","ae") -replace "ö","oe") -replace "ß","ss") | $sensorName 
            $t = $templateSensor -replace "{{sensorName}}", $sensorName
            $t = $t -replace "{{deviceID}}", "$($deviceID)"
            $t = $t -replace "{{deviceID}}", "$($deviceID)"
            $deviceSensors += $t
            write-host "Sensor-template for '$($deviceName)'" -ForegroundColor Green    
            write-host $t
            $t2 = $templateCover -replace "{{deviceName}}", $deviceName
            $t2 = $t2 -replace "{{sensorName}}", $sensorName
            $t2 = $t2 -replace "{{deviceID}}", "$($deviceID)"
            $deviceCovers += $t2
            write-host "Cover-template for '$($deviceName)'" -ForegroundColor Green    
            write-host $t2
        }
        else {
            write-host "Skipping $($deviceName)" -ForegroundColor Magenta
        }
    }
}
$dateLong = (Get-Date).ToString("yyyy-MM-dd_hh-mm-ss")
if ($deviceSensors.Length -gt 0) {
    $deviceSensors | Out-File "$($basepath.TrimEnd("\"))\RademacherDeviceSensors_$($dateLong).yml" -Encoding utf8 -Force
}
if ($deviceCovers.Length -gt 0) {
    $deviceCovers | Out-File "$($basepath.TrimEnd("\"))\RademacherDeviceCovers_$($dateLong).yml" -Encoding utf8 -Force
}
#endregion