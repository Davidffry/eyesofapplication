#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Chargement eon4apps                                                                                                    *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALISATIONS***********************************************************

# Paramètres
Param(
	[Parameter(Mandatory=$true)]
	[string]$App,
	[string]$EonServ="",
	[string]$EonToken="",
	[string]$EonUrl="https://${EonServ}/nrdp",
	[string]$PurgeProcess="True"
)
if(!$EonServ -or !$EonToken) { throw "Please define EonServ and EonToken" }
$App_Backup = $App # Workaround bug of Start-Process made by Microsoft


# Récupération du path
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 

# Variables et Fonctions
$Init = $ScriptPath + "\init.ps1"
If (!(Test-Path $Init)){ throw [System.IO.FileNotFoundException] "$Init not found" }
. $Init

# Création du fichier de log
 $out = & $ScriptPath"\GetRunner.exe" 0
        $State = [int]$out.Split('|')[0]
        
        if ($State -ne 0) {
                $domain = $out.Split('|')[1]
                $username = $out.Split('|')[2]
                $computer = $out.Split('|')[3] 

                $LogPath = $ScriptPath + "\Execlog\" + $domain + "\" + $username + "\" + $computer
                
                If(!(test-path $LogPath)) {
                    New-Item -ItemType Directory -Force -Path $LogPath
                }

                $Log = $LogPath + "\" + $App + ".log" # Continue to use Log variable in rest of scripts.

        } else {
            throw [System.IO.FileNotFoundException] "GetRunner could not determine environnement." 
        }

New-Item $Log -Type file -force -value "" |out-null

# From this point logging is available.
AddValues "INFO" "Chargement Init.ps1 OK"
AddValues "INFO" "Current call is: $App $EonServ $EonToken $EonUrl $PurgeProcess."
# Purge
Get-ChildItem -Path $ScriptPath\log\ -Filter *.bmp -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddMinutes(-$PurgeDelay) } | Remove-Item -Force -Recurse

# Chargement de l'application
$TempPathAppsLnk = $PathApps + "User\\" + $App + ".ps1.lnk"
if ( (Test-Path $TempPathAppsLnk) ) { 
    $InitApp = $PathApps + $App + ".ps1"
    $InitApp = $InitApp -replace "user_", ""
} else {
    $InitApp = $PathApps + $App + ".ps1"
}

$PassApp = $PathApps + $App + ".pass"
If (!(Test-Path $InitApp)){ throw [System.IO.FileNotFoundException] "$InitApp not found" }
. $InitApp

AddValues "INFO" "Chargement InitApp OK... ($InitApp)"
# Determine if User (GUI) or Sched
$FromGUI = $false
if ( ($App -match [regex]'^user_')) {
    AddValues "INFO" "Running from GUI detected."
    $FromGUI = $true
}
AddValues "INFO" "Running scenario:" + $InitApp + "\n"

#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          DEBUT DU PROGRAMME                                                   *#
#*                                                                                                                               *#
#*********************************************************************************************************************************#    

AddValues "INFO" "Démarrage de la sonde"

