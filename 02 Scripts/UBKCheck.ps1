$Script:htmlPath = "C:\Users\"+$env:USERNAME.ToLower()+"\AppData\Local\Temp\report.html"


function Get-CompareDescriptiveName {
    param ( [string]$DescriptiveName )
    $Result ="<p style='color:red'>$DescriptiveName - not present in UBK abbrevations </p>"
    $script:UBKArray | ForEach-Object {
        if( ($_."Domain Name" -eq "AUTOSAR" -or $_."Domain Name" -eq "RB" ) -and $_."Life Cycle State" -eq "Valid" -and ($_."Abbr Name" -ceq $DescriptiveName)){ 
        if($DescriptiveName.Length -eq 1){$Result = "<p style='color:orange'>$DescriptiveName - "+ $_."Long Name En"+"</p>" }else{$Result = "<p style='color:green'>$DescriptiveName - "+ $_."Long Name En"+"</p>"}}
        }
    return $Result
    }


#Checking the validity of pp
function Get-Comparepp {
    param ([string[]]$pp)
         
    $Result ="<p style='color:red'> $pp - not a valid Physical or Logical 'pp' </p>"
    $script:UBKArray | ForEach-Object {
        if( ($_."Logical" -eq "x" -or $_."Physical" -eq "x" ) -and ($_."Life Cycle State" -eq "Valid") -and ($pp -ceq $_."Abbr Name")){ $Result = "<p style='color:green'>$pp - "+$_."Long Name En"+"</p>"}
        }

   if($pp -eq 'r'){$Result = "<p style='color:blue'> $pp -  'r'=resistance, 'rat'=ratio </p>"}
   return $Result
    }

#Splitting the string to Abbrevations
function Get-SplittedArray {
    param ([string[]]$Unsplitted)
    [char[]]$newtext  =@()
    $Final = @()
    foreach ($character in $Unsplitted.ToCharArray())
        {
        if ([Char]::IsUpper($character)){$newtext +='*'}
        $newtext += $character
        }
    $Result = -Join $newtext
    $Result = $Result.TrimStart('*')
    return $Result.Split('*')
    }








