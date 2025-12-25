"
             ______   _          _______           _______  _______  _       
   |\     /|(  ___ \ | \    /\  (  ____ \|\     /|(  ____ \(  ____ \| \    /\
   | )   ( || (   ) )|  \  / /  | (    \/| )   ( || (    \/| (    \/|  \  / /
   | |   | || (__/ / |  (_/ /   | |      | (___) || (__    | |      |  (_/ / 
   | |   | ||  __ (  |   _ (    | |      |  ___  ||  __)   | |      |   _ (  
   | |   | || (  \ \ |  ( \ \   | |      | (   ) || (      | |      |  ( \ \ 
   | (___) || )___) )|  /  \ \  | (____/\| )   ( || (____/\| (____/\|  /  \ \
   (_______)|/ \___/ |_/    \/  (_______/|/     \|(_______/(_______/|_/    \/"
   "A small tool to check naming conventions"
   "Contact : lpd5kor"


$Ready = $True

While($Ready)
{

$PavastFilePath  = Read-Host "Pavast file path"

if($PavastFilePath -ne "")
{
if(Test-Path $PavastFilePath -PathType leaf){

if(($PavastFilePath.Substring($PavastFilePath.Length - 11) -eq "_pavast.xml") -or ($PavastFilePath.Substring($PavastFilePath.Length - 15) -eq "_specpavast.xml")){$Ready = $False}Else{"Please enter a valid pavast path"}

}
else{"Please enter a valid pavast path"}
}

}

$Script:htmlPath = "C:\Users\"+$env:USERNAME.ToLower()+"\AppData\Local\Temp\report.html"
$script:UBKDownlaodPath = "C:\Users\"+$env:USERNAME.ToLower()+"\AppData\Local\Temp\ubk_keyword_list.csv"

#If not downloaded today download again
if((Test-Path $script:UBKDownlaodPath) -and (((Get-Item $script:UBKDownlaodPath).LastWriteTime).Date -eq (Get-Date).Date)){
    echo "Latest UBK database already present..."
}
else
{
    echo "Downloading latest UBK database..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest "http://rb-ubkklpro.de.bosch.com:38121/apex/f?p=2100:205:0::NO:::" -outfile $script:UBKDownlaodPath -ErrorAction Stop
    echo "Download complete..."
}


function Get-CompareDescriptiveName {
    param ( [string]$DescriptiveName )
    $Found = $False
    $script:UBKArray | ForEach-Object {
        if ($_."Abbr Name" -ceq $DescriptiveName -and $_."Life Cycle State" -eq "Valid" -and $_."Domain Name" -eq "AUTOSAR" -and  ($_."Element" -eq "x" -or $_."ProperName" -eq "x")) {
            $Found = $True
            $LongName = $_."Long Name En"
            }
        }

    if($Found){ #Found an AUTOSAR name
        if($DescriptiveName.Length -eq 1){$Result = "<p style='color:orange'>$DescriptiveName - "+ $LongName+" (AUTOSAR)</p>" }else{$Result = "<p style='color:green'>$DescriptiveName - "+ $LongName+" (AUTOSAR)</p>"}
        }
    else {
        $script:UBKArray | ForEach-Object {
        if ($_."Abbr Name" -ceq $DescriptiveName -and $_."Life Cycle State" -eq "Valid" -and $_."Domain Name" -eq "RB" -and  ($_."Element" -eq "x" -or $_."ProperName" -eq "x")) {
            $Found = $True
            $LongName = $_."Long Name En"
            }
        }
        if($Found) {
            $Result = "<p style='color:orange'>$DescriptiveName - "+ $LongName+" (RB)</p>"}
        else {
            $Result ="<p style='color:red'>$DescriptiveName - not present in UBK abbrevations </p>"
            }
        }
        
    return $Result
    }


function Get-IdCompareResult {
    param ([string]$MessagePartIn, [string]$idIn )
     if($MessagePartIn -ceq $idIn) {$Result= "<p style='color:green'>"+ $MessagePartIn +"</p>" } else {$Result = "<p style='color:red'>"+ $MessagePartIn + " - <Id> not equal to $idIn (Id)</p>"}
     Return $Result
    }


#Checking the validity of pp
function Get-Comparepp {
    param ([string[]]$pp)
         
    $Result ="<p style='color:red'> $pp - not a valid Physical or Logical 'pp' </p>"
    $script:UBKArray | ForEach-Object {
        if( ($_."Logical" -eq "x" -or $_."Physical" -eq "x" ) -and ($_."Life Cycle State" -eq "Valid") -and ($pp -ceq $_."Abbr Name")){ $Result = "<p style='color:green'>$pp - "+$_."Long Name En"+"</p>"}
        }

   if($pp -eq 'r'){$Result = "<p style='color:Orange'> $pp -  'r'=resistance, 'rat'=ratio </p>"}
   if($pp -eq 'mask'){$Result = "<p style='color:Orange'> $pp -  only valid for signal qualifier(Sq) mask calibrations</p>"}
   return $Result
    }

#Splitting the string to Abbrevations
function Get-SplittedArray {
    param ([string[]]$Unsplitted)
    [char[]]$newtext  =@()
    foreach ($character in $Unsplitted.ToCharArray())
        {
        if ([Char]::IsUpper($character) -or [Char]::ISNumber($character)){$newtext +='*'}
        $newtext += $character
        }
    $Result = -Join $newtext
    $Result = $Result.TrimStart('*')
    return $Result.Split('*')
    }

function Get-ContinuousCapitalArray {
    param ([string[]]$Unsplitted)
    [char[]]$newtext  =@()
    #To take all the values from last of the message
    $Unsplitted = $Unsplitted +"X"
    [string[]]$StringArray =@()
    [string[]]$ReturnArray=@()
    foreach ($character in $Unsplitted.ToCharArray())
        {
        if ([Char]::IsUpper($character)){$newtext += $character;$Once=$True;}else{if($Once){$newtext += "*";$Once=$False} }
        }
    $Result = -Join $newtext
    $Result = $Result.Trim('*')
    $StringArray=  $Result.Split('*')

    $Count = 0
    while($Count -lt $StringArray.Length)
        {
        if($StringArray[$Count].Length -gt 2){$ReturnArray += $StringArray[$Count].SubString(0,$StringArray[$Count].Length -1)}
        $Count++
        }


    return $ReturnArray
    }

function Get-CompareCapitalName{
    param ( [string]$DescriptiveName )

    $Result =""
  
    $script:UBKArray | ForEach-Object {
        if( ($_."Domain Name" -eq "AUTOSAR" -or $_."Domain Name" -eq "RB" ) -and $_."Life Cycle State" -eq "Valid" -and ($_."Abbr Name" -ceq $DescriptiveName)){ 
        $Result = "<p style='color:green'>$DescriptiveName - "+ $_."Long Name En"+"</p>"
        }
     }
     $DescriptiveNameModified = $DescriptiveName.SubString(0,1) + $DescriptiveName.SubString(1, $DescriptiveName.Length - 1).ToLower()
 
     if($Result -eq ""){
            $script:UBKArray | ForEach-Object {

                if( ($_."Domain Name" -eq "AUTOSAR" -or $_."Domain Name" -eq "RB" ) -and $_."Life Cycle State" -eq "Valid" -and ($_."Abbr Name" -ceq $DescriptiveNameModified)){ 
                $Result = "<p style='color:Blue'>$DescriptiveName - not present in UBK, Recommendation - $DescriptiveNameModified"+"</p>"}}
                }


    if($Result -eq ""){"<p style='color:red'>$DescriptiveName - not present in UBK abbrevations</p>"}
    return $Result
    }


echo "Reading pavast..."
$script:UBKArray = Import-Csv $script:UBKDownlaodPath -delimiter ";"

[String[]]$Calibrations = @()
[String[]]$Messages = @()



$SWSYSTEMS = 'SW-SYSTEMS'
$SWSYSTEM = 'SW-SYSTEM'
$ADMINDATA = 'ADMIN-DATA'
$COMPANYDOCINFOS = 'COMPANY-DOC-INFOS'
$COMPANYDOCINFO= 'COMPANY-DOC-INFO'
$SWCOMPONENTSPEC = 'SW-COMPONENT-SPEC'
$SWCOMPONENTS = 'SW-COMPONENTS'
$SWFEATURE = 'SW-FEATURE'
$SHORTNAME = 'SHORT-NAME'
$SWFEATUREOWNEDELEMENTSETS = 'SW-FEATURE-OWNED-ELEMENT-SETS'
$SWFEATUREOWNEDELEMENTSET ='SW-FEATURE-OWNED-ELEMENT-SET'
$SWFEATUREOWNEDELEMENTS ='SW-FEATURE-OWNED-ELEMENTS'
$SWFEATUREELEMENTS = 'SW-FEATURE-ELEMENTS'
$SWCALPRMREFS = 'SW-CALPRM-REFS'
$SWCALPRMREF = 'SW-CALPRM-REF'
$USERDEFINEDTYPE = 'USER-DEFINED-TYPE'
$SWVARIABLEREFS = 'SW-VARIABLE-REFS'
$SWVARIABLEREF = 'SW-VARIABLE-REF'
$SWVARIABLEREFSYSCOND = 'SW-VARIABLE-REF-SYSCOND'
$SWCALPRMREFSYSCOND = 'SW-CALPRM-REF-SYSCOND'

$PavastData = [xml](Get-Content $PavastFilePath)


$FCName= $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SHORTNAME
 
 $CodeGenerator = ""
 $PavastData.MSRSW.$ADMINDATA.$COMPANYDOCINFOS.$COMPANYDOCINFO.SDGS.SDG.SD.GID | ForEach-Object {
 if ( $_ -eq 'ASCET-User')
    {
    $CodeGenerator = 'ASCET'
    
    }
 elseif ( $_ -eq 'MATLAB-User')
    {
    $CodeGenerator = 'MATLAB'
    }

}


if($CodeGenerator -eq 'ASCET')
{
    $Calibrations = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREFSYSCOND.$SWCALPRMREF
    if($PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF.length -gt 0)
    {
    $Calibrations += $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF
    }
    $Messages = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREFSYSCOND.$SWVARIABLEREF
    if($PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF.length -gt 0)
    {
    $Messages += $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF
    }
}
elseif($CodeGenerator -eq 'MATLAB')
{ 
    $Calibrations = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREFSYSCOND.$SWCALPRMREF
    if($PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF.length -gt 0)
    {
    $Calibrations += $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF
    }
    $Messages = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREFSYSCOND.$SWVARIABLEREF
    if($PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF.length -gt 0)
    {
     $Messages += $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF
    }
}
else
{
   Echo "Cannot read Pavast"
   Break
}

echo "Analyzing messages..."

#break
<#
Variable ::="<Id>"_"<pp>"  "<DescriptiveName>"[_"<ExVar>"]
#>

$Id = $FCName.Split("_")[0]

$Counter = 0

$reportHTML = "<!DOCTYPE html>
<html>
<head>
<style>
table {
  font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
  border-collapse: collapse;
  width: 50%;
  margin-left: auto;
  margin-right: auto;
}

td, th {
  border: 1px solid #ddd;
  padding: 2px;
  width: 25%;
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

</style>

<title>UBK check report</title>
</head>
<body>

<table><tr><th>Instructions</th></tr><tr style='text-align:center'><td>Only local static variables, exported messages and calibrations are checked. </br>Colors used and their meanings
<p style='color:Green'>All Ok</p>
<p style='color:Blue'>Suggestion</p>
<p style='color:Red'>Error</p>
<p style='color:Orange'>User confirmation needed</p>
</td></tr></table>



<p class='fcname'>$FCName</p>

<table><tr><th>Variables</th><th>Findings</th></tr>"

while ($Counter -lt $Messages.Length) {

    #Ignoring class instance variables in matlab generated pavast - 
    ###Needs better way to identify class instances
    if($Messages[$Counter].Substring($Messages[$Counter].Length - 2) -ceq '_I'){$Counter++;continue}
    
    $MessageParts =@()
    $MessageParts = $Messages[$Counter].Split('_')
    
    #First column
    $reportHTML += '<tr><td>'+ $Messages[$Counter] +'</td><td>'
       
    #Checking number of underscores in variables.
    if($MessageParts.Length -gt 3 -or $MessageParts.Length -lt 2){$reportHTML += "<p style='color:red'>DGS recommend maximum of 2 '_'s and minimum one '_'. </br>No other checks executed.</p>";$Counter++;Continue}

    #Checking <Id> matching FC name
    $reportHTML += Get-IdCompareResult $MessageParts[0] $Id
   
    #Splitting the second part of message
    [String[]]$SplittedMessage = Get-SplittedArray($MessageParts[1])
   
    #Checking <pp>    
    $reportHTML += Get-Comparepp($SplittedMessage[0])

    #Checking descriptive name
    $MessageCounter = 1
    while($MessageCounter -lt $SplittedMessage.Length){
            $reportHTML +=  Get-CompareDescriptiveName($SplittedMessage[$MessageCounter])
            $MessageCounter++}

    #Checking last part of message if it is present
    if($MessageParts.Length -gt 2){
       if(($MessageParts[2] -ceq 'MP') -or ($MessageParts[2] -ceq 'f') -or ($MessageParts[2] -ceq 'Sq') -or ($MessageParts[2] -ceq 'msg') -or ($MessageParts[2] -ceq 'f_msg')){}else{$reportHTML += "<p style='color:red'>Allowed 'ExVar's are  MP | f | msg | f_msg | Sq </p>"}
    }


    #Continuos Capital letter check
    [String[]]$SplittedMessage = Get-ContinuousCapitalArray($MessageParts[1])
        
    if($SplittedMessage.Length -gt 0){$reportHTML +="<p><u>Continuous capital letter check</u></p>"}
    #Checking descriptive name
    $MessageCounter = 0
    while($MessageCounter -lt $SplittedMessage.Length){
          $reportHTML += Get-CompareCapitalName($SplittedMessage[$MessageCounter])
          $MessageCounter++
            }
                
$Counter++
$reportHTML += '</td>'}


$reportHTML += '</table></br></br><table><tr><th>Calibrations</th><th>Findings</th></tr>'

echo "Analyzing calibrations..."

$Counter = 0
while ($Counter -lt $Calibrations.Length) {
    
    [String[]]$CalibrationParts = $Calibrations[$Counter].Split('_')
    
    #First column
    $reportHTML += '<tr><td>'+ $Calibrations[$Counter] +'</td><td>' 

    #Checking number of underscores in variables.
    if($CalibrationParts.Length -ne 3){$reportHTML += "<p style='color:red'>Should have exact 2 '_'s in the name. </br>No other checks executed</p>";$Counter++;Continue}
       
    #Checking <Id> matching FC name
    $reportHTML += Get-IdCompareResult $CalibrationParts[0] $Id

    #Splitting descriptive name
    [String[]]$SplittedCalibrations = Get-SplittedArray($CalibrationParts[1])
    
    #Checking <pp>  
    $reportHTML += Get-Comparepp($SplittedCalibrations[0])
    
    #Checking descriptive name
    $CalibPartsCounter = 1
    while($CalibPartsCounter -lt $SplittedCalibrations.Length){
            $reportHTML +=  Get-CompareDescriptiveName($SplittedCalibrations[$CalibPartsCounter])
            $CalibPartsCounter++
            }

    #Checking the ending of calibrations
    if(($CalibrationParts[2] -ceq 'C') -or
       ($CalibrationParts[2] -ceq 'CA') -or
       ($CalibrationParts[2] -ceq 'T') -or
       ($CalibrationParts[2] -ceq 'FT') -or
       ($CalibrationParts[2] -ceq 'GT') -or
       ($CalibrationParts[2] -ceq 'M') -or
       ($CalibrationParts[2] -ceq 'FM') -or
       ($CalibrationParts[2] -ceq 'GM') -or
       ($CalibrationParts[2] -ceq 'AX') -or
       ($CalibrationParts[2] -ceq 'ASC') ){} else {$reportHTML += "<p style='color:red'>'"+$CalibrationParts[2]+"' is not a valid 'ExCal'</p>"}

    #Continuos Capital letter check
    [String[]]$SplittedCalibrations = Get-ContinuousCapitalArray($CalibrationParts[1])
        
    if($SplittedCalibrations.Length -gt 0){$reportHTML +="<p><u>Continuous capital letter check</u></p>"}

    #Checking Capital name
    $CalibPartsCounter = 0
    while($CalibPartsCounter -lt $SplittedCalibrations.Length){
          $reportHTML += Get-CompareCapitalName($SplittedCalibrations[$CalibPartsCounter])
          $CalibPartsCounter++
            }
    
    $Counter++
    $reportHTML += '</td>'
}



$reportHTML += ' </tr></table></body></html>'

#Final writing of test report

if (Test-Path $Script:htmlPath -PathType leaf){
remove-item $Script:htmlPath
}
if(New-Item $Script:htmlPath){}
Set-content -Path $Script:htmlPath  -Value $reportHTML

Invoke-item $Script:htmlPath


