#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function: Variables et Fonctions pour EON4APPPS                                                                                    *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALISATIONS***********************************************************

$Path = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
$Path = $Path + "\" #Ne pas modifier
$PathApps = $Path + "Apps\"#Ne pas modifier
$CheminFichierImages = $Path + "Images\"#Ne pas modifier
$Status = "OK"#Ne pas modifier-initialisation
$Information = ""#Ne pas modifier
$Chrono=@()#Ne pas modifier
$BorneInferieure = 0#Ne pas modifier
$BorneSuperieure = 0#Ne pas modifier
$PerfData = " | "#Ne pas modifier
$PurgeDelay = 60#Ne pas modifier

#********************************************************************FONCTIONS*****************************************************************

# Fonction qui ajoute les valeurs dans un fichier
Function AddValues($aNiveau, $aMsg)
{
    $aDate = Get-Date
    $aLog = "$aDate ($aNiveau) : $aMsg"
    Write-Host $aLog
	Write-Output $aLog >> $Log
}


# Fonction pour cliquez sur les liens avec la souris
Function Click-MouseButton
{
    param([string]$Button)

    if($Button -eq "double")
    {
        & $Path\EON-Keyboard.exe -c L
		Start-sleep 1
    }
    if($Button -eq "left")
    {
        & $Path\EON-Keyboard.exe -c l
		Start-sleep 1
    }
    if($Button -eq "right")
    {
        & $Path\EON-Keyboard.exe -c r
		Start-sleep 1
    }
    if($Button -eq "middle")
    {
        & $Path\EON-Keyboard.exe -c m
		Start-sleep 1
    }
}

Function Send-SpecialKeys
{
    param([string] $KeysToPress)
    & $Path\EON-Keyboard.exe -S $KeysToPress
    Start-sleep 1
}

Function Send-Keys
{
    param([string] $KeysToPress)
    & $Path\EON-Keyboard.exe -s $KeysToPress
    Start-sleep 1
}

# Fonction pour move the mouse
Function Move-Mouse ($AbsoluteX, $AbsoluteY)
{
    If (($AbsoluteX -ne $null) -and ($AbsoluteY -ne $null)) {
        [system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($AbsoluteX,$AbsoluteY)
   }
    else {
        AddValues "WARN" "Absolute position not received ($AbsoluteX,$AbsoluteY)."
    }
    Start-sleep 1
}

function Set-Active
{
    param (
        [int] $ProcessPid
    )
	AddValues "INFO" "PID ---> $ProcessPid"
	& $Path\SetActiveWindows.exe $ProcessPid 0
}

function Set-Active-Maximized
{
    param (
        [int] $ProcessPid
    )
    AddValues "INFO" "PID ---> $ProcessPid"
    & $Path\SetMaximizedWindows.exe $ProcessPid 0
}

# Fonction de purge des processus
Function PurgeProcess
{  
    Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne "" -or $_.ProcessName -eq "powershell"}  | ?{$_.ID -ne $pid} | stop-process -Force |out-null
    (New-Object -comObject Shell.Application).Windows() | foreach-object {$_.quit()} |out-null
    start-sleep 2
}

# Function de recherche image
Function ImageSearch
{

    param (
		[string] $Image,
		[int] $ImageSearchRetries,
		[int] $ImageSearchVerbosity,
		[string] $EonSrv,
		[int] $Wait=250,
		[int] $noerror=0,
		[int] $variance=0,
		[int] $green=0
    )

    AddValues "INFO" "(ImageSearch) Looking for image: $Image."
    If (!(Test-Path $Image)){ throw [System.IO.FileNotFoundException] "ImageSearch: $Image not found" }
	$ImageFound = 0
    for($i=1;$i -le $ImageSearchRetries;$i++)  {
        $out = & $Path"\GetImageLocation.exe" $Image 0 $variance $green
        $State = [int]$out.Split('|')[0]
		
		if ($State -ne 0) {
		# Image trouvée
		AddValues "INFO" "ImageSearch ---> $out"
		$xx1 = [int]$out.Split('|')[1] 
	    $yy1 = [int]$out.Split('|')[2]
		$tx = [int]$out.Split('|')[3]
		$ty = [int]$out.Split('|')[4]
		
		$modulox = $tx % 2
		$moduloy = $ty % 2
		
		if ( $modulox -ne 0) { $tx = $tx - $modulox }
		if ( $moduloy -ne 0) { $ty = $ty - $moduloy }
		
		$OffSetX = $tx / 2
		$OffSetY = $ty / 2
		
		$x1 = $OffSetX + $xx1
		$y1 = $OffSetY + $yy1
		$ImageFound = 1
		$xy=@($x1,$y1)
		break; 
		#Image trouvée, je sors.
		}
        AddValues "WARN" "Image $Image not found in screen (try $i)"
        start-sleep -Milliseconds $Wait
    }
	
	if (($ImageFound -ne 1) -and ($noerror -eq 0))
	{
		$out = & $Path"\GetImageLocation.exe" $Image $ImageSearchVerbosity $variance $green
        $State = [int]$out.Split('|')[0]
		$xy=@(0,0)
		if ($State -eq 0) {
			# Image non trouvée
			$ScrShot = $out.Split('|')[1] 
			$BaseFileName = [System.IO.Path]::GetFileNameWithoutExtension($ScrShot)
			$BaseFileNameExt = [System.IO.Path]::GetExtension($ScrShot)
			#
			# Send image to EON server.
			AddValues "ERROR" "Send the file: ${Path}pscp.exe -i ${Path}sshkey\id_dsa -l eon4apps $ScrShot ${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
			$SendFile = & ${Path}pscp.exe -i ${Path}sshkey\id_dsa -l eon4apps $ScrShot "${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
            $out = & ${Path}\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration
			$ConcatUrlSend = $Image + ' not found in screen: <a href="/eon4apps/' + $BaseFileName + $BaseFileNameExt + '" target="_blank">' + $ScrShot + '</a>'
			throw [System.IO.FileNotFoundException] "$ConcatUrlSend"
		}
	}
    elseif (($ImageFound -ne 1) -and ($noerror -eq 1))
    {
        $xy=@(-1,-1)
    }
      
    return $xy

}