[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="windowCheckName"
    Title=" Naming conventions" 
    Height="Auto"
    Width="500" 
    WindowStyle="ToolWindow" 
    Background="White" 
    ResizeMode = "NoResize"
    SizeToContent="Height" >

    <!-- Border start -->
    <Border Padding="10" >
        <StackPanel>
        <TextBlock Text="UBK CSV path : "></TextBlock>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="3*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <TextBox x:Name = "TextboxCSVPath"
                Width="Auto"
                Padding ="3"
                Margin ="0 3 10 10"
                TextWrapping="Wrap"
                Grid.Column="0"
                Grid.Row="0" />

                <Button x:Name = "ButtonCSVBrowse"
                Content="Browse"
                Margin ="0 3 5 10"
                Height = "25"
                Grid.Column="1"
                Grid.Row="0" 
                Background="LightBlue" 
                BorderBrush="Blue" 
                BorderThickness=".5" />
            </Grid>
        <TextBlock Text="Pavast file path : "></TextBlock>
        
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="3*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name = "TextboxPavastPath"
                Width="Auto"
                Grid.Column="0"
                Padding ="3"
                TextWrapping="Wrap"
                Margin ="0 3 10 10"
                Grid.Row="0"/>
                <Button x:Name = "ButtonPavastBrowse"
                Content="Browse"
                Margin ="0 3 5 10"
                Height = "25"
                Grid.Row="0"
                Grid.Column="1"
                Background="LightBlue" 
                BorderBrush="Blue" 
                BorderThickness=".5" />
            </Grid>
    
    
     <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        
        <Button x:Name = "ButtonStartRun"
            Content="Run"
            Grid.Column="0"
            Margin ="175 5 175 0"
            Padding ="10"
            Grid.Row="0"
            Background="LightBlue" 
            BorderBrush="Blue" 
            BorderThickness=".5"/>
        
    </Grid>
    
    </StackPanel>

    </Border>
</Window>
"@
$XmlReader = (New-Object System.Xml.XmlNodeReader $xaml)
[System.Reflection.Assembly]::LoadWithPartialName(‘PresentationFramework’) | Out-Null
$Window = [Windows.Markup.XamlReader]::Load($XmlReader)
$WindowName = $window.FindName("windowCheckName")
$BrowseCSVButton = $window.FindName("ButtonCSVBrowse")
$BrowsePavastButton = $window.FindName("ButtonPavastBrowse")
$RunButton = $Window.FindName("ButtonStartRun")
$PavastPathText = $window.FindName("TextboxPavastPath")
$CSVPathText = $window.FindName("TextboxCSVPath")


#Action during browsing the CSV file
$BrowseCSVFileClick ={
        [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $Browse = New-Object System.Windows.Forms.OpenFileDialog
        $Browse.filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $Browse.InitialDirectory = "C:\Users\"+$env:USERNAME.ToLower()+"\Downloads"
        $Loop = $True
        while($Loop){
            if ($Browse.ShowDialog() -eq "OK"){
                $Loop = $False
		        $CSVPathText.Text = $Browse.FileName                              
                } 
            else{
                return
                }
            }
        $Browse.Dispose()
        } 
    
$BrowseCSVButton.Add_Click($BrowseCSVFileClick)  

#Action during browsing the Pavast File
$BrowsePavastFileClick ={
        [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $Browse = New-Object System.Windows.Forms.OpenFileDialog
        $Browse.filter = "XML files (*.xml)|*.xml|All files (*.*)|*.*"
        $Browse.InitialDirectory = "C:\temp\" + $env:USERNAME.ToLower()
        $Loop = $True
        while($Loop){
            if ($Browse.ShowDialog() -eq "OK") {
                $loop = $False
		        $PavastPathText.Text= $Browse.FileName 
                }
            else{
                return
                }
            }
        $Browse.Dispose()
        return
        }
      
$BrowsePavastButton.Add_Click($BrowsePavastFileClick)



$RunClick = {

$RunButton.IsEnabled = $False
$RunButton.Content ="Running.."
$WindowName.Dispatcher.Invoke([Action]{},"Render")



$UBKCsvPath =  $CSVPathText.Text
$PavastFilePath = $PavastPathText.Text

$script:UBKArray = Import-Csv $UBKCsvPath -delimiter ";"

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

$PavastData = [xml](Get-Content $PavastFilePath)

$AdminDataRead = @()
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
    $Calibrations = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF
    $Messages = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTS.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF
}
elseif($CodeGenerator -eq 'MATLAB')
{ 
    $Calibrations = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWCALPRMREFS.$SWCALPRMREF
    $Messages = $PavastData.MSRSW.$SWSYSTEMS.$SWSYSTEM.$SWCOMPONENTSPEC.$SWCOMPONENTS.$SWFEATURE.$SWFEATUREOWNEDELEMENTSETS.$SWFEATUREOWNEDELEMENTSET.$SWFEATUREELEMENTS.$SWVARIABLEREFS.$SWVARIABLEREF
}
else
{
    "Cannot read Pavast"
    Break
}



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
<body><p class='fcname'>$FCName</p>

<table><tr><th>Variables</th><th>Findings</th></tr>"

while ($Counter -lt $Messages.Length) {
    $MessageParts =@()
    $MessageParts = $Messages[$Counter].Split('_')
    $reportHTML += '<tr><td>'+ $Messages[$Counter] +'</td><td>'
       
    #Checking <Id> Matching FC Name
    if($MessageParts[0] -ceq $Id){$reportHTML += "<p style='color:green'>"+ $MessageParts[0] +"</p>" }else{$reportHTML += "<p style='color:red'>"+ $MessageParts[0]+ " - <Id> not equal to $Id </p>"}    

    $MessagePartsCounter = 1
    [String[]]$SplittedMessage = @()
    while($MessagePartsCounter -lt $MessageParts.Length)
        {
        [String[]]$SplittedMessage = Get-SplittedArray($MessageParts[$MessagePartsCounter])
        
        $MessageCounter = 0
        if(($MessagePartsCounter -eq 1) -and ($MessageParts[$MessageParts.Length -1] -cne 'I')){
            $reportHTML += Get-Comparepp($SplittedMessage[0])
            $MessageCounter = 1}

        while($MessageCounter -lt $SplittedMessage.Length){
            $reportHTML +=  Get-CompareDescriptiveName($SplittedMessage[$MessageCounter])
            $MessageCounter++}

        $MessagePartsCounter++
        }
      
$Counter++
$reportHTML += '</td>'}


$reportHTML += '</table></br></br><table><tr><th>Calibrations</th><th>Findings</th></tr>'



$Counter = 0
while ($Counter -lt $Calibrations.Length) {
    
    $MessageParts =@()
    $MessageParts = $Calibrations[$Counter].Split('_')
    
    $reportHTML += '<tr><td>'+ $Calibrations[$Counter] +'</td><td>' 
       
    #Checking <Id> Matching FC Name
    if($MessageParts[0] -ceq $Id){$reportHTML += "<p style='color:green'>"+ $MessageParts[0] +"</p>" }else{$reportHTML += "<p style='color:red'>"+ $MessageParts[0]+ " - <Id> not equal to $Id </p>"}   

    #Checking the ending of calibrations
    $SizeofSplittedArray = $MessageParts.Length - 1
    if(($MessageParts[$MessageParts.Length - 1] -ceq 'C') -or ($MessageParts[$MessageParts.Length - 1] -ceq 'T') -or ($MessageParts[$MessageParts.Length - 1] -ceq 'M')){} else {$reportHTML += "<p style='color:red'>Calibration has to end with C, T or M</p>";$SizeofSplittedArray = $MessageParts.Length}

    $MessagePartsCounter = 1
    [String[]]$SplittedMessage = @()
    while($MessagePartsCounter -lt ($SizeofSplittedArray))
        {
        
        [String[]]$SplittedMessage = Get-SplittedArray($MessageParts[$MessagePartsCounter])
        
        $MessageCounter = 0
        if($MessagePartsCounter -eq 1) {$reportHTML += Get-Comparepp($SplittedMessage[0]);$MessageCounter = 1}
         
        while($MessageCounter -lt $SplittedMessage.Length){
            $reportHTML +=  Get-CompareDescriptiveName($SplittedMessage[$MessageCounter])
            $MessageCounter++
            }

        $MessagePartsCounter++
        }
      
$Counter++
}



$reportHTML += ' </tr></table></body></html>'

if (Test-Path $Script:htmlPath -PathType leaf){
remove-item $Script:htmlPath
}
New-Item $Script:htmlPath
Set-content -Path $Script:htmlPath  -Value $reportHTML

Invoke-item $Script:htmlPath

$RunButton.IsEnabled = $True
$RunButton.Content ="Run"

}

$RunButton.Add_Click($RunClick)



 

[Void] $Window.ShowDialog()
