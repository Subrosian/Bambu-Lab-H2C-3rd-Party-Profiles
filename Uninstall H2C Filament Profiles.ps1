$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SystemRoot = Join-Path $env:APPDATA "BambuStudio\system"
$BblJson = Join-Path $SystemRoot "BBL.json"
$DestRoot = Join-Path $SystemRoot "BBL\filament"
$Library = Get-Content (Join-Path $Root "manifests\profiles.json") -Raw | ConvertFrom-Json
$Manifest = Get-Content $BblJson -Raw | ConvertFrom-Json
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $BblJson "$BblJson.backup-$Stamp" -Force

$Names = @{}
foreach ($BrandProp in $Library.brands.PSObject.Properties) {
	foreach ($Entry in $BrandProp.Value) {
		$Names[$Entry.name] = $true
		$File = Join-Path (Join-Path $DestRoot $BrandProp.Name) "$($Entry.name).json"
		if (Test-Path $File) {
			Remove-Item $File -Force
		}
	}
}
$Manifest.filament_list = @($Manifest.filament_list | Where-Object {
	-not ($_.name -and $Names.ContainsKey($_.name))
})
$Manifest | ConvertTo-Json -Depth 100 | Set-Content $BblJson -Encoding UTF8
Write-Host "Library-managed H2C profiles removed."
