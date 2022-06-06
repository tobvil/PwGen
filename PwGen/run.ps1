using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Output "PowerShell HTTP trigger function processed a request."

Write-Output "Request from $($request.Headers.'x-forwarded-for')"

if ($request.Query.id) {
  
    $RandomID = $Request.Query.ID

    $secret = Get-KeyVaultPassword -ID $RandomID

    if (!($secret)) {
        $Password = "No Password found. The link may have expired."

        $expires = New-TimeSpan
    }
    else {
        $password = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
    
        $expires = $secret.Expires - (Get-Date).ToUniversalTime()
    }

    # Interact with query parameters or the body of the request.
    $Body = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>Norlys Password Generator</Title>
    <link rel="icon" href="$($ENV:IconURL)">
    <meta name="viewport" content="width=device-width">
    <script>
        function copyFunction() {
            var copyText = document.getElementById("password");
            copyText.select();
            copyText.setSelectionRange(0, 99999);
            document.execCommand("copy");
        }
    </script>
    <style>
        input#password {

            width: 70%;
            padding: 12px 20px;
            margin: 8px 0;
            display: inline-block;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
        }

        button {
            width: 25%;
            background-color: #0f3d24;
            color: white;
            padding: 14px 20px;
            margin: 8px 0;
            border: none;
            border-radius: 20px;
            cursor: pointer;
            transition: transform 0.1s;
        }

        button:hover {
            transform: scale(1.01);
        }

        div {
            border-radius: 5px;
            background-color: #f2f2f2;
            padding: 20px;
            width: 40%;
            font-family: "Basis Grotesque Pro", sans-serif;
        }
    </style>
</head>

<body>
    <center>
        <img src="$($ENV:LogoURL)" alt="Logo">
        <div>
            <h3>Link expires in $($expires.Days)d $($expires.Hours)h $($expires.Minutes)m $($expires.Seconds)s</h3>
            <input type="text" id="password" name="password" value="$($Password)" readonly><br>
            <button class="button" onclick="copyFunction()">
                Copy
            </button>
        </div>
    </center>
</body>

</html>
"@

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name 'Response' -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Body        = $Body
            ContentType = 'text/html'
        })
}

else {

    $length = 16

    #Check body if password has been posted as form data
    if ($Request.Body) {

        $formData = $Request.Body.Split('&') | ConvertFrom-StringData

        if ($formData.Password) {

            $urlEncodedPassword = $formData.Password
            $urlEncodedPasswordRetention = $formData.Retention

            #Url's are encoded, so we need to decode
            $Password = [System.Web.HttpUtility]::UrlDecode($urlEncodedPassword)
            $PasswordRetention = [System.Web.HttpUtility]::UrlDecode($urlEncodedPasswordRetention)

            Write-Output $PasswordRetention

            $securePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
            $RandomID = Add-PasswordToKeyVault -Password $securePassword -PasswordRetentionInSeconds $PasswordRetention
            $URL = "https://$($Request.Headers.'disguised-host')/api/pwgen/?ID=$($RandomID)"
        }
        elseif ($formData.length) {

            $urlEncodedLength = $formData.length

            #length url encoded, so we need to decode
            $length = [System.Web.HttpUtility]::UrlDecode($urlEncodedLength)

            Write-Host $length

            $Password = New-RandomPassword -Length $length
        }
    }
    else {
        $Password = New-RandomPassword -Length $length
    }

    # Interact with query parameters or the body of the request.
    $Body = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>Norlys Password Generator</Title>
    <link rel="icon" href="$($ENV:IconURL)">
    <meta name="viewport" content="width=device-width">
    <script>
        function copyFunction() {
            var copyText = document.getElementById("URL");
            copyText.select();
            copyText.setSelectionRange(0, 99999);
            document.execCommand("copy");
        }
    </script>
    <style>
        input#password {

            width: 70%;
            padding: 12px 20px;
            margin: 8px 0;
            display: inline-block;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
        }

        input#URL {
            width: 70%;
            padding: 12px 20px;
            margin: 8px 0;
            display: inline-block;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
        }

        button {
            width: 25%;
            background-color: #0f3d24;
            color: white;
            padding: 14px 20px;
            margin: 8px 0;
            border: none;
            border-radius: 20px;
            cursor: pointer;
            transition: transform 0.1s;
        }

        button:hover {
            transform: scale(1.01);
        }

        div {
            border-radius: 5px;
            background-color: #f2f2f2;
            padding: 20px;
            width: 40%;
            font-family: "Basis Grotesque Pro", sans-serif;
        }
    </style>
</head>

<body>
    <center>
        <img src="$($ENV:LogoURL)" alt="Logo">
        <div>
            <form method="post">
                <button type="submit" class="submit">
                    Generate
                </button><br>
                <input type="number" name="length" id="length" min="8" max="256" value="$($length)">
            </form>
            <form method="post">
                <input type="text" id="password" name="password" value="$($Password)"><br>
                <button type="submit" class="submit">
                    Create
                </button><br>
                <label for="retention"></label><select id="retention" name="retention" class="form-control">
                    <option value="604800">1 Week</option>
                    <option value="3600">1 Hour</option>
                    <option value="21600">6 Hours</option>
                    <option value="86400">1 Day</option>
                    <option value="259200">3 Days</option>
                    <option value="1209600">2 Weeks</option>
                    <option value="2419200">4 Weeks</option>
                    <option value="4838400">8 Weeks</option>
                </select>
            </form>
            <input type="text" id="URL" value="$($URL)" readonly><br><br>
            <button type="button" class="button" onclick="copyFunction()">
                Copy
            </button>
        </div>
    </center>
</body>

</html>
"@

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name 'Response' -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Body        = $Body
            ContentType = 'text/html'
        })
}