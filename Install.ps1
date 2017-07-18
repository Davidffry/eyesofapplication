[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') 
$EonServ = [Microsoft.VisualBasic.Interaction]::InputBox("IP du serveur EON", "Configuration NRDP", "")
$EonToken = [Microsoft.VisualBasic.Interaction]::InputBox("Token NRDP", "Configuration NRDP", "")

$Path = Get-Location
$ApxPath = "C:\Axians\EOA\"
$Purge = $ApxPath + "purge.ps1"
$Sonde = $ApxPath + "eon4apps.ps1"

New-Item $ApxPath -Type directory
Copy-Item -Path $Path"\Dependances\Apps" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\bin" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\Docs" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\Images" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\lib" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\log" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\ps" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\sshkey" -Destination $ApxPath -Recurse




Copy-Item -Path $Path"\Dependances\EyesOfApplicationGUI.exe" -Destination $ApxPath

SCHTASKS /Create /SC MINUTE /MO 5 /TN EON4APPS /TR "powershell -WindowStyle Minimized -ExecutionPolicy Bypass -File '$Sonde' www.eyesofnetwork.fr $EonServ $EonToken https://$EonServ/nrdp/ true"
