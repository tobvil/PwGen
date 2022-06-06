using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

Write-Host "Request from $($request.Headers.'x-forwarded-for')"

if ($request.Method -eq 'Get') {

    $Password = New-RandomPassword -Length 16

    $body = $password | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Body        = $body
            ContentType = 'application/json'
        })
}

if ($request.Method -eq 'Post') {

    if ($request.Headers.Length) {

        $Password = New-RandomPassword -Length $request.Headers.Length

        $body = $password | ConvertTo-Json

        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                Body        = $body
                ContentType = 'application/json'
            })
    }
}