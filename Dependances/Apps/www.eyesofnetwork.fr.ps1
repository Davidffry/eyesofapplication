#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Scénario de test de connexion à la page Téléchargements de www.eyesofnetwork.fr                                        *#
#* Expected results : Etat + Temps de lancement + Action                                                                                     *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#****************************************************************MODIFICATIONS ICI*************************************************************
#**********************************************************************************************************************************************

# --- Expected resolution
$ExpectedResolutionX="1024"
$ExpectedResolutionY="768"

# Required field to run via GUI
$TargetedEon="127.0.0.1"
$NrdpToken="TEST"
$GUI_Equipement_InEON = "SONDE_SVP"

# --- Web
$Url = "http://www.eyesofnetwork.fr"

# --- Client lourd
$ProgExe = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" # Executable
$ProgArg = $Url # Arguments de l'exéctuable
$ProgDir = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) # Dossier dans lequel démarrer le programme

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

Function RunScenario($Chrono)
{ 
    $cmd = Measure-Command {

        AddValues "INFO" "Maximize FF" 
        if (ImageNotExist $Image_maximize_button 10)
        {
            AddValues "INFO" "Already in fullsize"
        } else
        {
            AddValues "INFO" "Not in full size, i click to maximize windows."
            ImageClick $xy 0 0
        }

        AddValues "INFO" "30 of tolerance because of transparency...."
        $xy=ImageSearch $Image_download_title $ImageSearchRetries $ImageSearchVerbosity $EonServ 250 0 30 
        ImageClick $xy 0 0
        
        AddValues "INFO" "Verify download page appears...."
        $xy=ImageSearch $Image_download_page $ImageSearchRetries $ImageSearchVerbosity $EonServ 250 0 30
        ImageClick $xy 0 0

        # Start-Sleep 2 

        # Send-Keys "XXXXXXX"

        # Send-SpecialKeys "{TAB}"
           
    }
    $Chrono += [math]::Round($cmd.TotalSeconds,6)
         
#**********************************************************************************************************************************************
#**********************************************************************************************************************************************

    # Renvoi le tableau de chronos
    return $Chrono

}