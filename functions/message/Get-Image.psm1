[cmdletbinding()]
Param([bool]$verbose)
$VerbosePreference = if ($verbose) { 'Continue' } else { 'SilentlyContinue' }
$ProgressPreference = "SilentlyContinue"

function Get-Image ($imageTagMatch, $assetsFolderPath, $clientId, $tenantId) {
    $imageUriPath = $imageTagMatch.Groups[1].Value
    $imageUriPathStream = [IO.MemoryStream]::new([byte[]][char[]]$imageUriPath)
    $imageFileName = "$((Get-FileHash -InputStream $imageUriPathStream -Algorithm SHA256).Hash).jpg"
    $imageFilePath = Join-Path -Path "$assetsFolderPath" -ChildPath "$imageFileName"

    if (-not(Test-Path $imageFilePath)) {
        Write-Verbose "Image cache miss, downloading."

        $imageUri = "https://graph.microsoft.com" + $imageUriPath
        
        try {
            $start = Get-Date

            Invoke-Retry -Code {
                Invoke-WebRequest -Uri $imageUri -Headers @{
                    "Authorization" = "Bearer $(Get-GraphAccessToken $clientId $tenantId)"
                } -OutFile $imageFilePath
            }

            Write-Verbose "Took $(((Get-Date) - $start).TotalSeconds)s to download image."

            $image = "assets/$imageFileName"
        }
        catch {
            Write-Verbose "Failed to fetch image, returning input."
            $image = $imageUri
        }
    }
    else {
        Write-Verbose "Image cache hit."
        $image = "assets/$imageFileName"
    }

    $image
}
