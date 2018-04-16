<#

.Synopsis

   Setup.ps1 - Install applications and scripts in sequences

.DESCRIPTION

   Setup.ps1 - Install applications and scripts in sequences

   VERSION: 
   V1.0 - 2018-04-08 - EMER15 - Creation of script

.EXAMPLE

   setup.ps1 -INSTALL = To install in sequence from setup.ini

   Runs in SCCM: Powershell.exe -Command ".\Setup.ps1 -INSTALL"

   steup.ps1 running setup.ini in order and checking steps that contains INSTALL

   example (setip.ini):

   Will begin with step1,INSTALL and end with Step2,INSTALL

    STEP1,INSTALL,"msiexec /qb-! /i "7z1801-x64.msi" ALLUSERS=1 /le "C:\Log\SCCM\7z1801-x64.msi.Install.log"",3010
    STEP1,UNINSTALL,"msiexec /qb-! /x "7z1801-x64.msi" /le "C:\Log\SCCM\7z1801-x64.msi.Uninstall.log"",3310
    STEP2,INSTALL,"msiexec /qb-! /i "7z1801-x64.msi" ALLUSERS=1 /le "C:\Log\SCCM\7z1801-x64.msi.Install.log"",0
    STEP2,UNINSTALL,"msiexec /qb-! /x "7z1801-x64.msi" /le "C:\Log\SCCM\7z1801-x64.msi.Uninstall.log"",0

    Script.ps1 will check each steps in setup.ini if it contains exitCode for example 3010 the end of STEP1.INSTALL

.EXAMPLE

   setup.ps1 -UNINSTALL = To Uninstall in sequence from setup.ini

   Runs in SCCM: Powershell.exe -Command ".\Setup.ps1 -UNINSTALL"

   steup.ps1 running setup.ini in revert order and checking steps that contains UNINSTALL

   example (setip.ini):

   Will begin with step2,UNINSTALL and end with Step1,UNINSTALL

    STEP1,INSTALL,"msiexec /qb-! /i "7z1801-x64.msi" ALLUSERS=1 /le "C:\Log\SCCM\7z1801-x64.msi.Install.log"",3010
    STEP1,UNINSTALL,"msiexec /qb-! /x "7z1801-x64.msi" /le "C:\Log\SCCM\7z1801-x64.msi.Uninstall.log""
    STEP2,UNINSTALL,"msiexec /qb-! /faum  {63DF5C4B-E3BF-3346-A033-C57B22F44C9E} /le "C:\Log\SCCM\RepairNetFrameWork.Uninstall.log""

.INPUTS
   -INSTALL or -UNINSTALL
.OUTPUTS
   NONE
.NOTES
   General notes
.COMPONENT
.ROLE
.FUNCTIONALITY
#>

    param(

    [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$false,
        ValueFromRemainingArguments=$false
        )]
    [switch]$INSTALL,

    [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$false,
        ValueFromRemainingArguments=$false
        )]
    [switch]$UNINSTALL
    )

        # Getting content from sequence.ini
        $INIContent = Get-Content -path ($PSScriptRoot + "\setup.ini") -ErrorAction Stop

        try{
            $INIContentRows = $INIContent -split [Environment]::NewLine, ""
        } Catch {
            Write-Error $_.Exception.ItemName
            Write-Error $_.Expception.Message
            Break
        }

        # Argument INSTALL is used run this code
        if($INSTALL){
            try{
                foreach($INIContentRow in $INIContentRows.GetEnumerator()){
                    foreach($SequenceItem in $INIContentRow){
                       $SequenceItem = $SequenceItem.Split(",")

                       # Looping throuh INIContent

                       if($SequenceItem[1] -eq "INSTALL"){
                            Start-Process -FilePath "cmd.exe" -ArgumentList ("/C " + $SequenceItem[2].trim("""") + """") -Wait  -WindowStyle Hidden
                       }

                       # Set exitcode if it contains in install sequence
                       if(!([string]::IsNullOrEmpty($SequenceItem[3]))){
                            [Environment]::Exit($SequenceItem[3])
                       }
                    }         
                }
            } Catch {
                Write-Error $_.Exception.ItemName
                Write-Error $_.Expception.Message
                Break
            }
        }elseif ($UNINSTALL){ # Argument UNINSTALL is used run this code
            try{
                [array]::Reverse($INIContentRows)

                foreach($INIContentRow in $INIContentRows.GetEnumerator()){
                    foreach($SequenceItem in $INIContentRow){
                       $SequenceItem = $SequenceItem.Split(",")

                       # Looping throuh INIContent
                       if($SequenceItem[1] -eq "UNINSTALL"){
                            Start-Process -FilePath "cmd.exe" -ArgumentList ("/C " + $SequenceItem[2].trim("""") + """") -Wait -WindowStyle Hidden
                       }

                       # Set exitcode if it contains in install sequence
                       if(!([string]::IsNullOrEmpty($SequenceItem[3]))){
                            [Environment]::Exit($SequenceItem[3])
                       }
                    }         
                }
            } Catch {
                Write-Error $_.Exception.ItemName
                Write-Error $_.Expception.Message
                Break
            }
        }