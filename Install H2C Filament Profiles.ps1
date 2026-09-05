$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SystemRoot = Join-Path $env:APPDATA "BambuStudio\system"
$BblJson = Join-Path $SystemRoot "BBL.json"
$DestRoot = Join-Path $SystemRoot "BBL\filament"
$LibraryPath = Join-Path $Root "manifests\profiles.json"

if (-not (Test-Path $BblJson)) {
	throw "Bambu Studio profile manifest not found. Open Bambu Studio once, select the H2C, quit it, and run this again."
}

if (Get-Process -Name "BambuStudio*" -ErrorAction SilentlyContinue) {
	throw "Quit Bambu Studio completely before installing."
}

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $BblJson "$BblJson.backup-$Stamp" -Force

$Manifest = Get-Content $BblJson -Raw | ConvertFrom-Json
$Library = Get-Content $LibraryPath -Raw | ConvertFrom-Json

if (-not $Manifest.filament_list) {
	throw "Unexpected BBL.json format. Restore the timestamped backup."
}

$Existing = @{}
foreach ($Item in $Manifest.filament_list) {
	if ($Item.name) {
		$Existing[$Item.name] = $true
	}
}

foreach ($BrandProp in $Library.brands.PSObject.Properties) {
	$Brand = $BrandProp.Name
	$Dest = Join-Path $DestRoot $Brand
	New-Item -ItemType Directory -Path $Dest -Force | Out-Null

	foreach ($Entry in $BrandProp.Value) {
		$Src = Join-Path $Root ($Entry.path -replace '/', '\')
		$Filename = "$($Entry.name).json"
		Copy-Item $Src (Join-Path $Dest $Filename) -Force

		if (-not $Existing.ContainsKey($Entry.name)) {
			$Manifest.filament_list += [PSCustomObject]@{
				name = $Entry.name
				sub_path = "filament/$Brand/$Filename"
			}
			$Existing[$Entry.name] = $true
		}
	}
}

$Manifest | ConvertTo-Json -Depth 100 | Set-Content $BblJson -Encoding UTF8
Write-Host "H2C filament profiles installed."
Write-Host "A timestamped BBL.json backup was created."
