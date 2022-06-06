function Invoke-CleanupKeyVault {
    
    $secrets = Get-AzKeyVaultSecret -VaultName $env:KeyVaultName

    $currentDate = (Get-Date).ToUniversalTime()

    foreach ($secret in $secrets) {
        if ($CurrentDate -gt $secret.Expires) {
            
            Remove-AzKeyVaultSecret -VaultName $env:KeyVaultName -Name $secret.Name -Force -PassThru
        }
    }
}
function Add-PasswordToKeyVault {
    [CmdletBinding()]
    param (
        [Parameter()]
        [SecureString]
        $Password,
        
        [Parameter()]
        [Int]
        $PasswordRetentionInSeconds
    )

    $id = (New-Guid).ToString().Replace('-', '')

    $retentionDate = (Get-Date).ToUniversalTime().AddSeconds($PasswordRetentionInSeconds)

    $null = Set-AzKeyVaultSecret -VaultName $env:KeyVaultName -Name $id -SecretValue $Password -Expires $retentionDate
    
    $id
}
function Get-KeyVaultPassword {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]
        $ID
    )

    try {

        $secret = Get-AzKeyVaultSecret -VaultName $env:KeyVaultName -Name $ID -ErrorAction 'Stop'

        if ($secret.Expires.ToUniversalTime() -lt (Get-Date).ToUniversalTime()) {
            throw
        }
        $secret
    }
    catch {
        $false
    }
}
Function New-RandomPassword {
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateRange(8, 256)]
        [int]
        $Length = 16
    )

    $lowerCase = 'abcdefghijklmnopqrstuvwxyz'
    $upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '123456789'
    $signs = '!@#$%&?'

    $all = $lowerCase + $upperCase + $numbers + $signs

    $lower = $lowerCase.ToCharArray() | Get-Random
    $upper = $upperCase.ToCharArray() | Get-Random
    $number = $numbers.ToCharArray() | Get-Random
    $sign = $signs.ToCharArray() | Get-Random

    $randomPassword = -join (1..($Length - 4) | ForEach-Object { Get-Random -InputObject $all.ToCharArray() })

    $password = $randomPassword + $lower + $upper + $number + $sign

    #shuffle Password
    $shuffledPassword = -join (Get-Random -Shuffle -InputObject $password.ToCharArray())

    $shuffledPassword
}