[system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(0,0)

# Création du dossier et des variables images
$CheminDossierImages = $CheminFichierImages + $Service + "\"
New-Item $CheminDossierImages -Type directory -force -value "" |out-null
Get-ChildItem $CheminDossierImages -Filter *.bmp |foreach { $name = $_.BaseName ; New-Variable -Force -Name "Image_${name}" -Value $_.FullName }

#Purge des processus
if($PurgeProcess -eq "True") {
	AddValues "INFO" "Purge des processus"
	PurgeProcess
}

# --- Definition des seuils globaux
Foreach($svc in $Services) { 
    $BorneInferieure += $svc[1]  
    $BorneSuperieure += $svc[2]  
}
AddValues "INFO" "Screen resolution adjustment to ${ExpectedResolutionX}x${ExpectedResolutionY}"
SetScreenResolution $ExpectedResolutionX $ExpectedResolutionY

# Do not remove. This cd is used to relative path access...
$ExceScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
AddValues "INFO" "Execution Path is: $ExceScriptPath"
cd $ExceScriptPath

# # --- Start application and initialize launch chrono.
$cmd = Measure-Command {

    AddValues "INFO" "Lancement de l'application"
    
    # Client lourd avec arguments
    if($ProgArg) {  
        $app = Start-Process -PassThru -FilePath "$ProgExe" -ArgumentList "$ProgArg" -WorkingDirectory "$ProgDir"            
        AddValues "INFO" "Run with Args: $ProgExe $ProgArg"
    }   
    # Client lourd sans arguments
    elseif($ProgExe) { 
        $app = Start-Process -PassThru -FilePath "$ProgExe" -WorkingDirectory "$ProgDir"        
        AddValues "INFO" "Run: $ProgExe"
    }
    # Web
    else { 
        $ie = New-Object -COMObject InternetExplorer.Application
        $ie.visible = $true
        $ie.fullscreen = $true
        $ie.Navigate($Url)
        while ($ie.Busy -eq $true) { start-sleep 1; }
        $app = Get-Process -Name iexplore | Where-Object {$_.MainWindowHandle -eq $ie.HWND}
        AddValues "INFO" "Running in web mode..."
    }

    # Set application windows on top.
    AddValues "INFO" "Ask for PID ---> $app.id"
    Set-Active $app.id
}
$Chrono += [math]::Round($cmd.TotalSeconds,6)

AddValues "INFO" "EOA Scenario: $App"
# Chargement de l'application
Try {
    #$Chrono = LoadApp($Chrono) 
    $Chrono += RunScenario($Chrono)   
}
Catch {

    # Ajouter le service en cours en erreur
    $ErrorMessage = $_.Exception.Message
    AddValues "ERROR" $ErrorMessage
    $Status = "CRITICAL"
    $Information = $Status + " : " + $Service + " " + $ErrorMessage
    AddValues "ERROR" $Information

    # Envoi de la trap
    AddValues "ERROR" "Envoi de la trap en erreur"
    if ( $FromGUI -eq $false ) {
 	  $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
	   AddValues "ERROR" "powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"
	}
    if ( $FromGUI -eq $true ) {
       $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${GUI_Equipement_InEON}" -service "${App_Backup}" -state "${Status}" -output "${Hostname}:${Information}"
       AddValues "ERROR" "powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${GUI_Equipement_InEON}' -service '${App_Backup}' -state '${Status}' -output '${Hostname}:${Information}'"
    }
    AddValues "INFO" "Restore screen resolution"
    $out = & ${Path}\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration
    exit 2

}

# Définition des perfdata
$PerfData = GetPerfdata $Services $Chrono $BorneInferieure $BorneSuperieure

# Dépassement de seuil global ou unitaire
if (($PerfData[0] -gt $BorneSuperieure) -or ($PerfData[3] -ne ""))
{
	$Status = "CRITICAL"
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
elseif (($PerfData[0] -gt $BorneInferieure) -or ($PerfData[2] -ne "")) 
{ 
	$Status = "WARNING"
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
# Exécution normale
else
{
	$Status = "OK"
    AddValues "INFO" "Envoi de la trap en fonctionnement normal"
}
	
# Envoi de la trap
$Information = $Status + " : " + $Service + " " + $PerfData[0] + "s" 
if($PerfData[2] -ne "") { $Information = $Information + " " + $PerfData[2] }
if($PerfData[3] -ne "") { $Information = $Information + " " + $PerfData[3] }
$Information = $Information + $PerfData[1]
AddValues "INFO" $Information
if ( $FromGUI -eq $false ) {
    $Send_Trap = &  powershell -ExecutionPolicy ByPass -File  ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
    AddValues "INFO" "powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"
}
if ( $FromGUI -eq $true ) {
    $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${GUI_Equipement_InEON}" -service "${App_Backup}" -state "${Status}" -output "${Hostname}:${Information}"
    AddValues "INFO" "powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${GUI_Equipement_InEON}' -service '${App_Backup}' -state '${Status}' -output '${Hostname}:${Information}'"
}

AddValues "INFO" "Restore screen resolution"
$out = & ${Path}\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration

# # Purge des processus
if($PurgeProcess -eq "True") {
    AddValues "INFO" "Purge des processus"
    PurgeProcess
}

# Fin de la sonde
AddValues "INFO" "Fin de la sonde"

exit 0


#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          FIN DU PROGRAMME                                                     *#
#*                                                                                                                               *#
#*********************************************************************************************************************************# 