#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Scénario de test de connexion à la page Téléchargements de www.eyesofnetwork.fr                                        *#
#* Expected results : Etat + Temps de lancement + Action                                                                                     *#
#* Manual Execution : powershell -WindowStyle Minimized -ExecutionPolicy Bypass -File "C:\eon\APX\EON4APPS\eon4apps.ps1" www.eyesofnetwork.fr 127.0.0.1 TEST
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#****************************************************************MODIFICATIONS ICI*************************************************************
#**********************************************************************************************************************************************

# --- Expected resolution
$ExpectedResolutionX="1024"
$ExpectedResolutionY="768"

# --- Gestion des fenêtres
$WindowName = "iexplore" # Nom de la fenêtre

# --- Web
$Url = "http://www.eyesofnetwork.fr"

# --- Client lourd
$ProgExe = "C:\Program Files (x86)\Internet Explorer\iexplore.exe" # Executable
$ProgArg = $Url # Arguments de l'exéctuable
$ProgDir = "C:\eon\APX\EON4APPS\" # Dossier dans lequel démarrer le programme

# --- Authentification
$User = ""
$Pass = ""

# --- Host, Service, données de performances et seuils Nagios
$Hostname = "sondes-applicatives" # Definition du Host dans EON pour l'envoi de trap
$Service = "www.eyesofnetwork.fr" # Definition du service dans EON pour l'envoi de trap
$Services = ("Launch","10","15"), 
            ("Download","10","15") # Renseigner ici le nom des différents tests et les seuils

# --- Gestion des recherches d'image
$ImageSearchRetries = "20"  # Nombre d'essais lors de la recherche d'une image
$ImageSearchVerbosity = "2" # Niveau de log de la recherche d'image

#**********************************************************************************************************************************************
#**********************************************************************************************************************************************

# --- Definition des seuils globaux
Foreach($svc in $Services) { 
    $BorneInferieure += $svc[1]  
    $BorneSuperieure += $svc[2]  
}

AddValues "INFO" "Screen resolution adjustment"
SetScreenResolution $ExpectedResolutionX $ExpectedResolutionY

# --- Chargement de l'application
Function LoadApp($Chrono)
{

    # Lancement de l'application 
    $cmd = Measure-Command {
    
        AddValues "INFO" "Lancement de l'application"
        
        # Client lourd avec arguments
        if($ProgArg) { $app = Start-Process -PassThru -FilePath $ProgExe -ArgumentList $ProgArg -WorkingDirectory $ProgDir }   
        
	    # Client lourd sans arguments
        elseif($ProgExe) { $app = Start-Process -PassThru -FilePath $ProgExe -WorkingDirectory $ProgDir }
	
        # Web
        else {         
            $ie = New-Object -COMObject InternetExplorer.Application
            $ie.visible = $true
            $ie.fullscreen = $true
            $ie.Navigate($Url)
            while ($ie.Busy -eq $true) { start-sleep 1; }
            $app = Get-Process -Name iexplore | Where-Object {$_.MainWindowHandle -eq $ie.HWND}
        }

        # Sélection de la fenêtre
        Set-Active $app.Id
    
#****************************************************************MODIFICATIONS ICI*************************************************************
#**********************************************************************************************************************************************

    }
    $Chrono += [math]::Round($cmd.TotalSeconds,6)
    
     # Accès page téléchargements
    $cmd = Measure-Command {

        AddValues "INFO" "Maximize IE" #This line add a comment to the exection log (located in Apps after running.)
        # Here we try to take a look to "Windows Maximizer button". If we do not found it, it mean windows is already fullsized. 
        # Please note the 1 at the end of the ImageSearch invokation. It means do not thrown error on undetection, but return array [-1,-1]
        $xy=ImageSearch C:\eon\APX\EON4APPS\Images\www.eyesofnetwork.com\maximize_button.bmp 5 0 $EonServ 250 1 10 0
        # Parameter are:
            # BMP file to look for on screen
            # 5: Means 5 retries before exit.
            # 0: Usually set to ImageSearchVerbosity (value = 2), it mean no debug but screenshot if not found.
            # EonServ: Is the EON server hostname to send result and screenshot.
            # 250: Is number of millisecond to wait between each retries.
            # 1: Is to set "noerror" mode. It means image not found don't exit the script but return an array with -1,-1
            # 10: Means the search accept a variance of 10 grade of color for difference between actual screen and BMP to find.
            # 0: Means it is need to use true color (i.e: 1 means Green drift of color) Drift could be used in case of hilgty white or black sample to find.

        $x = [int]$xy[0]
        $y = [int]$xy[1]
        if (($x -eq -1) -and ($y -eq -1))
        {
            AddValues "INFO" "Already in fullsize"
        } else
        {
            AddValues "INFO" "Not in full size, i click to maximize windows."
            ImageClick $xy 0 0
        }

	    AddValues "INFO" "Try "
        $xy=ImageSearch $Image_download_link $ImageSearchRetries $ImageSearchVerbosity $EonServ
        ImageClick $xy 0 0
        $xy=ImageSearch $Image_download_title $ImageSearchRetries $ImageSearchVerbosity $EonServ
        Start-Sleep 2 

        Send-Keys "XXXXXXX"
        Send-SpecialKeys "{TAB}"
           
    }
    $Chrono += [math]::Round($cmd.TotalSeconds,6)
         
#**********************************************************************************************************************************************
#**********************************************************************************************************************************************

    # Renvoi le tableau de chronos
    return $Chrono

}