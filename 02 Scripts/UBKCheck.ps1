
"             ______   _          _______           _______  _______  _       
   |\     /|(  ___ \ | \    /\  (  ____ \|\     /|(  ____ \(  ____ \| \    /\
   | )   ( || (   ) )|  \  / /  | (    \/| )   ( || (    \/| (    \/|  \  / /
   | |   | || (__/ / |  (_/ /   | |      | (___) || (__    | |      |  (_/ / 
   | |   | ||  __ (  |   _ (    | |      |  ___  ||  __)   | |      |   _ (  
   | |   | || (  \ \ |  ( \ \   | |      | (   ) || (      | |      |  ( \ \ 
   | (___) || )___) )|  /  \ \  | (____/\| )   ( || (____/\| (____/\|  /  \ \
   (_______)|/ \___/ |_/    \/  (_______/|/     \|(_______/(_______/|_/    \/"
"                 Tool for naming convention check"
"                        Version : 1.12.0"
"    For help, suggestions and improvements please contact 'lpd5kor'" 

$current_version = "1.12.0"
$Script:htmlPath = "C:\Users\" + $env:USERNAME.ToLower() + "\AppData\Local\Temp\report.html"
$DownloadToolPath = "C:\Users\" + $env:USERNAME.ToLower() + "\Desktop\"
$IniFilePath = "\\SGPVMC0521.apac.bosch.com\CloudSearch\UBKCheck\PavastBased\ubkcheck_current_ver.ini"
$script:DailyCheckIni = "C:\Users\" + $env:USERNAME.ToLower() + "\AppData\Local\Temp\daily_check.ini"
$registryPath = "HKCU:\Software\Bosch\UBKCheck"
$LastUpdateDate = "LastUpdateDate"


# Check if the registry path exists, if not create it and set last update date to yesterday
if (-not(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null  # Create the registry path if it doesn't exist
    Set-ItemProperty -Path $registryPath -Name $LastUpdateDate -Value (Get-Date).AddDays(-1).ToString("yyyyMMdd")
}
# Retrieve registry properties, with error handling in case of failures
$property = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue

if (-not $property -or $property.$LastUpdateDate -ne (Get-Date).ToString("yyyyMMdd")) {
    Write-Output "    Daily update check running..."
    $UpdateCheckStatus = $True
    #READING UPDATE CHECK FILE
    try { $FileContent = get-content $IniFilePath -ErrorAction Stop } catch { $UpdateCheckStatus = $False }
    
    #READ SUCCESS
    if ($UpdateCheckStatus -and $FileContent.Count -ge 2) {
        $Latest_version = $FileContent[0]
        $Location = $FileContent[1]
        if ($Current_version -ne $Latest_version) {
            Write-Output "    A new update found, Downloading the update..."
            Copy-item $Location -destination $DownloadToolPath
            Write-Output "    Please use the latest tool version : UBKCheck - $Latest_version ... (At Desktop)"
            Read-Host "    Press any key to exit this version..."
            Exit
        }
        else {
            Write-Host "    No new update..." -ForegroundColor green
        }
    }
    else {
        #READ FAILED
        Write-Host "    Update check failed, but you are allowed to use current version for now..." -ForegroundColor red
    } 
    # Update the last update date in the registry
    Set-ItemProperty -Path $registryPath -Name $LastUpdateDate -Value (Get-Date).ToString("yyyyMMdd")
}

Write-Output "    Downloading latest UBK database..."

#Database API Link
$apiUrl = "https://si0vmc0854.de.bosch.com/swap-prod/api/ubk-keywords"

# Make the REST API call and store the response
try {
    $script:UBKArray = Invoke-RestMethod -Uri $apiUrl -Method Get
} catch {
    Write-Host "    Error occurred while downloading UBK database" -ForegroundColor Red
    Write-Host "    $_.Exception.Message"
    Read-Host "    Tool cannot continue, Press any key to exit"
    Exit
}

#Getting pavast Inputs
$Ready = $True
While ($Ready) {
    Write-Output " "
    $PavastFilePath = Read-Host "    Pavast file path (or drag your pavast file to this window)"
    $PavastFilePath = $PavastFilePath.Trim('"') #Why? To support drag and drop files with spaces in the path

    if ($PavastFilePath -ne "") {
        if (Test-Path $PavastFilePath -PathType leaf) {
            if (($PavastFilePath.Substring($PavastFilePath.Length - 11) -eq "_pavast.xml") -or ($PavastFilePath.Substring($PavastFilePath.Length - 15) -eq "_specpavast.xml")) { $Ready = $False }
            Else { Write-Output "    Please enter a valid pavast file path" }
        }
        else { Write-Output "    Please enter a valid pavast file path" }
    }
}

$Ready = $True
$BaseCompareActive = $False
While ($Ready) {
    Write-Output " "
    $BasePavastFilePath = Read-Host "    Base Pavast file path (optional, press enter to skip)"
    $BasePavastFilePath = $BasePavastFilePath.Trim('"') #Why? To support drag and drop files with spaces in the path

    if ($BasePavastFilePath -ne "") {
        if (Test-Path $BasePavastFilePath -PathType leaf) {
            if (($BasePavastFilePath.Substring($BasePavastFilePath.Length - 11) -eq "_pavast.xml") -or ($BasePavastFilePath.Substring($BasePavastFilePath.Length - 15) -eq "_specpavast.xml")) {
                $Ready = $False
                $BaseCompareActive = $True
            }
            Else { Write-Output "    Please enter a valid pavast file path" }
        }
        else { Write-Output "    Please enter a valid pavast file path" }
    }
    else {
        $Ready = $false
    }
}

#Collecting <Id> for orverriding
Write-Output " "
$Id = Read-Host "    <Id> Override value(optional, press enter to skip)"
    


function Get-CompareDescriptiveName {
    param ([string]$DescriptiveName)
    # If length is 1 character, user confirmation is requested
    $colour = if ($DescriptiveName.Length -eq 1) { "orange" } else { "green" }

    # Iterate through the $UBKArray using a foreach loop
    foreach ($item in $script:UBKArray) {
        if ($item.abbrName -ceq $DescriptiveName -and $item.lifeCycleState -eq "Valid" -and $item.state -eq "Released" -and $item.domainName -eq "AUTOSAR" -and ($item.rbClassifications -eq "Element" -or $item.rbClassifications -eq "ProperName")) {
            # Found an AUTOSAR entry
            return "<p style='color:$colour'>$DescriptiveName - " + $item.longNameEn + " (AUTOSAR)</p>"
       }
     
    }

    foreach ($item in $script:UBKArray) {
        if ($item.abbrName -ceq $DescriptiveName -and $item.lifeCycleState -eq "Valid" -and $item.state -eq "Released" -and $item.domainName -eq "RB" -and ($item.rbClassifications -eq "Element" -or $item.rbClassifications -eq "ProperName")) {
            # Found an RB entry
            return "<p style='color:orange'>$DescriptiveName - " + $item.longNameEn + " (RB)</p>" 
        }
    }

    foreach ($item in $script:UBKArray) {
        if ($item.abbrName -ceq $DescriptiveName -and ($item.lifeCycleState -eq "Obsolete" -or $item.lifeCycleState -eq "Removed") -and $item.state -eq "Released"  -and $item.useInsteadAbbrName -ne $null -and ($item.rbClassifications -eq "Element" -or $item.rbClassifications -eq "ProperName")) {
            # Found an RB entry
            return "<p style='color:red'>$DescriptiveName -  is no more valid, Try using '" +  $item.useInsteadAbbrName +"' instead</p>" 
        }
    }

    # If no AUTOSAR or RB entry was found
    return "<p style='color:red'>$DescriptiveName - not present in UBK abbreviations </p>"
}

    
    

function Get-IdCompareResult {
    param ([string]$MessagePartIn, [string]$idIn )
    if ($MessagePartIn -ceq $idIn) {
        Return "<p style='color:green' >" + $MessagePartIn + "</p>" 
    }
    else {
        Return "<p style='color:red'>" + $MessagePartIn + " - &lt;Id&gt; not equal to $idIn (Id)</p>"
    }
 
}


#Checking the validity of pp
function Get-Comparepp {
    param ([string]$pp)
    #Special pps    
    if ($pp -eq 'r')
    { Return "<p style='color:Orange'> $pp -  'r'=resistance, 'rat'=ratio </p>" }
    #Special pps
    if ($pp -eq 'mask')
    { Return "<p style='color:Orange'> $pp -  only valid for signal qualifier(Sq) mask calibrations</p>" }
    
    #Normal case
    foreach ($item in $script:UBKArray) {
        if ($item.abbrName -ceq $pp -and $item.lifeCycleState -eq "Valid" -and $item.state -eq "Released" -and ($item.rbClassifications -eq "Physical" -or $item.rbClassifications -eq "Logical")) {
            Return "<p style='color:green'>$pp - " + $item.longNameEn + "</p>"    
        }
    }
    
    foreach ($item in $script:UBKArray) {
        if ($item.abbrName -ceq $pp -and ($item.lifeCycleState -eq "Obsolete" -or $item.lifeCycleState -eq "Removed") -and $item.state -eq "Released"  -and $item.useInsteadAbbrName -ne $null -and ($item.rbClassifications -eq "Physical" -or $item.rbClassifications -eq "Logical")) {
            # Found an RB entry
            return "<p style='color:red'>$pp -  is no more valid, Try using '" +  $item.useInsteadAbbrName +"' instead</p>" 
        }
    }

    return "<p style='color:red'> $pp - not a valid Physical or Logical 'pp' </p>"
}

#Splitting the string to Abbrevations
function Get-SplittedArray {
    param ([string]$Unsplitted)


    # Return empty array if input is null or whitespace
    if ([string]::IsNullOrWhiteSpace($Unsplitted)) {
        return @()
    }
      # Initialize an empty string to build the modified text
      $newText = ""

      # Track if the previous character was an uppercase letter
      $seenCapitalBefore  = $false
  
      # Loop through each character of the input string
      foreach ($character in $Unsplitted.ToCharArray()) {
          # Insert a separator (*) if:
          # - Current character is uppercase
          # - OR previous character was uppercase and current character is a number
          if ([Char]::IsUpper($character) -or ($seenCapitalBefore  -and [Char]::IsNumber($character))) {
              $newText += '*'
          }
  
          # Add the current character to the array
          $newText += $character
  
          # Once a capital letter is seen, set the flag permanently
          if( [Char]::IsUpper($character)){$seenCapitalBefore  = $true}
      }
      
      # Remove any leading separator
      $newText = $newText.TrimStart('*')

      # Split the string by separator and return the array
      return $newText.Split('*')
  }

function Get-ContinuousCapitalArray {
    param ([string]$Unsplitted)
    
    $newtext = ""
    $ReturnArray = @()
    
    # Add a dummy capital followed by small letter at the end to detect final sequence and to avoid removing last capital letter
    $Unsplitted += "Xx"
        
    foreach ($character in $Unsplitted.ToCharArray()) {
        if ([char]::IsUpper($character)) {
            # If the character is uppercase, append it to the temporary string
            $newtext += $character
        }
        else {
            # When encountering a non-uppercase character, check for a sequence
            if ($newtext.Length -gt 3) {
                # Add to return array only if the sequence is more than 3 characters
                $ReturnArray += $newtext.SubString(0,$newtext.Length -1)
            }
            # Reset temporary string after processing
            $newtext = ""
        }
    }
    return $ReturnArray
} 

function Get-CompareCapitalName {
    param ([string]$DescriptiveName )
  
    foreach ($item in $script:UBKArray) {
             if ($item.abbrName -ceq $DescriptiveName -and $item.lifeCycleState -eq "Valid" -and $item.state -eq "Released" -and ($item.domainName -eq "RB" -or $item.domainName -eq "AUTOSAR")) { 
            Return "<p style='color:green'>$DescriptiveName - " + $item."Long Name En" + "</p>"
        }
    }

    $DescriptiveNameModified = $DescriptiveName.SubString(0, 1) + $DescriptiveName.SubString(1).ToLower()
 
    foreach ($item in $script:UBKArray) {
                  if ($item.abbrName -ceq $DescriptiveNameModified -and $item.lifeCycleState -eq "Valid" -and $item.state -eq "Released" -and ($item.domainName -eq "RB" -or $item.domainName -eq "AUTOSAR")) {             
            Return "<p style='color:Blue' >$DescriptiveName - not present in UBK, Recommendation - $DescriptiveNameModified" + "</p>"
        }
    }
    Return "<p style='color:red'>$DescriptiveName - not present in UBK abbrevations</p>"
    
}

   
function Get-LengthCheckResult {
    param ([string]$CIdentifier)
    
    $Sections = $CIdentifier.Split('_')
    $Result = "<table align='left'><tr><td colspan='3' style='color:#486350;font-weight:bold;text-align: center;'>Length Check</td></tr>"
    $Result += "<tr style='color:#486350;'><td>Section</td><td>Length</td><td>Status</td></tr>"   
    foreach ($Section in $Sections){
        $Length = $Section.Length
        $Color = if ($Length -gt 20) { "red" } else { "green" }
        $Status = if ($Length -gt 20) { "Failed" } else { "Passed" }
        # Use string interpolation for readability
        $Result += "<tr><td style='color:$Color;'>$Section</td><td style='color:$Color;'>$Length</td><td style='color:$Color;'>$Status</td></tr>"
    }
    $Result += "</table>"
    return $Result
}

function Get-Messages {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)

    $Messages = @()
    foreach ($ref in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-INTERFACES/SW-FEATURE-INTERFACE/SW-INTERFACE-EXPORTS/SW-INTERFACE-EXPORT/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS/SW-VARIABLE-REF-SYSCOND")) {
        $variableRef = $ref.SelectSingleNode("SW-VARIABLE-REF").InnerText 
        $Messages += $variableRef 
    }
    if ($null -ne $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-INTERFACES/SW-FEATURE-INTERFACE/SW-INTERFACE-EXPORTS/SW-INTERFACE-EXPORT/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF") {
        $Messages += $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-INTERFACES/SW-FEATURE-INTERFACE/SW-INTERFACE-EXPORTS/SW-INTERFACE-EXPORT/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF"}
    
    Return $Messages
}


function Get-Calibrations {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content -Path $PavastFilePath)

    $CodeGenerator = 'ASCET'
    $code = $PavastData.SelectSingleNode("//MSRSW/ADMIN-DATA/COMPANY-DOC-INFOS/COMPANY-DOC-INFO/SDGS/SDG/SD[@GID='MATLAB-User']")
    if ($code) { $CodeGenerator = 'MATLAB' }

    $Calibrations = @()

    if ($CodeGenerator -eq 'ASCET') {
        foreach ($ref in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS/SW-CALPRM-REF-SYSCOND")) {
            $CalibRef = $ref.SelectSingleNode("SW-CALPRM-REF").InnerText 
            $Calibrations += $CalibRef 
        }
        if($null -ne $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS")."SW-CALPRM-REF") {
            $Calibrations += $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS")."SW-CALPRM-REF"}
    }
    else {
        foreach ($ref in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS/SW-CALPRM-REF-SYSCOND")) {
            $CalibRef = $ref.SelectSingleNode("SW-CALPRM-REF").InnerText 
            $Calibrations += $CalibRef 
        }
        if($null -ne $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS")."SW-CALPRM-REF") {
             $Calibrations += $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-CALPRM-REFS")."SW-CALPRM-REF"
            }

    }
    Return $Calibrations
}

function Get-Variables {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content -Path $PavastFilePath)
    
    $CodeGenerator = 'ASCET'
    $code = $PavastData.SelectSingleNode("//MSRSW/ADMIN-DATA/COMPANY-DOC-INFOS/COMPANY-DOC-INFO/SDGS/SDG/SD[@GID='MATLAB-User']")
    if ($code) { $CodeGenerator = 'MATLAB' }
    
    $Variables = @()
    $Messages = @()
    
    if ($CodeGenerator -eq 'ASCET') {
        foreach ($ref in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS/SW-VARIABLE-REF-SYSCOND")) {
            $CalibRef = $ref.SelectSingleNode("SW-VARIABLE-REF").InnerText 
            $Variables += $CalibRef 
        }
        if($null -ne $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF"){
            $Variables += $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF"}
    }
    else {
        foreach ($ref in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS/SW-VARIABLE-REF-SYSCOND")) {
            $CalibRef = $ref.SelectSingleNode("SW-VARIABLE-REF").InnerText 
            $Variables += $CalibRef 
        }
        if($null -ne $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF"){
            $Variables += $PavastData.SelectSingleNode("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-VARIABLE-REFS")."SW-VARIABLE-REF"}
    }
    
    #Removing exported variables
    $Messages = Get-Messages -PavastFilePath $PavastFilePath
    $LocalVariables = @()
    foreach ($variable in $Variables) {
        if ($Messages -contains $variable) {} 
        else {
            $LocalVariables += $variable
        }
    }

    Return $LocalVariables
}

function Get-FCName {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content -Path $PavastFilePath)
    $FCName = $PavastData.SelectSingleNode("//MSRSW/SW-SYSTEMS/SW-SYSTEM/SW-COMPONENT-SPEC/SW-COMPONENTS/SW-FEATURE").'SHORT-NAME'
    return $FCName
}

#Messages
#Variables
#Calibrations
function Get-AnalysisTable{
    param ([string[]]$VariableArray, [String]$VariableType, [string]$IdIn, [string[]]$ExVarArray, [string]$ExVarType, [Boolean]$BaseCompareActive, [string[]]$BaseVariableArray)
    $Result =""
    $idVariable = $VariableType.ToLower()
    $Result = "<table id='$idVariable'><thead><tr><th>$VariableType</th><th>Findings</th></tr></thead><tbody>"
    
    foreach ($Variable In $VariableArray) {
        #Ignoring class instance variables in matlab generated pavast - 
        ###Needs better way to identify class instances
        if ($Variable.Substring($variable.Length - 2) -ceq '_I') {continue }
        
        #Splitting the messages to different parts
        $VariableParts = @()
        $VariableParts = $Variable.Split('_')
     
        #First column
        if (!$BaseCompareActive -or ($BaseVariableArray -contains $Variable)) {
            $Result += '<tr><td>' + $Variable + '</td><td>'
        }
        else {
            $Result += '<tr style="background-color:#aafa93" ><td>' + $Variable + '</td><td>'
        }
     
        #Checking number of underscores in variables.
        if($VariableType -eq "Calibrations"){
            if ($VariableParts.Length -ne 3) {
                $Result += "<p style='color:red'>Should have exact 2 '_'s in the name.<br>No other checks executed</p>";
                Continue
            }

        }
        else{
            if ($VariableParts.Length -gt 3 -or $VariableParts.Length -lt 2) {
                $Result += "<p style='color:red' >DGS recommend maximum of 2 '_'s and minimum one '_'. <br>No other checks executed.</p>"; 
                Continue 
            }
        }
        #Checking <Id> matching FC name
        $Result += Get-IdCompareResult -MessagePartIn $VariableParts[0] -idIn $IdIn
       
        #Splitting the second part of message
        [String[]]$SplittedVariable = Get-SplittedArray($VariableParts[1])
       
        #Checking <pp>    
        $Result += Get-Comparepp -pp $SplittedVariable[0]
    
        #Checking descriptive name
        $VariableCounter = 1
        while ($VariableCounter -lt $SplittedVariable.Length) {
            $Result += Get-CompareDescriptiveName -DescriptiveName $SplittedVariable[$VariableCounter]
            $VariableCounter++
        }
        
        #Checking last part of variable if it is present
        if ($VariableParts.Length -gt 2) {
            if ($ExVarArray -contains $VariableParts[2]) {
            } else {
                $Result += "<p style='color:red' >"+$VariableParts[2]+" is not a valid '"+$ExVarType+"'</p>" 
            }
        }
        #Continuos Capital letter check
        [String[]]$SplittedVariable = Get-ContinuousCapitalArray -Unsplitted $VariableParts[1]
            
        if ($SplittedVariable.Length -gt 0) { $Result += "<p><u>Continuous capital letter check</u></p>" }
        #Checking descriptive name
        $MessageCounter = 0
        while ($MessageCounter -lt $SplittedVariable.Length) {
            $Result += Get-CompareCapitalName -DescriptiveName $SplittedVariable[$MessageCounter]
            $MessageCounter++
        }
                  
        $Result += Get-LengthCheckResult -CIdentifier $Variable
        $Result += '</td></tr>'
    }
    
    $Result += "</tbody></table>"
    Return $Result
}


Write-Output "    Reading pavast..."


[String[]]$Calibrations = @()
[String[]]$Messages = @()
[String[]]$Variables = @()

[String[]]$BaseCalibrations = @()
[String[]]$BaseMessages = @()
[String[]]$BaseVariables = @()


$FCName = Get-FCName($PavastFilePath)
$Messages = Get-Messages($PavastFilePath)
$Calibrations = Get-Calibrations($PavastFilePath)
$Variables = Get-Variables($PavastFilePath)

#Reading Base pavast file
if ($BaseCompareActive) {
    if ($FCName -ne (Get-FCName($BasePavastFilePath))) {
        Write-Output "    Wrong base pavast file used"
        $BaseCompareActive = $False
    }
    else {
        $BaseMessages = Get-Messages($BasePavastFilePath)
        $BaseCalibrations = Get-Calibrations($BasePavastFilePath)
        $BaseVariables = Get-Variables($BasePavastFilePath)
    }
}


if ($Id -eq "") {
    $Id = $FCName.Split("_")[0]
}



$reportHTML = "<!DOCTYPE html>
<html>
<head><meta charset='UTF-8'>
<style>

table {
  font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
  border-collapse: collapse;
  width: 70%;
  margin-left: auto;
  margin-right: auto;
}

td, th {
  border: 1px solid #ddd;
  padding: 2px 14px;
  width: 50%;
}

tr:nth-child(even){background-color: #f2f2f2;}
th {
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: left;
  background-color: #4CAF50;
  color: white;
}

p.fcname {
text-align:center;
font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
color:purple;
font-size:300%;
}

div.warning {
background-color: #fff;
width:800px;
margin-top: 40vh;
position: absolute;
left:50%;
transform: translateX(-50%);
text-align: center;
padding: 0px 0px 20px 0px;
box-shadow: 0 0 20px 0 rgba(0,0,0,2);
border-radius: 14px;
font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
}

div.warninghead {
padding-top: 8px;
padding-left: 10px;
padding-bottom: 8px;
border-radius: 12px 12px 0px 0px;
text-align: left;
background-color: #4CAF50;
color: white;'
}

button.understand {
color: #fff;
background-color: #5cb85c; 
border-radius: 3px;
border: none;
padding: 10px 24px;
border-color: #4cae4c;
}
</style>
<title>UBKCheck report</title>
</head>
<body style='background-color: #ececec;' onload='ShowIUnderstandCheck()'>

<div id='Div1' class='warning'>
<div class='warninghead' >Please note !</div>
<ul style='color:#5e5e5e;text-align: left;padding:12px 12px 12px 30px;'>
  <li style='padding-bottom:6px'>The created report can only be used as an additional reference for your implementation. A manual check of the variables are still advised.</li>
  <li style='padding-bottom:6px'>If you are updating the name of existing variables(to fix the identified warning) extra care must be taken to check to see if it impacts anywhere else.</li>
  <li>Class instance names and instance specific variables are not checked in the current tool.</li>
</ul> 
<button onclick='MakeVisible()' class ='understand'>I Understand</button></div>
<div style='display: none;' id='Div2'>
<table class='legend'><tbody style='text-align:center'>
<tr ><th colspan='3' style='text-align:center'>Legend and statistics</th></tr>
<tr><td  style='width:10%'><input type='checkbox'  onchange='ApplyFilter()' id='CheckOk' checked/></td><td><p style='color:Green'>All Ok</p></td><td id='OkCount'>16</td></tr>
<tr><td  style='width:10%'><input type='checkbox'  onchange='ApplyFilter()' id='CheckSuggest' checked/></td><td><p style='color:Blue'>Suggestion</p></td><td id='SuggestionCount'>0</td></tr>
<tr><td  style='width:10%'><input type='checkbox'  onchange='ApplyFilter()' id='CheckError' checked/> </td><td><p style='color:Red'>Error</p></td><td id='ErrorCount'>37</td></tr>
<tr><td  style='width:10%'><input type='checkbox'  onchange='ApplyFilter()' id='CheckWarning' checked/></td><td><p style='color:Orange'>User confirmation needed</p></td><td id='WarningCount'>27</td></tr>
</tbody></table>
<p class='fcname'>$FCName</p>"

$ExVarMessageArray = @("MP","f","msg","f_msg", "Sq")
# $ExVarVariableArray = @('c','p','a','en','un','st','pfn','cb8','pb8','ab8','cb16','pb16','ab16','cb32','pb32','ab32','cu8',
#                         'pu8','au8','cu16','pu16','au16','cu32','pu32','au32','cu64','pu64','au64','cui','pui','aui','cs8','ps8','as8',
#                         'cs16','ps16','as16','cs32','ps32','as32','cs64','ps64','as64','csi','psi','asi','cr32','pr32','ar32')
$ExVarVariableArray = @("MP","f","msg","f_msg")
$ExVarCalibArray = @('C','CA','T','FT','GT','M','FM','GM','AX','ASC')


Write-Output "    Analyzing messages..."
$reportHTML += Get-AnalysisTable -VariableArray $Messages -VariableType "Messages" -IdIn $Id -ExVarArray $ExVarMessageArray -ExVarType "ExVar" -BaseCompareActive $BaseCompareActive -BaseVariableArray $BaseMessages
$reportHTML += '<br><br>'
Write-Output "    Analyzing variables..."
$reportHTML += Get-AnalysisTable -VariableArray $Variables -VariableType "Variables" -IdIn $Id -ExVarArray $ExVarVariableArray -ExVarType "ExVar" -BaseCompareActive $BaseCompareActive -BaseVariableArray $BaseVariables
$reportHTML += '<br><br>'
Write-Output "    Analyzing calibrations..."
$reportHTML += Get-AnalysisTable -VariableArray $Calibrations -VariableType "Calibrations" -IdIn $Id -ExVarArray $ExVarCalibArray -ExVarType "ExCal" -BaseCompareActive $BaseCompareActive -BaseVariableArray $BaseCalibrations

$reportHTML += '</div><script>
function ShowIUnderstandCheck() {
    if (typeof(Storage) !== "undefined") {
        var Lastaccepteddate = new Date();
        var currentDate = new Date()
        Lastaccepteddate = GetLocalStorage();
        if (Lastaccepteddate == null){SetLocalStorage();} 
        else {
            const diffTime = Math.abs(Lastaccepteddate - currentDate);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            if (diffDays > 7){SetLocalStorage();} else {MakeVisible();}
        }
    }
    Counter();
}

function SetLocalStorage() {
    var current = new Date();
    localStorage.setItem("LastAcceptedDate", current);}


function MakeVisible() {
    var x = document.getElementById("Div1");
    var y = document.getElementById("Div2");
    y.style.display = "block"
    x.style.display = "none";
}

function GetLocalStorage() {
    if (localStorage.getItem("LastAcceptedDate") != null) {
        return Date.parse(localStorage.getItem("LastAcceptedDate"));
    } else {return null}
    }

function ApplyFilter() {
	var showok = document.getElementById("CheckOk").checked;
	var showSuggest = document.getElementById("CheckSuggest").checked;
	var showErr = document.getElementById("CheckError").checked;
	var showConfirm = document.getElementById("CheckWarning").checked;
	var ids = ["messages", "variables", "calibrations"];
    for (iCount =0; iCount <3; iCount++) {
	FilterTable(document.getElementById(ids[iCount]), showok, showSuggest, showErr, showConfirm);
    }
}

function FilterTable(table, showok, showSuggest, showErr, showConfirm) {
	var tr = table.getElementsByTagName("tr");
	for (r = 1; r < tr.length; r++) {
		var allok=true;
		var sugg=false;
		var errprs=false;
		var conf=false;
		
		var td = tr[r].getElementsByTagName("td");
		if (td.length>0) {
			var para = td[1].getElementsByTagName("p");
			for (p=0;p<para.length; p++) {
				if (para[p].style.color=="blue") {sugg=true;allok=false;}
				if (para[p].style.color=="red") {errprs=true;allok=false;}
				if (para[p].style.color=="orange") {conf=true;allok=false;}
			}
		} 
		
		if ((showok && allok) || (showSuggest && sugg) || (showErr && errprs) || (showConfirm && conf)) {
			tr[r].style.display = "";
		} else {
			tr[r].style.display = "none";
		}
	}
}
function Counter()
{
var SuggestionCount = 0;
var ErrorCount = 0;
var WarningCount = 0;
var AllOkCount = 0;
var tableCalibrations;
var ids = ["messages", "variables", "calibrations"];
for (iCount =0; iCount <3; iCount++) {
 tableVariables = document.getElementById(ids[iCount]);

var tr = tableVariables.getElementsByTagName("tr");
	for (r = 1; r < tr.length; r++) {
		var allok=true;
		var sugg=false;
		var errprs=false;
		var conf=false;
		var td = tr[r].getElementsByTagName("td");
		if (td.length>0) {
			var para = td[1].getElementsByTagName("p");
			for (p=0;p<para.length; p++) {
				if (para[p].style.color=="blue") {sugg=true;allok=false;}
				if (para[p].style.color=="red") {errprs=true;allok=false;}
				if (para[p].style.color=="orange") {conf=true;allok=false;}
			}	
		}
		if(sugg){SuggestionCount++;}
		if(errprs){ErrorCount++;}
		if(conf){WarningCount++;}
		if(allok){AllOkCount++;}
}
}	
document.getElementById("OkCount").innerHTML = AllOkCount;
document.getElementById("SuggestionCount").innerHTML = SuggestionCount;
document.getElementById("ErrorCount").innerHTML = ErrorCount;
document.getElementById("WarningCount").innerHTML = WarningCount;
}

</script></body></html>'


#### Automation Tracking #####
$uriFeatureTracking = "https://sgpvmc0521.apac.bosch.com:8443/portal/api/tracking/trackFeature?toolId=ubkcheck&userId=" + $env:UserName + "&componentName=" + $FCName + "&result=" + $current_version + "-P"
$uriCountTracking = "https://sgpvmc0521.apac.bosch.com:8443/portal/api/tracking/save?toolId=ubkcheck&userId=" + $env:UserName
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
try {
    $resp = Invoke-WebRequest $uriFeatureTracking -Method GET -TimeoutSec 10 
    }
    catch {
        Write-Output "    Tool tracking failed 01"
    }
    try {
     $resp =Invoke-WebRequest $uriCountTracking -Method GET -TimeoutSec 10
    }
    catch {
        Write-Output "    Tool tracking failed 02"
    }
#### Tracking Ends here #####


#Final writing of test report
Write-Output "    Opening report ... "
if (Test-Path $Script:htmlPath -PathType leaf) {
    remove-item $Script:htmlPath
}
if (New-Item $Script:htmlPath) {}
Set-content -Path $Script:htmlPath  -Value $reportHTML

Invoke-item $Script:htmlPath


