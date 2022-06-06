# PowerShell function that can generate passwords and password links.

## Requirements

- Function App with managed identity enabled
- Keyvault (MSI should have get, list, set, delete permissions for secrets in the vault)
- 3 variables has to be added in the function app configuration
    - KeyVaultName -  Name of the KeyVault
    - LogoURL - The logo thats added in the HTML
    - IconURL - The icon thats added in the HTML

## Functions

### Cleanup

Triggers on a schedule and deletes expired secrets in the key vault

### Generate

Get: Returns a 16 character password

Post: Post a header called "length" with an integer between 8 and 256, and the function returns a password with specified length

### Create

Get: Returns 16 character password and URL with 7 days retention

Post: Post a header called "password" with a password of your own choosing, and the function returns the URL with 7 days retention.

Post a header called "password" and "retention", and the function returns a URL with specified password and retention. Retention is in seconds.

### Retrieve

Get: Get the password link, and the function returns the password and an expiration timer.

### AzPwGen

GUI implementation of the above functions. Returns HTML.

## Examples

### Generate 16 character password
`Invoke-RestMethod -Method 'Get' -Uri 'https://{functionName}.azurewebsites.net/api/generate'`

### Generate password with custom 256 length
`Invoke-RestMethod -Method 'Post' -Uri 'https://{functionName}.azurewebsites.net/api/generate' -Headers @{'Length'=256}`

### Create password link with 16 characters and 7 days retention
`Invoke-RestMethod -Method 'Get' -Uri 'https://{functionName}.azurewebsites.net/api/create'`

### create password link with VerySecure123! as password
`Invoke-RestMethod -Method 'Post' -Uri 'https://{functionName}.azurewebsites.net/api/create' -Headers @{'Password'='VerySecure123!'}`

### Create password link with VerySecure123! as password and 30 seconds retention
`Invoke-RestMethod -Method 'Post' -Uri 'https://{functionName}.azurewebsites.net/api/create' -Headers @{'Password'='VerySecure123!';'Retention'=30}`

### create and retrieve password
`$response = Invoke-RestMethod -Method 'Post' -Uri 'https://{functionName}.azurewebsites.net/api/create' -Headers @{'Password'='VerySecure123!';'Retention'=3600}`

`Invoke-RestMethod -Method 'Get' -Uri $response.Url`