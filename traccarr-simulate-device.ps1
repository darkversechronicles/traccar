
$Builder = New-Object System.UriBuilder('http', '127.0.0.1', 5055)
$Builder.Path = '/'
$Builder.Query = 'id=video-demo-001&lat=18.4655&lon=-66.1057'

$Response = Invoke-WebRequest -Uri $Builder.Uri.AbsoluteUri -UseBasicParsing
Write-Host "GPS Status: $($Response.StatusCode)" -ForegroundColor Green
