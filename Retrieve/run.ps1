using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

Write-Host "Request from $($request.Headers.'x-forwarded-for')"

if ($request.Query.ID) {
  
    $RandomID = $Request.Query.ID

    $secret = Get-KeyVaultPassword -ID $RandomID

    if (!($secret)) {
        $Password = "No Password found. The link may have expired."

        $body = $password | ConvertTo-Json

        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Forbidden
                Body        = $body
                ContentType = 'application/json'
            })
    }
    else {
        $password = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
    
        $expires = $secret.Expires - (Get-Date).ToUniversalTime()

        $body = @{
            Password = $password
            Expires  = $expires
        } | ConvertTo-Json

        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                Body        = $body
                ContentType = 'application/json'
            })
    }
}