$ver = Read-Host "Enter new version"


$applicationName = "UBK Check"
$ZipFilePath = "C:\temp\UBKCheck.zip"
$fileName = "C:\Users\lpd5kor\OneDrive - Bosch Group\001_Automation\02 UBK check\UBKCheckBetaV$ver.exe"
$inputFile = "C:\Users\lpd5kor\OneDrive - Bosch Group\001_Automation\02 UBK check\UBKCheckBetaV"+ $ver + ".ps1"
$iconFile = "C:\Users\lpd5kor\OneDrive - Bosch Group\001_Automation\02 UBK check\check-form_116472.ico"

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
\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\UBKCheckBetaV$ver.exe
"@

Set-Content -Path $iniFilePath -Value $content


#EEI release
Write-Output "EEI Release"
copy-item $fileName -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check
copy-item $ZipFilePath -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check
copy-item "\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\ubkcheck_current_ver.ini" -destination \\bosch.com\dfsrb\DfsIN\loc\Kor\BE-ES\EEI_EC\05_Global\01_Internal\24_EEI_Automation\03_UBK_Check