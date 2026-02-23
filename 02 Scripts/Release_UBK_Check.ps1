
$applicationName = "UBK Check"

$fileName = "C:\Working_Directory\Automation\02 UBK check\02 Scripts\UBKCheckV$ver.exe"
$inputFile = "C:\Working_Directory\Automation\02 UBK check\02 Scripts\UBKCheck.ps1"
$iconFile = "C:\Working_Directory\Automation\02 UBK check\02 Scripts\icon.ico"

$ver = Read-Host "Enter new version"

$ZipFilePath = "C:\temp\UBKCheck.zip"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$fileName = Join-Path $scriptDir ("UBKCheckV" + $ver + ".exe")
$inputFile = Join-Path $scriptDir ("UBKCheck.ps1")
$iconFile = Join-Path $scriptDir "icon.ico"


# Update version number in UBKCheck.ps1
$psContent = Get-Content $inputFile -Raw
$psContent = $psContent -replace '\$current_version = "[^"]*"', "`$current_version = `"$ver`""
Set-Content -Path $inputFile -Value $psContent -NoNewline

&"C:\Users\lpd5kor\OneDrive - Bosch Group\001_Automation\PS2EXE-GUI\ps2exe.ps1" -inputFile $inputFile -outputFile $fileName  -STA -iconFile $iconFile -title $applicationName -description $applicationName -company 'BGSW' -product $applicationName -copyright 'LPD5KOR' -version $ver 

if(Test-path -Path $ZipFilePath){
remove-item $ZipFilePath}

compress-archive -path $fileName -destinationpath $ZipFilePath -compressionlevel optimal


#Global release
Write-Output "Global release"
copy-item $fileName -destination \\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\
copy-item $ZipFilePath -destination \\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\

$iniFilePath = "\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\ubkcheck_current_ver.ini"
Set-Content -Path $iniFilePath -Value ""

$content = @"
$ver
\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\UBKCheckV$ver.exe
"@

Set-Content -Path $iniFilePath -Value $content


#EEI release
Write-Output "EEI Release"
copy-item $fileName -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check
copy-item $ZipFilePath -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check
copy-item "\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\ubkcheck_current_ver.ini" -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check