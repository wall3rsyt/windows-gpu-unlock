# Read-only RTX 50-series inventory collector
# Does not modify PCI configuration, MMIO, firmware, drivers, or GPU state.
# Review output before sharing; it intentionally omits serial numbers and device instance IDs.

$ErrorActionPreference = "Continue"

Write-Output "=== OS ==="
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture |
    Format-List

Write-Output "=== NVIDIA GPU (nvidia-smi) ==="
$nvidiaSmi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    & $nvidiaSmi.Source --query-gpu=name,pci.bus_id,pci.device_id,pci.sub_device_id,driver_version,vbios_version,memory.total --format=csv,noheader
} else {
    Write-Output "nvidia-smi.exe not found in PATH"
}

Write-Output "=== NVIDIA display adapter PnP properties ==="
$gpus = Get-PnpDevice -Class Display -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match "NVIDIA|GeForce" }

foreach ($gpu in $gpus) {
    Write-Output ("Adapter: " + $gpu.FriendlyName)
    foreach ($key in @(
        "DEVPKEY_Device_HardwareIds",
        "DEVPKEY_Device_LocationInfo",
        "DEVPKEY_Device_DriverVersion",
        "DEVPKEY_Device_Manufacturer"
    )) {
        $p = Get-PnpDeviceProperty -InstanceId $gpu.InstanceId -KeyName $key -ErrorAction SilentlyContinue
        if ($p -and $null -ne $p.Data) {
            Write-Output ($key + ": " + (($p.Data | ForEach-Object { "$_" }) -join "; "))
        }
    }
}

Write-Output "=== Motherboard and BIOS ==="
Get-CimInstance Win32_BaseBoard |
    Select-Object Manufacturer, Product, Version |
    Format-List
Get-CimInstance Win32_BIOS |
    Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate |
    Format-List

Write-Output "=== End of inventory ==="
Write-Output "No unlock attempt or hardware modification was performed."
