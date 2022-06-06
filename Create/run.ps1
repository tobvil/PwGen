using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

Write-Host "Request from $($request.Headers.'x-forwarded-for')"

if ($request.Method -eq 'Get') {

    $Password = New-RandomPassword

    $securePassword = $Password | ConvertTo-SecureString -AsPlainText -Force

    $randomId = Add-PasswordToKeyVault -Password $securePassword -PasswordRetentionInSeconds 604800

    $URL = "https://$($Request.Headers.'disguised-host')/api/retrieve/?ID=$($randomId)"

    $body = @{
        Password = $Password
        Url      = $URL
    } | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Body        = $body
            ContentType = 'application/json'
        })
}

if ($request.Method -eq 'Post') {

    if ($request.Headers.Password -and (!($request.Headers.Retention))) {

        $securePassword = $request.Headers.Password | ConvertTo-SecureString -AsPlainText -Force

        $RandomID = Add-PasswordToKeyVault -Password $securePassword -PasswordRetentionInSeconds 604800

    }
    elseif ($request.Headers.Password -and $request.Headers.Retention) {

        $securePassword = $request.Headers.Password | ConvertTo-SecureString -AsPlainText -Force

        $RandomID = Add-PasswordToKeyVault -Password $securePassword -PasswordRetentionInSeconds $request.Headers.Retention

    }

    $URL = "https://$($Request.Headers.'disguised-host')/api/retrieve/?ID=$($RandomID)"

    $body = @{
        Url = $URL
    } | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Body        = $body
            ContentType = 'application/json'
        })
}