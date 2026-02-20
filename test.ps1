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

<#
.SYNOPSIS
    Extracts all class definitions from a Pavast XML file.

.DESCRIPTION
    This function parses a Pavast XML file and retrieves all SW-CLASS elements with CATEGORY='CLASS'.
    For each class, it extracts the class name, variable prototypes, and calibration parameter prototypes,
    returning them as structured PowerShell custom objects.

.PARAMETER PavastFilePath
    The full file path to the Pavast XML file to be parsed.

.OUTPUTS
    System.Object[]
    Returns an array of PSCustomObject instances, each containing:
    - ClassName: The SHORT-NAME of the class
    - VariablePrototypes: Array of SHORT-NAMEs from SW-VARIABLE-PROTOTYPE elements
    - CalPrmPrototypes: Array of SHORT-NAMEs from SW-CALPRM-PROTOTYPE elements

.EXAMPLE
    $classes = Get-AllClasses -PavastFilePath "C:\Data\pavast.xml"
    
    Retrieves all classes from the specified Pavast XML file.

.EXAMPLE
    $classes = Get-AllClasses -PavastFilePath "C:\Data\pavast.xml"
    $classes | ForEach-Object { Write-Host "Class: $($_.ClassName)" }
    
    Retrieves all classes and displays their names.

.NOTES
    The function expects the XML structure to follow the Pavast schema with specific XPath patterns:
    - //SW-COMPONENT-SPEC/SW-COMPONENTS/SW-CLASS[CATEGORY='CLASS']
    - .//SW-VARIABLE-PROTOTYPES/SW-VARIABLE-PROTOTYPE
    - .//SW-CALPRM-PROTOTYPES/SW-CALPRM-PROTOTYPE
#>
function Get-AllClasses {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)

 
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

    $UserDefinedClasses = @()
    foreach ($classRef in $PavastData.SelectNodes("//SW-FEATURE-OWNED-ELEMENTS/SW-FEATURE-ELEMENTS/SW-CLASS-REFS/SW-CLASS-REF")) {
        $UserDefinedClasses += $classRef.InnerText
    }

  return $UserDefinedClasses
}

function Get-ClassInstances {
    param ([string]$PavastFilePath)
    $PavastData = [xml](Get-Content $PavastFilePath)

    $ClassInstances = @()
    foreach ($instance in $PavastData.SelectNodes("//SW-FEATURE/SW-DATA-DICTIONARY-SPEC/SW-CLASS-INSTANCES/SW-CLASS-INSTANCE")) {
        $instanceDetails = [PSCustomObject]@{
            InstanceName = $instance.SelectSingleNode("SHORT-NAME").InnerText
            ClassRef = $instance.SelectSingleNode("SW-CLASS-REF").InnerText
        }
        $ClassInstances += $instanceDetails
    }

    return $ClassInstances
}


Get-ClassInstances -PavastFilePath "A:\2025\V2L\03_Ascet_generated_code\AcExtChrgrCtrlp_5622_2_0_V2L\AcExtChrgrCtrl_pavast.xml"

