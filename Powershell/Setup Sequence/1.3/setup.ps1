<#

.Synopsis

   Setup.ps1 - Install applications and scripts in sequences

.DESCRIPTION

   Setup.ps1 - Install applications and scripts in sequences

   VERSION: 
   V1.3 - 2018-04-12 - EMER15 - Created logging function to log each step in sequence. You need to specify the application name in argument LogAppName "appname"
                                When Execute script setup.ps1 example .\setup.ps1 -INSTALL -LogAppName "APPName". A log will be created under c:\LOG\SCCM\

   V1.2 - 2018-04-11 - EMER15 - Added -WorkingDirectory "$PSScriptRoot" to cmdlet Start-Process and created logging function log each setup.ini steps

   V1.1 - 2018-04-11 - EMER15 - Updated script to run application in sequence via powershell.exe -Command instead rather than via cmd.exe /c.
                                Run application setup with arguments you need to specify o in setup.ini the path to media file with. 
                                single quotation marks example msiexec /I 'msifile.msi' /l*v 'c:\log\file.log' 
                                setup.ps1 also support run powershell cmdlets in setup.ini in sequence, see example below. Can also
                                run single script files in sequence by enter with dot and slash before filename example 
                                .\script.ps1 or .\script.vbs or .\script.exe

   V1.0 - 2018-04-08 - EMER15 - Creation of script

.EXAMPLE

   setup.ps1 -INSTALL -LogAppName "AppName.Install" = To install in sequence from setup.ini
   setup.ps1 -UNINSTALL -LogAppName "AppName.Uninstall" = To uninstall in sequence from setup.ini

   Runs in SCCM: Powershell.exe -Command ".\Setup.ps1 -INSTALL" -LogAppName "AppName.INSTALL"
   Runs in SCCM: Powershell.exe -Command ".\Setup.ps1 -UNINSTALL" -LogAppName "AppName.UNINSTALL"

   steup.ps1 running setup.ini in order and checking steps that contains INSTALL

   example (setip.ini):

   Will begin with step1,INSTALL and end with Step2,INSTALL

    STEP1,INSTALL,"msiexec /qb-! /i '7z1801-x64.msi' ALLUSERS=1 /le 'C:\Log\SCCM\7z1801-x64.msi.Install.log'",3010
    STEP1,UNINSTALL,"msiexec /qb-! /x '{63DF5C4B-E3BF-3346-A033-C57B22F44C9E}' /le 'C:\Log\SCCM\7z1801-x64.msi.Uninstall.log'",3310
    STEP2,INSTALL,"msiexec /qb-! /i '7z1801-x64.msi' ALLUSERS=1 /le 'C:\Log\SCCM\7z1801-x64.msi.Install.log'",0
    STEP2,UNINSTALL,"msiexec /qb-! /x '{63DF5C4B-E3BF-3346-A033-C57B22F44C9E}' /le 'C:\Log\SCCM\7z1801-x64.msi.Uninstall.log'"

    Script.ps1 will check each steps in setup.ini if it contains exitCode for example 3010 the end of STEP1.INSTALL

