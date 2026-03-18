function Get-DattoBCDRAPIKey {
<#
    .SYNOPSIS
        Gets the Datto API public & secret key global variables

    .DESCRIPTION
        The Get-DattoBCDRAPIKey cmdlet gets the Datto API public & secret key
        global variables and returns them as an object

    .PARAMETER AsPlainText
        Decrypt and return the API key in plain text

    .EXAMPLE
        Get-DattoBCDRAPIKey

        Gets the Datto API public & secret key global variables and returns them
        as an object with the secret key as a SecureString

    .EXAMPLE
        Get-DattoBCDRAPIKey -AsPlainText

        Gets the Datto API public & secret key global variables and returns them
        as an object with the secret key as plain text


    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Get-DattoBCDRAPIKey.html
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$AsPlainText
    )

    begin {}

    process {

        try {

            if ($DattoBCDRModuleApiSecretKey){

                if ($AsPlainText){
                    $ApiKey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DattoBCDRModuleApiSecretKey)

                    [PSCustomObject]@{
                        PublicKey = $DattoBCDRModuleApiKey
                        SecretKey = ([System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ApiKey)).ToString()
                    }
                }
                else {
                    [PSCustomObject]@{
                        PublicKey = $DattoBCDRModuleApiKey
                        SecretKey = $DattoBCDRModuleApiSecretKey
                    }
                }

            }
            else { Write-Warning "The Datto API [ secret ] key is not set. Run Add-DattoBCDRAPIKey to set the API key." }

        }
        catch {
            Write-Error $_
        }
        finally {
            if ($ApiKey) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ApiKey)
            }
        }


    }

    end {}

}
