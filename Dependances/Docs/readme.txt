# Wait 2 seconds
Start-Sleep 2 
 
# Add logs 
AddValues "LEVEL" "Text to add in app log file"

# Send keys
Send-Keys "COUCOU"

# Send special keys
Send-SpecialKeys "{ENTER}"

# Image search 
$xy = ImageSearch $Image $ImageSearchRetries $ImageSearchVerbosity $EonSrv $Wait $noerror $variance $green

# Left click on the image
ImageClick $xy