.EXAMPLE

   setup.ps1 -UNINSTALL = To Uninstall in sequence from setup.ini

   Runs in SCCM: Powershell.exe -Command ".\Setup.ps1 -UNINSTALL"

   steup.ps1 running setup.ini in revert order and checking steps that contains UNINSTALL

   example (setip.ini):

   Will begin with step2,UNINSTALL and end with Step1,UNINSTALL

    STEP1,INSTALL,"msiexec /qb-! /i '7z1801-x64.msi" ALLUSERS=1 /le 'C:\Log\SCCM\7z1801-x64.msi.Install.log'",3010
    STEP1,UNINSTALL,"msiexec /qb-! /x '{63DF5C4B-E3BF-3346-A033-C57B22F44C9E}' /le 'C:\Log\SCCM\7z1801-x64.msi.Uninstall.log'"
    STEP2,UNINSTALL,"msiexec /qb-! /faum '{63DF5C4B-E3BF-3346-A033-C57B22F44C9E}' /le 'C:\Log\SCCM\RepairNetFrameWork.Uninstall.log'"
    STEP3,INSTALL,"Copy-Item -Path '.\extensions\*.*' -Destination 'C:\Program Files\Microsoft VS Code\extensions' -Force"
    STEP3,UNINSTALL,"Remove-Item -Path 'C:\Program Files\Microsoft VS Code\extensions\' -Recurse -Confirm:$false -ErrorAction SilentlyContinue -Force"
    STEP4,INSTALL,".\Install-VSCodeExtensions.ps1 -VSCodeExtensionPath 'C:\Program Files\Microsoft VS Code\extensions' -VSCodeArgument --install-extension""
    STEP4,UNINSTALL,".\Install-VSCodeExtensions.ps1 -VSCodeExtensionPath 'C:\Program Files\Microsoft VS Code\extensions' -VSCodeArgument --uninstall-extension""

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
    [switch]$UNINSTALL,
    
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$false,
    ValueFromPipelineByPropertyName=$false,
    ValueFromRemainingArguments=$false
    )]
    [string]$LogPath = "C:\LOG\SCCM\",
    
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$false,
    ValueFromPipelineByPropertyName=$false,
    ValueFromRemainingArguments=$false
    )]
    [string]$LogAppName

    )

        function funcLogSequenceStep
        {
            # Function to logging each step in sequence and append it to log file on local computer
            PARAM(
            [string]$LogPath,
            [string]$LogName,
            [string]$LogStep
            )
            
            if(!(Test-Path -Path ("""" + $LogPath + $LogName + ".log"""))){
                # Create Log, if it's not exist
                try{
                    New-Item -Path $LogPath -Name ($LogName + ".log") -Force -Confirm:$false -ErrorAction stop | Out-Null
                    Add-Content -Path ($LogPath + $LogName + ".log") -Value ('<![LOG[' + $LogStep + ']LOG]!><time="' + (Get-date -Format "mm-dd-yyyy") + '" date="' + (Get-date -Format "HH:MM:ss.FFF-FFF") + '" component="SCRIPT" context="" type="1" thread="" file="">') -ErrorAction Stop
                
                } catch {
                    Write-Error -Message $_.Exception.Message
                    Break
                } 
            }else{
                # Add Content to log file
                try{
                    if((New-TimeSpan -start (Get-ChildItem -Path ($LogPath + $LogName + ".log")).CreationTime -End (Get-date)).Days -lt 1){ # If log is not i older than 1 day, add content to exist log
                        Add-Content -Path ($LogPath + $LogName + ".log") -Value ('<![LOG[' + $LogStep + ']LOG]!><time="' + (Get-date -Format "mm-dd-yyyy") + '" date="' + (Get-date -Format "HH:MM:ss.FFF-FFF") + '" component="SCRIPT" context="" type="1" thread="" file="">') -ErrorAction Stop
                    }else{ # If Log is older than one day create new log
                        New-Item -Path $LogPath -Name ($LogName + ".log") -Force -Confirm:$false -ErrorAction Stop | Out-Null
                        Add-Content -Path ($LogPath + $LogName + ".log") -Value ('<![LOG[' + $LogStep + ']LOG]!><time="' + (Get-date -Format "mm-dd-yyyy") + '" date="' + (Get-date -Format "HH:MM:ss.FFF-FFF") + '" component="SCRIPT" context="" type="1" thread="" file="">') -ErrorAction Stop
                    }

                } catch {
                    Write-Error -Message $_.Exception.Message
                    Break
                } 
            }

        }


        # Getting content from sequence.ini
        try{
            $INIContent = Get-Content -path ($PSScriptRoot + "\setup.ini") -ErrorAction Stop
            $INIContentRows = $INIContent -split [Environment]::NewLine, ""
        } Catch {
            Write-Error -Message $_.Exception.Message
            Break
        }

        # Argument INSTALL is used run this code
        if($INSTALL){
                foreach($INIContentRow in $INIContentRows.GetEnumerator()){
                    foreach($SequenceItem in $INIContentRow){
                       $SequenceItem = $SequenceItem.Split(",")

                       # Looping throuh INIContent

                       if($SequenceItem[1] -eq "INSTALL"){
                            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
                            $ProcessInfo.FileName = "Powershell.exe"
                            $ProcessInfo.RedirectStandardError = $true
                            $ProcessInfo.RedirectStandardOutput = $true
                            $ProcessInfo.UseShellExecute = $false
                            $ProcessInfo.CreateNoWindow = $true
                            $ProcessInfo.WorkingDirectory = "$PSScriptRoot"
                            $ProcessInfo.Arguments = ("-NoLogo -NonInteractive -Command """ + $SequenceItem[3].trim("""") + """")
                            $ProcessExecution = New-Object System.Diagnostics.Process
                            $ProcessExecution.StartInfo = $ProcessInfo
                            $ProcessExecution.Start() | Out-Null
                            $ProcessExecution.ExitCode
                            $ProcessExecution.WaitForExit() 
                            $ProcessExecution.StandardOutput.ReadToEnd();
                            $ProcessExecution.ExitCode

                            # Logging the step
                            funcLogSequenceStep `
                                -LogPath $LogPath `
                                -LogName $LogAppName `
                                -LogStep ($SequenceItem[1] + " - " + $SequenceItem[0] + " - " + $SequenceItem[2] +  "- " + $SequenceItem[3] + " - ExitCode: " + $ProcessExecution.ExitCode)
                            
                            # Stop sequence if error occurs
                            if($ProcessExecution.ExitCode -eq 1){
                                break
                            }

                                 
                       }

                       # Set exitcode if it contains in install sequence
                       if(!([string]::IsNullOrEmpty($SequenceItem[4]))){
                            [Environment]::Exit($SequenceItem[4])
                       }
                    } 
                   # Stop script if error code occur
                   if($ProcessExecution.ExitCode -eq 1){
                        break
                   }          
                }
        }elseif ($UNINSTALL){ # Argument UNINSTALL is used run this code
                [array]::Reverse($INIContentRows)

                foreach($INIContentRow in $INIContentRows.GetEnumerator()){
                    foreach($SequenceItem in $INIContentRow){
                       $SequenceItem = $SequenceItem.Split(",")

                       # Looping throuh INIContent
                       if($SequenceItem[1] -eq "UNINSTALL"){
                            
                            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
                            $ProcessInfo.FileName = "Powershell.exe"
                            $ProcessInfo.RedirectStandardError = $true
                            $ProcessInfo.RedirectStandardOutput = $true
                            $ProcessInfo.UseShellExecute = $false
                            $ProcessInfo.CreateNoWindow = $true
                            $ProcessInfo.WorkingDirectory = "$PSScriptRoot"
                            $ProcessInfo.Arguments = ("-NoLogo -NonInteractive -Command """ + $SequenceItem[3].trim("""") + """")
                            $ProcessExecution = New-Object System.Diagnostics.Process
                            $ProcessExecution.StartInfo = $ProcessInfo
                            $ProcessExecution.Start() | Out-Null
                            $ProcessExecution.ExitCode
                            $ProcessExecution.WaitForExit() 
                            $ProcessExecution.StandardOutput.ReadToEnd();
                            $ProcessExecution.ExitCode
                            
                            # Logging the step
                            funcLogSequenceStep `
                                -LogPath $LogPath `
                                -LogName $LogAppName `
                                -LogStep ($SequenceItem[1] + " - " + $SequenceItem[0] + " - " + $SequenceItem[2] +  "- " + $SequenceItem[3] + " - ExitCode: " + $ProcessExecution.ExitCode)
                         
                      }


                       # Set exitcode if it contains in install sequence
                       if(!([string]::IsNullOrEmpty($SequenceItem[4]))){
                            [Environment]::Exit($SequenceItem[4])
                       }


                    }       
                    
                   # Stop sequence if error occurs
                   if($ProcessExecution.ExitCode -eq 1){
                        break
                   }  
                }
        }