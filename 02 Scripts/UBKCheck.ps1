
"             ______   _          _______           _______  _______  _       
   |\     /|(  ___ \ | \    /\  (  ____ \|\     /|(  ____ \(  ____ \| \    /\
   | )   ( || (   ) )|  \  / /  | (    \/| )   ( || (    \/| (    \/|  \  / /
   | |   | || (__/ / |  (_/ /   | |      | (___) || (__    | |      |  (_/ / 
   | |   | ||  __ (  |   _ (    | |      |  ___  ||  __)   | |      |   _ (  
   | |   | || (  \ \ |  ( \ \   | |      | (   ) || (      | |      |  ( \ \ 
   | (___) || )___) )|  /  \ \  | (____/\| )   ( || (____/\| (____/\|  /  \ \
   (_______)|/ \___/ |_/    \/  (_______/|/     \|(_______/(_______/|_/    \/"
"                 Tool for naming convention check"
"                        Version : 1.12.3"
"    For help, suggestions and improvements please contact 'lpd5kor'" 

$current_version = "1.12.3"
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

    $colour = if ($DescriptiveName.Length -eq 1) { "orange" } else { "green" }

    foreach ($item in $script:UBKArray) {
        $isMatch = $item.abbrName -ceq $DescriptiveName
        $isReleased = $item.state -eq "Released"
        $isValidClassification = $item.rbClassifications -in @("Element", "ProperName")

        if (-not $isMatch -or -not $isReleased -or -not $isValidClassification) {
            continue
        }

        switch ($item.domainName) {
            "AUTOSAR" {
                if ($item.lifeCycleState -eq "Valid") {
                    return "<p style='color:$colour'>$DescriptiveName - $($item.longNameEn) (AUTOSAR)</p>"
                }
            }
            "RB" {
                if ($item.lifeCycleState -eq "Valid") {
                    return "<p style='color:orange'>$DescriptiveName - $($item.longNameEn) (RB)</p>"
                }
            }
        }

        if ($item.lifeCycleState -in @("Obsolete", "Removed") -and $null -ne $item.useInsteadAbbrName) {
            return "<p style='color:red'>$DescriptiveName ($($item.longNameEn)) - is no more valid, Try using '$($item.useInsteadAbbrName)' instead</p>"
        }
    }

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
            if ($newtext.Length -gt 2) {
                # Add to return array only if the sequence is more than 2 characters
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

    # Find the maximum length of the section text
    $maxSectionLength = 0
    foreach ($Section in $Sections) {
        if ($Section.Length -gt $maxSectionLength) {
            $maxSectionLength = $Section.Length
        }
    }
    # Estimate width in pixels (approx. 9px per character, min 150px)
    $sectionWidth = [Math]::Max($maxSectionLength * 9, 150)

    $Result = @"
<div style='display:inline-block; text-align:left; border:1px solid #ccc;'>
    <div style='font-weight:bold; text-align:center; color:#486350; padding:6px; ; border-bottom:1px solid #ccc;'>Length Check (&lt;21)</div>
    <div style='display:flex; font-weight:bold; color:#486350; border-bottom:1px solid #ccc;'>
        <div style='width:${sectionWidth}px; padding:4px; border-right:1px solid #ccc; word-break:break-all;'>Section</div>
        <div style='width:80px; padding:4px; border-right:1px solid #ccc;'>Length</div>
        <div style='width:80px; padding:4px;'>Status</div>
    </div>
"@

    foreach ($Section in $Sections) {
        $Length = $Section.Length
        $Color = if ($Length -gt 20) { "red" } else { "green" }
        $Status = if ($Length -gt 20) { "Failed" } else { "Passed" }

        $Result += @"
    <div style='display:flex; color:$Color; border-bottom:1px solid #eee;'>
       <div style='width:${sectionWidth}px; padding:4px; border-right:1px solid #ccc;'>$Section</div>
        <div style='width:80px; padding:4px; border-right:1px solid #ccc;'>$Length</div>
        <div style='width:80px; padding:4px;'>$Status</div>
    </div>
"@
    }

    $Result += "</div>"
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
function Get-AllClasses {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)

    $CodeGenerator = 'ASCET'
    $code = $PavastData.SelectSingleNode("//MSRSW/ADMIN-DATA/COMPANY-DOC-INFOS/COMPANY-DOC-INFO/SDGS/SDG/SD[@GID='MATLAB-User']")
    if ($code) { $CodeGenerator = 'MATLAB' }
 
    $AllClasses = @()
    foreach ($class in $PavastData.SelectNodes("//SW-COMPONENT-SPEC/SW-COMPONENTS/SW-CLASS[CATEGORY='CLASS']")) {
        $className = $class.SelectSingleNode("SHORT-NAME").InnerText
        
        $classDetails = [PSCustomObject]@{
            ClassName = $className
            VariablePrototypes = @()
            CalPrmPrototypes = @()
        }
        
        foreach ($varProto in $class.SelectNodes(".//SW-VARIABLE-PROTOTYPES/SW-VARIABLE-PROTOTYPE")) {
            $classDetails.VariablePrototypes += $varProto.SelectSingleNode("SHORT-NAME").InnerText
        }
        
        foreach ($calProto in $class.SelectNodes(".//SW-CALPRM-PROTOTYPES/SW-CALPRM-PROTOTYPE")) {
            $classDetails.CalPrmPrototypes += $calProto.SelectSingleNode("SHORT-NAME").InnerText
        }
        
        $AllClasses += $classDetails
    }
    
    Return $AllClasses
}
function Get-UserDefinedClasses {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)
    $CodeGenerator = 'ASCET'
    $code = $PavastData.SelectSingleNode("//MSRSW/ADMIN-DATA/COMPANY-DOC-INFOS/COMPANY-DOC-INFO/SDGS/SDG/SD[@GID='MATLAB-User']")
    if ($code) { $CodeGenerator = 'MATLAB' }

    $UserDefinedClasses = @()
    if($CodeGenerator -eq 'MATLAB') {
        foreach ($classRef in $PavastData.SelectNodes("//SW-FEATURE/SW-FEATURE-OWNED-ELEMENT-SETS/SW-FEATURE-OWNED-ELEMENT-SET/SW-FEATURE-ELEMENTS/SW-CLASS-REFS/SW-CLASS-REF")) {
            $UserDefinedClasses += $classRef.InnerText
        }
        return $UserDefinedClasses
    }

    foreach ($classRef in $PavastData.SelectNodes("//SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-CLASS-REFS/SW-CLASS-REF")) {
        $UserDefinedClasses += $classRef.InnerText
    }

  return $UserDefinedClasses
}

function Get-ClassInstances {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)
    $CodeGenerator = 'ASCET'
    $code = $PavastData.SelectSingleNode("//MSRSW/ADMIN-DATA/COMPANY-DOC-INFOS/COMPANY-DOC-INFO/SDGS/SDG/SD[@GID='MATLAB-User']")
    if ($code) { $CodeGenerator = 'MATLAB' }

    $ClassInstances = @()
    if($CodeGenerator -eq 'MATLAB') {
        foreach ($instance in $PavastData.SelectNodes("//SW-SYSTEMS/SW-SYSTEM/SW-DATA-DICTIONARY-SPEC/SW-CLASS-INSTANCES/SW-CLASS-INSTANCE")) {
            $instanceDetails = [PSCustomObject]@{
                InstanceName = $instance.SelectSingleNode("SHORT-NAME").InnerText
                ClassRef = $instance.SelectSingleNode("SW-CLASS-REF").InnerText
            }
            $ClassInstances += $instanceDetails
        }
        return $ClassInstances
    }
    foreach ($instance in $PavastData.SelectNodes("//SW-FEATURE/SW-DATA-DICTIONARY-SPEC/SW-CLASS-INSTANCES/SW-CLASS-INSTANCE")) {
        $instanceDetails = [PSCustomObject]@{
            InstanceName = $instance.SelectSingleNode("SHORT-NAME").InnerText
            ClassRef = $instance.SelectSingleNode("SW-CLASS-REF").InnerText
        }
        $ClassInstances += $instanceDetails
    }

    return $ClassInstances
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

function Get-AnalysisUserDefinedClasses{
    param ([string[]]$UserDefinedClasses, [PSCustomObject[]]$AllClasses, [string[]]$ExCalArray, [string[]]$ExVarArray, [Boolean]$BaseCompareActive, [PSCustomObject[]]$BaseAllClasses)
    
    $Result = ""
    $idVariable = "userclasses"
    $Result = "<table id='$idVariable'><thead><tr><th>User Defined Classes</th><th>Findings</th></tr></thead><tbody>"
    
    foreach ($ClassItem in $AllClasses) {
        # Check if this class is in the UserDefinedClasses array
        if ($UserDefinedClasses -notcontains $ClassItem.ClassName) {
            continue
        }
        
        # Add class name row
        $Result += "<tr><td colspan='2' style='background-color:#d3d3d3; font-weight:bold; text-align:center;'>Class: $($ClassItem.ClassName)</td></tr>"
        
        # Process VariablePrototypes
        if ($ClassItem.VariablePrototypes.Count -gt 0) {
            $Result += "<tr><td colspan='2' style='background-color:#e8e8e8; font-weight:bold;'>Variable Prototypes</td></tr>"
            
            foreach ($Variable in $ClassItem.VariablePrototypes) {
                # Splitting the variable parts
                $VariableParts = @()
                $VariableParts = $Variable.Split('_')
             
                # First column - check if variable exists in base
                if (!$BaseCompareActive) {
                    $Result += '<tr><td>' + $Variable + '</td><td>'
                }
                else {
                    # Find if this variable exists in the corresponding base class
                    $baseClass = $BaseAllClasses | Where-Object { $_.ClassName -eq $ClassItem.ClassName }
                    if ($baseClass -and ($baseClass.VariablePrototypes -contains $Variable)) {
                        $Result += '<tr><td>' + $Variable + '</td><td>'
                    }
                    else {
                        $Result += '<tr style="background-color:#aafa93"><td>' + $Variable + '</td><td>'
                    }
                }
                
                # Checking number of underscores
                if ($VariableParts.Length -gt 2) {
                    $Result += "<p style='color:red'>DGS recommend maximum of 1 '_'s, in the variable prototype. No other checks executed.</p>" 
                    $Result += '</td></tr>'
                    Continue 
                }
                
                # Checking last part if present (ExVar validation)
                if ($VariableParts.Length -gt 1) {
                    if ($ExVarArray -contains $VariableParts[1]) {
                    } else {
                        $Result += "<p style='color:red'>" + $VariableParts[1] + " is not a valid 'ExVar', so no other checks executed.</p>"
                        continue 
                    }
                }
                
                # Splitting the first part
                [String[]]$SplittedVariable = Get-SplittedArray($VariableParts[0])
               
                # Checking <pp>    
                $Result += Get-Comparepp -pp $SplittedVariable[0]
            
                # Checking descriptive name
                $VariableCounter = 1
                while ($VariableCounter -lt $SplittedVariable.Length) {
                    $Result += Get-CompareDescriptiveName -DescriptiveName $SplittedVariable[$VariableCounter]
                    $VariableCounter++
                }

                # Continuous Capital letter check
                [String[]]$SplittedVariable = Get-ContinuousCapitalArray -Unsplitted $VariableParts[0]
                    
                if ($SplittedVariable.Length -gt 0) { $Result += "<p><u>Continuous capital letter check</u></p>" }
                
                $MessageCounter = 0
                while ($MessageCounter -lt $SplittedVariable.Length) {
                    $Result += Get-CompareCapitalName -DescriptiveName $SplittedVariable[$MessageCounter]
                    $MessageCounter++
                }
                          
                # Length check
                $Result += Get-LengthCheckResult -CIdentifier $VariableParts[0]
                $Result += '</td></tr>'
            }
        }
        
        # Process CalPrmPrototypes
        if ($ClassItem.CalPrmPrototypes.Count -gt 0) {
            $Result += "<tr><td colspan='2' style='background-color:#e8e8e8; font-weight:bold;'>Calibration Parameter Prototypes</td></tr>"
            
            foreach ($Variable in $ClassItem.CalPrmPrototypes) {
                # Splitting the calibration parts
                $VariableParts = @()
                $VariableParts = $Variable.Split('_')
             
                # First column - check if calibration exists in base
                if (!$BaseCompareActive) {
                    $Result += '<tr><td>' + $Variable + '</td><td>'
                }
                else {
                    # Find if this calibration exists in the corresponding base class
                    $baseClass = $BaseAllClasses | Where-Object { $_.ClassName -eq $ClassItem.ClassName }
                    if ($baseClass -and ($baseClass.CalPrmPrototypes -contains $Variable)) {
                        $Result += '<tr><td>' + $Variable + '</td><td>'
                    }
                    else {
                        $Result += '<tr style="background-color:#aafa93"><td>' + $Variable + '</td><td>'
                    }
                }
             
                # Checking number of underscores for calibrations
                if ($VariableParts.Length -ne 2) {
                    $Result += "<p style='color:red'>Should have exact 1 '_'s in the name.<br>No other checks executed</p>"
                    $Result += '</td></tr>'
                    Continue
                }

                # Checking last part (ExCal validation)
                if ($ExCalArray -contains $VariableParts[1]) {
                } else {
                    $Result += "<p style='color:red'>" + $VariableParts[1] + " is not a valid 'EXCal', so no other checks executed.</p>"
                    continue 
                }
               
                # Splitting the first part
                [String[]]$SplittedVariable = Get-SplittedArray($VariableParts[0])
               
                # Checking <pp>    
                $Result += Get-Comparepp -pp $SplittedVariable[0]
            
                # Checking descriptive name
                $VariableCounter = 1
                while ($VariableCounter -lt $SplittedVariable.Length) {
                    $Result += Get-CompareDescriptiveName -DescriptiveName $SplittedVariable[$VariableCounter]
                    $VariableCounter++
                }
                
                # Continuous Capital letter check
                [String[]]$SplittedVariable = Get-ContinuousCapitalArray -Unsplitted $VariableParts[0]
                    
                if ($SplittedVariable.Length -gt 0) { $Result += "<p><u>Continuous capital letter check</u></p>" }
                
                $MessageCounter = 0
                while ($MessageCounter -lt $SplittedVariable.Length) {
                    $Result += Get-CompareCapitalName -DescriptiveName $SplittedVariable[$MessageCounter]
                    $MessageCounter++
                }
                          
                # Length check
                $Result += Get-LengthCheckResult -CIdentifier $VariableParts[0]
                $Result += '</td></tr>'
            }
        }
    }
    
    $Result += "</tbody></table>"
    Return $Result
}
function Get-AnalysisClassInstance {
    param (
        [string[]]$UserDefinedClasses,
        [PSCustomObject[]]$AllClasses,
        [PSCustomObject[]]$ClassInstances,
        [string]$IdIn,
        [Boolean]$BaseCompareActive,
        [PSCustomObject[]]$BaseClassInstances,
        [PSCustomObject[]]$ClassInstanceExtensions
    )
    
    $Result = ""
    $idVariable = "classinstances"
    $Result = "<table id='$idVariable'><thead><tr><th>Class Instances</th><th>Findings</th></tr></thead><tbody>"
    foreach ($Instance in $ClassInstances) {
        # Check if the instance's class exists in AllClasses
        # Determine the expected extension for this class instance
        $extension = $null
        # Check if this is a user-defined class
        if ($UserDefinedClasses -contains $Instance.ClassRef) {
                $classDefinition = $AllClasses | Where-Object { $_.ClassName -eq $Instance.ClassRef }
                # User-defined classes with VariablePrototypes use "_I" extension
                if ($classDefinition -and $classDefinition.VariablePrototypes.Count -gt 0) {
                    $extension = "_I"
                }
            }
            else {
                # For predefined classes, look up the extension from the mapping table
                $extensionMapping = $ClassInstanceExtensions | Where-Object { $_.ClassDefinition -eq $Instance.ClassRef }
            if ($extensionMapping) {
                $extension = $extensionMapping.Extension
                $classDefinition = $AllClasses | Where-Object { $_.ClassName -eq $Instance.ClassRef }
                if ($classDefinition -and $classDefinition.VariablePrototypes.Count -gt 0) {
                    $extension = $extension + "_I"
                }
            }   
        }

       
        
        # First column - check if instance exists in base
        if (!$BaseCompareActive) {
            $Result += '<tr><td>' + $Instance.InstanceName + '</td><td>'
        }
        else {
            # Check if this instance exists in base class instances
            $baseInstance = $BaseClassInstances | Where-Object { $_.InstanceName -eq $Instance.InstanceName }
            if ($baseInstance) {
                $Result += '<tr><td>' + $Instance.InstanceName + '</td><td>'
            }
            else {
                $Result += '<tr style="background-color:#aafa93"><td>' + $Instance.InstanceName + '</td><td>'
            }
        }
       

         # Special case for Efx/Mfl_DebounceState_Type - check for specific suffixes
        if ($Instance.ClassRef -eq "Efx_DebounceState_Type" -or $Instance.ClassRef -eq "Mfl_DebounceState_Type") {
            $validSuffixes = @("TON_I", "TOFF_I", "DEB_I")
            $hasValidSuffix = $false
            foreach ($suffix in $validSuffixes) {
            if ($Instance.InstanceName.EndsWith($suffix)) {
                $hasValidSuffix = $true
                $extension = $suffix
                break
            }
            }
            
            if (-not $hasValidSuffix) {
            $Result += "<p style='color:red'>Instance of class '" + $Instance.ClassRef + "' should end with one of the following suffixes: " + ($validSuffixes -join ", ") + ".
            No other checks executed.</p>"
            continue
            }
        }


        
        # Splitting the instance name parts
        $ClassinstanceWithoutExtension = $Instance.InstanceName.Replace($extension, "")
        $InstanceParts = @()
        $InstanceParts = $ClassinstanceWithoutExtension.Split('_')


        # Checking number of underscores
        if ($InstanceParts.Length -gt 2 -or $InstanceParts.Length -lt 1) {
            $Result += "<p style='color:red'>DGS recommend maximum of 2 '_' and minimum of 1 '_'s in class instance name. No other checks executed.</p>"
            $Result += '</td></tr>'
            Continue
        }
        
        # Checking <Id> matching
        $Result += Get-IdCompareResult -MessagePartIn $InstanceParts[0] -idIn $IdIn
        
        # If there's a second part, analyze it
        if ($InstanceParts.Length -gt 1) {
            # Splitting the second part
            [String[]]$SplittedInstance = Get-SplittedArray($InstanceParts[1])
            
            # Checking descriptive names
            $InstanceCounter = 0
            while ($InstanceCounter -lt $SplittedInstance.Length) {
                $Result += Get-CompareDescriptiveName -DescriptiveName $SplittedInstance[$InstanceCounter]
                $InstanceCounter++
            }
            
            # Continuous Capital letter check
            [String[]]$ContinuousCapitals = Get-ContinuousCapitalArray -Unsplitted $InstanceParts[1]
            
            if ($ContinuousCapitals.Length -gt 0) { 
                $Result += "<p><u>Continuous capital letter check</u></p>" 
            }
            
            $CapitalCounter = 0
            while ($CapitalCounter -lt $ContinuousCapitals.Length) {
                $Result += Get-CompareCapitalName -DescriptiveName $ContinuousCapitals[$CapitalCounter]
                $CapitalCounter++
            }
        }
         # Extension check
        if ($null -ne $extension) {
            if ($Instance.InstanceName.EndsWith($extension)) {
                $Result += "<p style='color:green'>$extension - Extension check Passed</p>"
            }
            else {
                $Result += "<p style='color:red'>Extension check Failed - Instance should end with '$extension'</p>"
            }
        }
        else {
            if ($Instance.InstanceName.EndsWith("_I")) {
                $Result += "<p style='color:red'>Extension check - Instance should not end with '_I' when no memory element inside the class.</p>"
            }
            else {
            }
        }
        # Length check
        $Result += Get-LengthCheckResult -CIdentifier $ClassinstanceWithoutExtension
        $Result += '</td></tr>'
    }  
    $Result += "</tbody></table>"
    Return $Result
}

Write-Output "    Reading pavast..."


[String[]]$Calibrations = @()
[String[]]$Messages = @()
[String[]]$Variables = @()
[String[]]$UserDefinedClasses = @()
[PSCustomObject[]]$AllClasses = @()
[PSCustomObject[]]$ClassInstances = @()

[String[]]$BaseCalibrations = @()
[String[]]$BaseMessages = @()
[String[]]$BaseVariables = @()
[String[]]$BaseUserDefinedClasses = @()
[PSCustomObject[]]$BaseAllClasses = @()
[PSCustomObject[]]$BaseClassInstances = @()
$FCName = Get-FCName($PavastFilePath)
$Messages = Get-Messages($PavastFilePath)
$Calibrations = Get-Calibrations($PavastFilePath)
$Variables = Get-Variables($PavastFilePath)
$UserDefinedClasses = Get-UserDefinedClasses($PavastFilePath)
$AllClasses = Get-AllClasses($PavastFilePath)
$ClassInstances = Get-ClassInstances($PavastFilePath)
$ClassInstanceExtensions = @(
    [PSCustomObject]@{ ClassDefinition = "TimerRetrigger"; Extension = "TR" }
    [PSCustomObject]@{ ClassDefinition = "IpolDelta"; Extension = "ID" }
    [PSCustomObject]@{ ClassDefinition = "Median_5"; Extension = "M5" }
    [PSCustomObject]@{ ClassDefinition = "Modulo"; Extension = "MOD" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Abs"; Extension = "ABS" }
    [PSCustomObject]@{ ClassDefinition = "Srv_AbsDiff"; Extension = "ABSD" }
    [PSCustomObject]@{ ClassDefinition = "Srv_AbsLimit"; Extension = "ABSL" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Average"; Extension = "AVRG" }
    [PSCustomObject]@{ ClassDefinition = "Srv_AvrgArr"; Extension = "AVRGA" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Mod"; Extension = "MODZ" }
    [PSCustomObject]@{ ClassDefinition = "Srv_MulAdd"; Extension = "MA" }
    [PSCustomObject]@{ ClassDefinition = "Srv_MulDiv"; Extension = "MD" }
    [PSCustomObject]@{ ClassDefinition = "Srv_MulShRight"; Extension = "MSR" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Sqrt"; Extension = "SQRT" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorK"; Extension = "IK" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorKEnabled"; Extension = "IKE" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorKLimited"; Extension = "IKL" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorT"; Extension = "IT" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorTEnabled"; Extension = "ITE" }
    [PSCustomObject]@{ ClassDefinition = "IntegratorTLimited"; Extension = "ITL" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntLimParam_t"; Extension = "INTLt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Int"; Extension = "INT" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntLimt"; Extension = "INTL" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IWinParam_t"; Extension = "IWt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Iwin"; Extension = "IW" }
    [PSCustomObject]@{ ClassDefinition = "Srv_PIWin"; Extension = "PIW" }
    [PSCustomObject]@{ ClassDefinition = "DigitalLowpass"; Extension = "DL" }
    [PSCustomObject]@{ ClassDefinition = "LowpassK"; Extension = "LK" }
    [PSCustomObject]@{ ClassDefinition = "LowpassKEnabled"; Extension = "LKE" }
    [PSCustomObject]@{ ClassDefinition = "LowpassT"; Extension = "LT" }
    [PSCustomObject]@{ ClassDefinition = "LowpassTEnabled"; Extension = "LTE" }
    [PSCustomObject]@{ ClassDefinition = "SrvF_PT1Param_t"; Extension = "PT1t" }
    [PSCustomObject]@{ ClassDefinition = "Srv_PT1"; Extension = "PT1" }
    [PSCustomObject]@{ ClassDefinition = "SrvF_PT1"; Extension = "FPT1" }
    [PSCustomObject]@{ ClassDefinition = "ClosedInterval"; Extension = "CI" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntervClsd"; Extension = "CI" }
    [PSCustomObject]@{ ClassDefinition = "GreaterZero"; Extension = "GZ" }
    [PSCustomObject]@{ ClassDefinition = "LeftOpenInterval"; Extension = "LOI" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntervLOpn"; Extension = "LOI" }
    [PSCustomObject]@{ ClassDefinition = "OpenInterval"; Extension = "OI" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntervOpn"; Extension = "OI" }
    [PSCustomObject]@{ ClassDefinition = "RightOpenInterval"; Extension = "ROI" }
    [PSCustomObject]@{ ClassDefinition = "Srv_IntervROpn"; Extension = "ROI" }
    [PSCustomObject]@{ ClassDefinition = "Counter_Timer"; Extension = "CD" }
    [PSCustomObject]@{ ClassDefinition = "CountDownEnabled"; Extension = "CDE" }
    [PSCustomObject]@{ ClassDefinition = "Counter"; Extension = "CTR" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Counter"; Extension = "CTR" }
    [PSCustomObject]@{ ClassDefinition = "CounterEnabled"; Extension = "CE" }
    [PSCustomObject]@{ ClassDefinition = "StopWatch"; Extension = "SW" }
    [PSCustomObject]@{ ClassDefinition = "StopWatchEnabled"; Extension = "SWE" }
    [PSCustomObject]@{ ClassDefinition = "Timer"; Extension = "T" }
    [PSCustomObject]@{ ClassDefinition = "TimerEnabled"; Extension = "TE" }
    [PSCustomObject]@{ ClassDefinition = "TimerRetriggerEnabled"; Extension = "TRE" }
    [PSCustomObject]@{ ClassDefinition = "Srv_SWTmr"; Extension = "SWT" }
    [PSCustomObject]@{ ClassDefinition = "Delay"; Extension = "DS" }
    [PSCustomObject]@{ ClassDefinition = "DelaySignalEnabled"; Extension = "DSE" }
    [PSCustomObject]@{ ClassDefinition = "DelayValue"; Extension = "DV" }
    [PSCustomObject]@{ ClassDefinition = "DelayValueEnabled"; Extension = "DVE" }
    [PSCustomObject]@{ ClassDefinition = "TurnOffDelay"; Extension = "TOFF" }
    [PSCustomObject]@{ ClassDefinition = "TurnOnDelay"; Extension = "TON" }
    [PSCustomObject]@{ ClassDefinition = "TurnOffDelayvariable"; Extension = "TOFFV" }
    [PSCustomObject]@{ ClassDefinition = "TurnOnDelayvariable"; Extension = "TONV" }
    [PSCustomObject]@{ ClassDefinition = "TurnOffDelayvariableNoMem"; Extension = "TOFFVNM" }
    [PSCustomObject]@{ ClassDefinition = "TurnOnDelayvariableNoMem"; Extension = "TONVNM" }
    [PSCustomObject]@{ ClassDefinition = "Srv_TrnOffDly"; Extension = "TOffD" }
    [PSCustomObject]@{ ClassDefinition = "TurnOnDelayA"; Extension = "TOnD" }
    [PSCustomObject]@{ ClassDefinition = "TurnOffDelayA"; Extension = "TOffD" }
    [PSCustomObject]@{ ClassDefinition = "Srv_TrnOnDly"; Extension = "TOnD" }
    [PSCustomObject]@{ ClassDefinition = "DelayTime"; Extension = "DTds" }
    [PSCustomObject]@{ ClassDefinition = "DelayTime_dsoptimized"; Extension = "DTdsOpt" }
    [PSCustomObject]@{ ClassDefinition = "DelayTime_Tt"; Extension = "DTTt" }
    [PSCustomObject]@{ ClassDefinition = "DelayTime_Tt optimized"; Extension = "DTTtOpt" }
    [PSCustomObject]@{ ClassDefinition = "Memory"; Extension = "A" }
    [PSCustomObject]@{ ClassDefinition = "AccumulatorEnabled"; Extension = "AE" }
    [PSCustomObject]@{ ClassDefinition = "AccumulatorLimited"; Extension = "AL" }
    [PSCustomObject]@{ ClassDefinition = "RSFlipFlop"; Extension = "FF" }
    [PSCustomObject]@{ ClassDefinition = "Srv_RSFF"; Extension = "FF" }
    [PSCustomObject]@{ ClassDefinition = "DeltaOneStep"; Extension = "DOS" }
    [PSCustomObject]@{ ClassDefinition = "EdgeBi"; Extension = "EB" }
    [PSCustomObject]@{ ClassDefinition = "Srv_EgeBipol"; Extension = "EB" }
    [PSCustomObject]@{ ClassDefinition = "EdgeBiNoMem"; Extension = "EBNM" }
    [PSCustomObject]@{ ClassDefinition = "EdgeFalling"; Extension = "EF" }
    [PSCustomObject]@{ ClassDefinition = "Srv_EdgeFalling"; Extension = "EF" }
    [PSCustomObject]@{ ClassDefinition = "EdgeFallingNoMem"; Extension = "EFNM" }
    [PSCustomObject]@{ ClassDefinition = "EdgeRising"; Extension = "ER" }
    [PSCustomObject]@{ ClassDefinition = "Srv_EdgeRising"; Extension = "ER" }
    [PSCustomObject]@{ ClassDefinition = "EdgeRisingNoMem"; Extension = "ERNM" }
    [PSCustomObject]@{ ClassDefinition = "Mux1of4"; Extension = "MUX4" }
    [PSCustomObject]@{ ClassDefinition = "Mux1of8"; Extension = "MUX8" }
    [PSCustomObject]@{ ClassDefinition = "Srv_DebounceParam_t"; Extension = "DEBt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Debounce"; Extension = "DEB" }
    [PSCustomObject]@{ ClassDefinition = "Srv_RampParam_t"; Extension = "RMPt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Ramp"; Extension = "RMP" }
    [PSCustomObject]@{ ClassDefinition = "Srv_RampSwitch"; Extension = "RMPS" }
    [PSCustomObject]@{ ClassDefinition = "Mx17_DSM"; Extension = "RTR" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_Delta_RSP"; Extension = "HDR" }
    [PSCustomObject]@{ ClassDefinition = "Srv_HystDR"; Extension = "HDR" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_Delta_RSP_SeqCall"; Extension = "HDRSC" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_LSP_Delta"; Extension = "HLD" }
    [PSCustomObject]@{ ClassDefinition = "Srv_HystLD"; Extension = "HLD" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_LSP_Delta_SeqCall"; Extension = "HLDSC" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_LSP_RSP"; Extension = "HLR" }
    [PSCustomObject]@{ ClassDefinition = "Srv_HystLR"; Extension = "HLR" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_LSP_RSP_SeqCall"; Extension = "HLRSC" }
    [PSCustomObject]@{ ClassDefinition = "Srv_HystCHD"; Extension = "HMD" }
    [PSCustomObject]@{ ClassDefinition = "Hysteresis_MSP_DeltaHalf_SeqCall"; Extension = "HMDSC" }
    [PSCustomObject]@{ ClassDefinition = "Limiter"; Extension = "LIM" }
    [PSCustomObject]@{ ClassDefinition = "Srv_Limit"; Extension = "LIM" }
    [PSCustomObject]@{ ClassDefinition = "Signum"; Extension = "SGN" }
    [PSCustomObject]@{ ClassDefinition = "Srv_DT1Param_t"; Extension = "DT1t" }
    [PSCustomObject]@{ ClassDefinition = "Srv_DT1"; Extension = "DT1" }
    [PSCustomObject]@{ ClassDefinition = "Srv_DT1WinParam_t"; Extension = "DT1Wt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_DT1Win"; Extension = "DT1W" }
    [PSCustomObject]@{ ClassDefinition = "Srv_LimitParam_t"; Extension = "LIMt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_PWinParam_t"; Extension = "PWt" }
    [PSCustomObject]@{ ClassDefinition = "Srv_PWin"; Extension = "PW" }
    [PSCustomObject]@{ ClassDefinition = "Efx_DebounceState_Type"; Extension = "DEB" }
    [PSCustomObject]@{ ClassDefinition = "Mfl_DebounceState_Type"; Extension = "DEB" }
    [PSCustomObject]@{ ClassDefinition = "Mfl_StateRamp_Type"; Extension = "RMP" }
    [PSCustomObject]@{ ClassDefinition = "Efx_StateRamp_Type"; Extension = "RMP" }
    [PSCustomObject]@{ ClassDefinition = "Mfl_StatePT1_Type"; Extension = "PT1" }
    [PSCustomObject]@{ ClassDefinition = "Mfl_StateDT1Typ1_Type"; Extension = "DT1" }
    [PSCustomObject]@{ ClassDefinition = "Efx_StatePT1_Type"; Extension = "PT1" }
    [PSCustomObject]@{ ClassDefinition = "SrvX_RampState_Type"; Extension = "RMP" }
    [PSCustomObject]@{ ClassDefinition = "Efx_StateDT1Typ2_Type"; Extension = "DT1" }
    [PSCustomObject]@{ ClassDefinition = "Efx_StateDT1Typ1_Type"; Extension = "DT1" }
    [PSCustomObject]@{ ClassDefinition = "Mfl_StateI_Type"; Extension = "XX" }
)

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
        $BaseUserDefinedClasses = Get-UserDefinedClasses($BasePavastFilePath)
        $BaseAllClasses = Get-AllClasses($BasePavastFilePath)
        $BaseClassInstances = Get-ClassInstances($BasePavastFilePath)
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
  <li style='padding-bottom:6px'>This report is intended to serve as an additional reference for your implementation. A manual review of the variables is still strongly recommended.</li>
  <li style='padding-bottom:6px'>When updating the names of existing variables (to address identified warnings), please ensure you carefully verify that the change does not affect other parts of the design.</li>
<li style='padding-bottom:6px; color:red;'>Checks for class instance names and instance‑specific variables are currently in Beta.</li>
    <li style='padding-bottom:6px; color:red;'>For MATLAB‑generated code, checks related to rising edges, falling edges, and flip‑flop detection cannot be performed.</li>
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
$reportHTML += '<br><br>'
Write-Output "    Analyzing class instances..."
$reportHTML += Get-AnalysisClassInstance -UserDefinedClasses $UserDefinedClasses -AllClasses $AllClasses -ClassInstances $ClassInstances -IdIn $Id -BaseCompareActive $BaseCompareActive -BaseClassInstances $BaseClassInstances -ClassInstanceExtensions $ClassInstanceExtensions  
$reportHTML += '<br><br>'
Write-Output "    Analyzing user defined classes..."
$reportHTML += Get-AnalysisUserDefinedClasses -UserDefinedClasses $UserDefinedClasses -AllClasses $AllClasses -ExCalArray $ExVarCalibArray -ExVarArray $ExVarVariableArray -BaseCompareActive $BaseCompareActive -BaseAllClasses $BaseAllClasses  


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
	var ids = ["messages", "variables", "calibrations","userclasses","classinstances"];
    for (iCount =0; iCount <5; iCount++) {
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
		if (td.length>1) {
			var para = td[1].getElementsByTagName("p");
			for (p=0;p<para.length; p++) {
				if (para[p].style.color=="blue") {sugg=true;allok=false;}
				if (para[p].style.color=="red") {errprs=true;allok=false;}
				if (para[p].style.color=="orange") {conf=true;allok=false;}
			}
		} else if (td.length==1) {
			// Header rows with colspan - always show them
			tr[r].style.display = "";
			continue;
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
var ids = ["messages", "variables", "calibrations","userclasses","classinstances"];
for (iCount =0; iCount <5; iCount++) {
 tableVariables = document.getElementById(ids[iCount]);

var tr = tableVariables.getElementsByTagName("tr");
	for (r = 1; r < tr.length; r++) {
		var allok=true;
		var sugg=false;
		var errprs=false;
		var conf=false;
		var td = tr[r].getElementsByTagName("td");
		if (td.length>1) {
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
    $resp = Invoke-WebRequest $uriFeatureTracking -Method GET -TimeoutSec 10 -UseBasicParsing
    }
    catch {
        Write-Output "    Tool tracking failed 01"
    }
    try {
     $resp = Invoke-WebRequest $uriCountTracking -Method GET -TimeoutSec 10 -UseBasicParsing
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