# Function de recherche image en basse precision (drift to the green)
Function ImageSearchLowPrecision
{

    param (
		[string] $Image,
		[int] $ImageSearchRetries,
		[int] $ImageSearchVerbosity,
		[string] $EonSrv,
		[int] $Wait=250,
		[int] $noerror=0,
		[int] $variance=0,
		[int] $green=1
    )
	
	$xy=ImageSearch $Image $ImageSearchRetries $ImageSearchVerbosity $EonSrv $Wait $noerror $variance $green

    return $xy 

}

# Function de click gauche
Function ImageClick($xy,$xoffset,$yoffset,$type="left")
{
	$x = [int]$xy[0]
	$y = [int]$xy[1]
	AddValues "INFO" "Imageclick position ---> x:$x,y:$y"
	
	If ($xoffset -ne $null) {
		$x = [int]$xy[0] + $xoffset
		$y = [int]$xy[1]
		$xy=@($x,$y)
	}
	If ($yoffset -ne $null) {
		$x = [int]$xy[0]
		$y = [int]$xy[1] + $yoffset
		$xy=@($x,$y)
	}
	AddValues "INFO" "Imageclick offseted position ---> x:$x,y:$y"
	
	$SetX = [int]$xy[0]
	$SetY = [int]$xy[1]
    [system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($SetX,$SetY)
    Click-MouseButton $type

}

# Function de création des perdata
Function GetPerfdata
{

    param (
        [array] $Services,
        [array] $Chrono,
        [int] $BorneInferieure,
        [int] $BorneSuperieure 
    )

    $ServicesW=""
    $ServicesC=""
    $ChronoTotal=0
    $PerfDataTemp=""
    $i=0
    
    Foreach($svc in $Services){ 
        $ChronoTotal += $Chrono[$i]
        $PerfDataTemp = $PerfDataTemp + " " + $svc[0] + "=" + $Chrono[$i]+"s"
        $ServicesWtmp = "\nWARNING : " +$svc[0]+" "+$Chrono[$i]+"s" 
        $ServicesCtmp = "\nCRITICAL : " +$svc[0]+" "+$Chrono[$i]+"s" 

        if($svc[1] -ne "") { 
            $PerfDataTemp += ";"+$svc[1]
            if($Chrono[$i] -gt $svc[1]) { $ServicesW=$ServicesW+$ServicesWtmp }
        }
        if($svc[2] -ne "") { 
            $PerfDataTemp += ";"+$svc[2] 
            if($Chrono[$i] -gt $svc[2]) { 
                $ServicesC=$ServicesC+$ServicesCtmp
                $ServicesW = $ServicesW.Replace($ServicesWtmp,"")
            }
        }
        $i++
    }

    $PerfData = $PerfData + "Total" + "=" + $ChronoTotal + "s;" + $BorneInferieure + ";" + $BorneSuperieure 
    $PerfData = $PerfData + $PerfDataTemp

    return @($ChronoTotal,$PerfData,$ServicesW,$ServicesC)

}

# Cryptage du password
Function GetCryptedPass 
{

    param (
        [Parameter(Mandatory=$false)][string]$Password
    )

    if($Password) {
        $Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File $PassApp
    }
    
    $SecurePassword = Get-Content $PassApp | ConvertTo-SecureString
    $Marshal = [System.Runtime.InteropServices.Marshal]
    $Bstr = $Marshal::SecureStringToBSTR($SecurePassword)
    $Password = $Marshal::PtrToStringAuto($Bstr)
    $Marshal::ZeroFreeBSTR($Bstr)

    return $Password
}

# Function de recherche image
Function SetScreenResolution
{

    param (
        [int] $ResolutionX,
        [int] $ResolutionY,
        [int] $debug=2
    )


    $out = & $Path"\SetScreenSetting.exe" $ResolutionX $ResolutionY $debug
    $State = [int]$out.Split('|')[0]
    
    if ($State -ne 0) {
        throw [System.IO.FileNotFoundException] "The resolution $ResolutionX x $ResolutionY cannot be set on this workstation."
    }
}

# Function to check if Image is foundable whitout exit.
# Return 0 if image exist. 1 if image is not foundable.
Function ImageNotExist
{
    param (
    [Parameter(Mandatory=$true)][string]$ImageToFind,
    [Parameter(Mandatory=$true)][string]$Retries,
    [bool]$returncode=$false
    )

    $xy=ImageSearch $ImageToFind $Retries 2 $EonServ 250 1 30
    AddValues "INFO" "(ImageNotExist) out of image Search."
    $x = [int]$xy[0]
    $y = [int]$xy[1]
    if (($x -eq -1) -and ($y -eq -1))
    {
        $returncode=$true
        AddValues "INFO" "(ImageNotExist)Image $ImageToFind not found."
    } 
    AddValues "INFO" "(ImageNotExist) Image $ImageToFind was found."
    return $xy
}

function Minimize-All-Windows
{
    AddValues "INFO" "Minimize all windows."
    & $Path\MinimizeAllWindows.exe
}