Il est n�cessaire de renseigner deux variables durant la copie des fichiers :
	- IP Serveur EyesOfNetwork
	- Token NRDP

Pour executer le script Install.ps1, il est n�cessaire de le lancer en Administrateur. Pour se faire :
	- Lancer powershell en Administrateur (Click droit ex�cuter en tant qu'Administrateur).
	- Se placer dans le dossier contenant Install.ps1 (ex: cd c:\EON4APPS_Windows_Station_Install).
	- Executer le script (Install.ps1).

Le script copiera Tous les fichiers n�cessaires au bon fonctionnement de la sonde dans :
	- C:\eon\APX\EON4APPS\
	- Une t�che planifi�e ex�cutant la sonde www.eyesofnetwork.fr.ps1 toutes les 5 minutes sera cr�ee. 