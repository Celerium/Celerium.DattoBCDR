#Region '.\Private\ApiCalls\ConvertTo-DattoBCDRQueryString.ps1' -1

function ConvertTo-DattoBCDRQueryString {
<#
    .SYNOPSIS
        Converts uri filter parameters

    .DESCRIPTION
        The Invoke-DattoBCDRRequest cmdlet converts & formats uri filter parameters
        from a function which are later used to make the full resource uri for
        an API call

        This is an internal helper function the ties in directly with the
        Invoke-DattoBCDRRequest & any public functions that define parameters

    .PARAMETER UriFilter
        Hashtable of values to combine a functions parameters with
        the ResourceUri parameter

        This allows for the full uri query to occur

    .EXAMPLE
        ConvertTo-DattoBCDRQueryString -UriFilter $UriFilter -ResourceUri '/account'

        Example: (From public function)
            $UriFilter = @{}

            ForEach ( $Key in $PSBoundParameters.GetEnumerator() ){
                if( $excludedParameters -contains $Key.Key ){$null}
                else{ $UriFilter += @{ $Key.Key = $Key.Value } }
            }

            1x key = https://api.datto.com/v1/account?accountId=12345
            2x key = https://api.datto.com/v1/account?accountId=12345&details=True

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/ConvertTo-DattoBCDRQueryString.html

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$UriFilter
)

    begin {}

    process {

        if (-not $UriFilter) {
            return ""
        }

        $params = @()
        foreach ($key in $UriFilter.Keys) {

            $rawValue = $UriFilter[$key]

            if ($rawValue -is [System.Collections.IEnumerable] -and $rawValue -isnot [string]) {
                foreach ($item in $rawValue) {
                    $encodedValue = [System.Net.WebUtility]::UrlEncode($item)
                    $params += "$key=$encodedValue"
                }
            }
            else {
                $encodedValue = [System.Net.WebUtility]::UrlEncode($rawValue)
                $params += "$key=$encodedValue"
            }

        }

        $QueryString = '?' + ($params -join '&')
        return $QueryString

    }

    end {}

}
#EndRegion '.\Private\ApiCalls\ConvertTo-DattoBCDRQueryString.ps1' 82
#Region '.\Private\ApiCalls\Get-DattoBCDRMetaData.ps1' -1

function Get-DattoBCDRMetaData {
<#
    .SYNOPSIS
        Gets various Api metadata values

    .DESCRIPTION
        The Get-DattoBCDRMetaData cmdlet gets various Api metadata values from an
        Invoke-WebRequest to assist in various troubleshooting scenarios such
        as rate-limiting

    .PARAMETER BaseUri
        Define the base URI for the Datto API connection using Datto's URI or a custom URI

        The default base URI is https://api.datto.com/v1

    .EXAMPLE
        Get-DattoBCDRMetaData

        Gets various Api metadata values from an Invoke-WebRequest to assist
        in various troubleshooting scenarios such as rate-limiting

        The default full base uri test path is:
            https://api.datto.com/v1

    .EXAMPLE
        Get-DattoBCDRMetaData -BaseUri http://myapi.gateway.celerium.org

        Gets various Api metadata values from an Invoke-WebRequest to assist
        in various troubleshooting scenarios such as rate-limiting

        The full base uri test path in this example is:
            http://myapi.gateway.celerium.org/device

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Get-DattoBCDRMetaData.html
#>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$BaseUri = $DattoBCDRModuleBaseUri
    )

    begin { $ResourceUri = "/bcdr/agent" }

    process {

        try {

            $ApiToken = Get-DattoBCDRAPIKey -AsPlainText
            $ApiTokenBase64 = [Convert]::ToBase64String( [Text.Encoding]::ASCII.GetBytes( ("{0}:{1}" -f ($ApiToken).PublicKey,($ApiToken).SecretKey) ) )

            $DattoHeaders = New-Object "System.Collections.Generic.Dictionary[[string],[string]]"
            $DattoHeaders.Add("Content-Type", 'application/json')
            $DattoHeaders.Add('Authorization', 'Basic {0}'-f $ApiTokenBase64)

            $RestOutput = Invoke-WebRequest -Method Get -uri ($BaseUri + $ResourceUri) -headers $DattoHeaders -ErrorAction Stop
        }
        catch {

            [PSCustomObject]@{
                Method = $_.Exception.Response.Method
                StatusCode = $_.Exception.Response.StatusCode.value__
                StatusDescription = $_.Exception.Response.StatusDescription
                Message = $_.Exception.Message
                URI = $($DattoBCDRModuleBaseUri + $ResourceUri)
            }

        }
        finally {
            Remove-Variable -Name DattoHeaders -Force
        }

        if ($RestOutput){
            $Data = @{}
            $Data = $RestOutput

            [PSCustomObject]@{
                ResponseUri             = $Data.BaseResponse.ResponseUri.AbsoluteUri
                ResponsePort            = $Data.BaseResponse.ResponseUri.Port
                StatusCode              = $Data.StatusCode
                StatusDescription       = $Data.StatusDescription
                'Content-Type'          = $Data.headers.'Content-Type'
                'X-Request-Id'          = $Data.headers.'X-Request-Id'
                'X-API-Limit-Remaining' = $Data.headers.'X-API-Limit-Remaining'
                'X-API-Limit-Resets'    = $Data.headers.'X-API-Limit-Resets'
                'X-API-Limit-Cost'      = $Data.headers.'X-API-Limit-Cost'
                raw                     = $Data
            }
        }

    }

    end {}
}
#EndRegion '.\Private\ApiCalls\Get-DattoBCDRMetaData.ps1' 99
#Region '.\Private\ApiCalls\Invoke-DattoBCDRRequest.ps1' -1

function Invoke-DattoBCDRRequest {
<#
    .SYNOPSIS
        Makes an API request

    .DESCRIPTION
        The Invoke-DattoBCDRRequest cmdlet invokes an API request to Datto API

        This is an internal function that is used by all public functions

        As of 2023-09 the Datto v1 API only supports GET and PUT requests

    .PARAMETER method
        Defines the type of API method to use

        Allowed values:
        'GET', 'PUT'

    .PARAMETER ResourceUri
        Defines the resource uri (url) to use when creating the API call

    .PARAMETER UriFilter
        Used with the internal function [ ConvertTo-DattoBCDRQueryString ] to combine
        a functions parameters with the ResourceUri parameter

        This allows for the full uri query to occur

        The full resource path is made with the following data
        $DattoBCDRModuleBaseUri + $ResourceUri + ConvertTo-DattoBCDRQueryString

    .PARAMETER Data
        Place holder parameter to use when other methods are supported
        by the Datto v1 API

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API
    .EXAMPLE
        Invoke-DattoBCDRRequest -Method GET -ResourceUri '/account' -UriFilter $UriFilter

        Invoke a rest method against the defined resource using any of the provided parameters

        Example:
            Name                           Value
            ----                           -----
            Method                         GET
            Uri                            https://api.datto.com/v1/account?accountId=12345&details=True
            Headers                        {Authorization = Bearer 123456789}
            Body


    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Invoke-DattoBCDRRequest.html

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('GET','PUT')]
        [string]$method = 'GET',

        [Parameter(Mandatory = $true)]
        [string]$ResourceUri,

        [Parameter(Mandatory = $false)]
        [hashtable]$UriFilter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Data = $null,

        [Parameter(Mandatory = $false)]
        [switch]$AllResults

    )

    begin {

        # Load Web assembly when needed as PowerShell Core has the assembly preloaded
        if ( !("System.Web.HttpUtility" -as [Type]) ) {
            Add-Type -Assembly System.Web
        }

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        if ($UriFilter) {
            $QueryString = ConvertTo-DattoBCDRQueryString -UriFilter $UriFilter
            Set-Variable -Name $QueryParameterName -Value $QueryString -Scope Global -Force -Confirm:$false
        }

        if ($null -eq $Data) {
            $body = $null
        } else {
            $body = $Data | ConvertTo-Json -Depth $DattoBCDRModuleJSONConversionDepth
        }

        try {
            $ApiToken = Get-DattoBCDRAPIKey -AsPlainText
            $ApiTokenBase64 = [Convert]::ToBase64String( [Text.Encoding]::ASCII.GetBytes( ("{0}:{1}" -f ($ApiToken).PublicKey,($ApiToken).SecretKey) ) )

            $parameters = [ordered] @{
                "Method"    = $method
                "Uri"       = $DattoBCDRModuleBaseUri + $ResourceUri + $QueryString
                "Headers"   = @{ 'Authorization' = 'Basic {0}'-f $ApiTokenBase64 }
                "Body"      = $body
            }

                if ( $method -ne 'GET' ) {
                    $parameters['ContentType'] = 'application/json; charset=utf-8'
                }

            Set-Variable -Name $ParameterName -Value $parameters -Scope Global -Force -Confirm:$false

            if ($AllResults) {

                Write-Verbose "Gathering all items from [  $( $DattoBCDRModuleBaseUri + $ResourceUri ) ] "

                $PageNumber = 1
                $AllResponseData = [System.Collections.Generic.List[object]]::new()

                do {

                    $parameters['Uri'] = $QueryString.Uri -replace '_page=\d+',"_page=$PageNumber"

                    $CurrentPage = Invoke-RestMethod @parameters -ErrorAction Stop

                    Write-Verbose "[ $PageNumber ] of [ $($CurrentPage.pagination.totalPages) ] Pages"

                        foreach ($item in $CurrentPage.items) {
                            $AllResponseData.add($item)
                        }

                    $PageNumber++

                } while ($CurrentPage.pagination.totalPages -ne $PageNumber - 1 -and $CurrentPage.pagination.totalPages -ne 0)

            }
            else{
                $ApiResponse = Invoke-RestMethod @parameters -ErrorAction Stop
            }

        }
        catch {

            $exceptionError = $_.Exception.Message
            Write-Warning 'The [ Invoke_DattoBCDRRequest_Parameters, Invoke_DattoBCDRRequest_ParametersQuery, & CmdletName_Parameters ] variables can provide extra details'

            switch -Wildcard ($exceptionError) {
                '*404*' { Write-Error "Invoke-DattoBCDRRequest : URI not found - [ $ResourceUri ]" }
                '*429*' { Write-Error 'Invoke-DattoBCDRRequest : API rate limited' }
                '*504*' { Write-Error "Invoke-DattoBCDRRequest : Gateway Timeout" }
                default { Write-Error $_ }
            }

        }
        finally {

            $Auth = $Invoke_DattoBCDRRequest_Parameters['headers']['Authorization']
            $Invoke_DattoBCDRRequest_Parameters['headers']['Authorization'] = $Auth.Substring( 0, [Math]::Min($Auth.Length, 9) ) + '*******'

        }

        if($AllResults) {

            #Making output consistent
            if( [string]::IsNullOrEmpty($AllResponseData.data) ) {
                $ApiResponse = $null
            }
            else{
                $ApiResponse = [PSCustomObject]@{
                    pagination  = $null
                    items       = $AllResponseData
                }
            }

            return $ApiResponse

        }
        else{

            #Making output consistent
            if ($ApiResponse.PSObject.Properties.Name -contains 'pagination') {
                return $ApiResponse
            }
            else{
                return [PSCustomObject]@{
                    pagination  = $null
                    items       = $ApiResponse
                }
            }

        }

    }

    end {}

}
#EndRegion '.\Private\ApiCalls\Invoke-DattoBCDRRequest.ps1' 211
#Region '.\Private\ApiKeys\Add-DattoBCDRAPIKey.ps1' -1

function Add-DattoBCDRAPIKey {
<#
    .SYNOPSIS
        Sets the API public & secret keys used to authenticate API calls

    .DESCRIPTION
        The Add-DattoBCDRAPIKey cmdlet sets the API public & secret keys
        which are used to authenticate all API calls made to Datto

        The Datto API keys are generated via the Datto portal
        Admin > Integrations

    .PARAMETER ApiKeyPublic
        Defines your API public key

    .PARAMETER ApiKeySecret
        Defines your API secret key

    .EXAMPLE
        Add-DattoBCDRAPIKey

        Prompts to enter in the API public key and secret key

    .EXAMPLE
        Add-DattoBCDRAPIKey -ApiKeyPublic '12345'

        The Datto API will use the string entered into the [ -ApiKeyPublic ] parameter as the
        public key & will then prompt to enter in the secret key

    .EXAMPLE
        '12345' | Add-DattoBCDRAPIKey

        The Datto API will use the string entered as the secret key & will prompt to enter in the public key

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Add-DattoBCDRAPIKey.html
#>

    [CmdletBinding()]
    [Alias('Set-DattoBCDRAPIKey')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKeyPublic,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKeySecret
    )

    begin {}

    process {

        if ($ApiKeySecret) {
            $SecureString = ConvertTo-SecureString $ApiKeySecret -AsPlainText -Force

            Set-Variable -Name "DattoBCDRModuleApiKey" -Value $ApiKeyPublic -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleApiSecretKey" -Value $SecureString -Option ReadOnly -Scope Global -Force
        }
        else {
            $SecureString = Read-Host -Prompt 'Please enter your API key:' -AsSecureString

            Set-Variable -Name "DattoBCDRModuleApiKey" -Value $ApiKeyPublic -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleApiSecretKey" -Value $SecureString -Option ReadOnly -Scope Global -Force
        }

    }

    end {}
}
#EndRegion '.\Private\ApiKeys\Add-DattoBCDRAPIKey.ps1' 75
#Region '.\Private\ApiKeys\Get-DattoBCDRAPIKey.ps1' -1

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
                        SecretKey = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ApiKey)).ToString()
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
#EndRegion '.\Private\ApiKeys\Get-DattoBCDRAPIKey.ps1' 81
#Region '.\Private\ApiKeys\Remove-DattoBCDRAPIKey.ps1' -1

function Remove-DattoBCDRAPIKey {
<#
    .SYNOPSIS
        Removes the Datto API public & secret key global variables

    .DESCRIPTION
        The Remove-DattoBCDRAPIKey cmdlet removes the Datto API public & secret key global variables

    .EXAMPLE
        Remove-DattoBCDRAPIKey

        Removes the Datto API public & secret key global variables

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Remove-DattoBCDRAPIKey.html
#>

    [cmdletbinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        switch ([bool]$DattoBCDRModuleApiKey) {
            $true   { Remove-Variable -Name "DattoBCDRModuleApiKey" -Scope Global -Force }
            $false  { Write-Warning "The Datto API [ public ] key is not set. Nothing to remove" }
        }

        switch ([bool]$DattoBCDRModuleApiSecretKey) {
            $true   { Remove-Variable -Name "DattoBCDRModuleApiSecretKey" -Scope Global -Force }
            $false  { Write-Warning "The Datto API [ secret ] key is not set. Nothing to remove" }
        }

    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Remove-DattoBCDRAPIKey.ps1' 43
#Region '.\Private\ApiKeys\Test-DattoBCDRAPIKey.ps1' -1

function Test-DattoBCDRAPIKey {
<#
    .SYNOPSIS
        Test the Datto API public & secret keys

    .DESCRIPTION
        The Test-DattoBCDRAPIKey cmdlet tests the base URI & API public & secret keys that were defined in the
        Add-DattoBCDRBaseURI & Add-DattoBCDRAPIKey cmdlets

    .PARAMETER BaseUri
        Define the base URI for the Datto API connection using Datto's URI or a custom URI

        The default base URI is https://api.datto.com/v1/bcdr

    .EXAMPLE
        Test-DattoBCDRBaseURI

        Tests the base URI & API access token that was defined in the
        Add-DattoBCDRBaseURI & Add-DattoBCDRAPIKey cmdlets

        The default full base uri test path is:
            https://api.datto.com/v1/bcdr/device

    .EXAMPLE
        Test-DattoBCDRBaseURI -BaseUri http://myapi.gateway.celerium.org

        Tests the base URI & API access token that was defined in the
        Add-DattoBCDRBaseURI & Add-DattoBCDRAPIKey cmdlets

        The full base uri test path in this example is:
            http://myapi.gateway.celerium.org/device

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Test-DattoBCDRAPIKey.html
#>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $true)]
        [string]$BaseUri = $DattoBCDRModuleBaseUri
    )

    begin { $ResourceUri = "/bcdr/agent" }

    process {

        try {

            $ApiToken = Get-DattoBCDRAPIKey -AsPlainText
            $ApiTokenBase64 = [Convert]::ToBase64String( [Text.Encoding]::ASCII.GetBytes( ("{0}:{1}" -f ($ApiToken).PublicKey,($ApiToken).SecretKey) ) )

            $Headers = @{}
            $Headers.Add('Authorization', 'Basic {0}'-f $ApiTokenBase64)

            $Parameters = @{
                'Method'        = 'GET'
                'Uri'           = $BaseUri + $ResourceUri
                'Headers'       = $Headers
                'UserAgent'     = $DattoBCDRModuleUserAgent
                UseBasicParsing = $true
            }

            $RestOutput = Invoke-WebRequest @Parameters -ErrorAction Stop
        }
        catch {

            [PSCustomObject]@{
                Method              = $_.Exception.Response.Method
                StatusCode          = $_.Exception.Response.StatusCode.value__
                StatusDescription   = $_.Exception.Response.StatusDescription
                Message             = $_.Exception.Message
                URI                 = $($DattoBCDRModuleBaseUri + $ResourceUri)
            }

        }
        finally {
            [void] ($Headers.Remove('Authorization'))
        }

        if ($RestOutput) {
            $Data = @{}
            $Data = $RestOutput

            [PSCustomObject]@{
                StatusCode          = $Data.StatusCode
                StatusDescription   = $Data.StatusDescription
                URI                 = $($DattoBCDRModuleBaseUri + $ResourceUri)
            }
        }

    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Test-DattoBCDRAPIKey.ps1' 99
#Region '.\Private\BaseUri\Add-DattoBCDRBaseURI.ps1' -1

function Add-DattoBCDRBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the Datto API connection

    .DESCRIPTION
        The Add-DattoBCDRBaseURI cmdlet sets the base URI which is
        later used to construct the full URI for all API calls

    .PARAMETER BaseUri
        Define the base URI for the Datto API connection using Datto's URI or a custom URI

    .PARAMETER DataCenter
        Datto's URI connection point that can be one of the predefined data centers

        The accepted values for this parameter are:
        [ US ]
            US = https://api.datto.com/v1

    .EXAMPLE
        Add-DattoBCDRBaseURI

        The default base URI will use https://api.datto.com/v1

    .EXAMPLE
        Add-DattoBCDRBaseURI -DataCenter US

        The default base URI will use https://api.datto.com/v1

    .EXAMPLE
        Add-DattoBCDRBaseURI -BaseUri http://myapi.gateway.celerium.org

        A custom API gateway of http://myapi.gateway.celerium.org will be used
        for all API calls to Datto's API

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Add-DattoBCDRBaseURI.html
#>

    [cmdletbinding(DefaultParameterSetName = 'PreDefinedUri')]
    [Alias('Set-DattoBCDRBaseURI')]
    Param (
        [Parameter(Mandatory = $false , ValueFromPipeline = $true)]
        [string]$BaseUri = 'https://api.datto.com/v1',

        [Parameter(Mandatory = $false)]
        [ValidateSet( 'US' )]
        [string]$DataCenter
    )

    begin {}

    process {

        if ($BaseUri[$BaseUri.Length-1] -eq "/") {
            $BaseUri = $BaseUri.Substring(0,$BaseUri.Length-1)
        }

        switch ($DataCenter) {
            'US' { $BaseUri = 'https://api.datto.com/v1' }
        }

        Set-Variable -Name "DattoBCDRModuleBaseUri" -Value $BaseUri -Option ReadOnly -Scope Global -Force

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Add-DattoBCDRBaseURI.ps1' 73
#Region '.\Private\BaseUri\Get-DattoBCDRBaseURI.ps1' -1

function Get-DattoBCDRBaseURI {
<#
    .SYNOPSIS
        Shows the Datto base URI global variable

    .DESCRIPTION
        The Get-DattoBCDRBaseURI cmdlet shows the Datto
        base URI global variable value

    .EXAMPLE
        Get-DattoBCDRBaseURI

        Shows the Datto base URI global variable value

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Get-DattoBCDRBaseURI.html
#>

    [cmdletbinding(DefaultParameterSetName = 'Index')]
    Param ()

    begin {}

    process {

        switch ([bool]$DattoBCDRModuleBaseUri) {
            $true   { $DattoBCDRModuleBaseUri }
            $false  { Write-Warning "The Datto base URI is not set. Run Add-DattoBCDRBaseURI to set the base URI." }
        }

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Get-DattoBCDRBaseURI.ps1' 39
#Region '.\Private\BaseUri\Remove-DattoBCDRBaseURI.ps1' -1

function Remove-DattoBCDRBaseURI {
<#
    .SYNOPSIS
        Removes the Datto base URI global variable

    .DESCRIPTION
        The Remove-DattoBCDRBaseURI cmdlet removes the Datto
        base URI global variable

    .EXAMPLE
        Remove-DattoBCDRBaseURI

        Removes the Datto base URI global variable

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Remove-DattoBCDRBaseURI.html
#>

    [cmdletbinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        switch ([bool]$DattoBCDRModuleBaseUri) {

            $true   {
                if ($PSCmdlet.ShouldProcess('DattoBCDRModuleBaseUri')) {
                    Remove-Variable -Name "DattoBCDRModuleBaseUri" -Scope Global -Force
                }
            }
            $false  { Write-Warning "The DattoBCDR base URI variable is not set. Nothing to remove" }

        }

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Remove-DattoBCDRBaseURI.ps1' 45
#Region '.\Private\ModuleSettings\Export-DattoBCDRModuleSettings.ps1' -1

function Export-DattoBCDRModuleSettings {
<#
    .SYNOPSIS
        Exports the Datto BaseURI, API, & JSON configuration information to file

    .DESCRIPTION
        The Export-DattoBCDRModuleSettings cmdlet exports the Datto BaseURI, API, & JSON configuration information to file

        Making use of PowerShell's System.Security.SecureString type, exporting module settings encrypts your API key in a format
        that can only be unencrypted with the your Windows account as this encryption is tied to your user principal
        This means that you cannot copy your configuration file to another computer or user account and expect it to work

    .PARAMETER DattoBCDRConfPath
        Define the location to store the Datto configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfFile
        Define the name of the Datto configuration file

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Export-DattoBCDRModuleSettings

        Validates that the BaseURI, API, and JSON depth are set then exports their values
        to the current user's Datto configuration file located at:
            $env:USERPROFILE\Celerium.DattoBCDR\config.psd1

    .EXAMPLE
        Export-DattoBCDRModuleSettings -DattoBCDRConfPath C:\Celerium.DattoBCDR -DattoBCDRConfFile MyConfig.psd1

        Validates that the BaseURI, API, and JSON depth are set then exports their values
        to the current user's Datto configuration file located at:
            C:\Celerium.DattoBCDR\MyConfig.psd1

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Export-DattoBCDRModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Set')]
    Param (
        [Parameter(ParameterSetName = 'Set')]
        [string]$DattoBCDRConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"Celerium.DattoBCDR"}else{".Celerium.DattoBCDR"}) ),

        [Parameter(ParameterSetName = 'Set')]
        [string]$DattoBCDRConfFile = 'config.psd1'
    )

    begin {}

    process {

        Write-Warning "Secrets are stored using Windows Data Protection API (DPAPI)"
        Write-Warning "DPAPI provides user context encryption in Windows but NOT in other operating systems like Linux or UNIX. It is recommended to use a more secure & cross-platform storage method"

        $DattoBCDRConfig = Join-Path -Path $DattoBCDRConfPath -ChildPath $DattoBCDRConfFile

        # Confirm variables exist and are not null before exporting
        if ($DattoBCDRModuleBaseUri -and $DattoBCDRModuleApiKey -and $DattoBCDRModuleApiSecretKey -and $DattoBCDRModuleJSONConversionDepth) {
            $SecureString = $DattoBCDRModuleApiSecretKey | ConvertFrom-SecureString

            if ($IsWindows -or $PSEdition -eq 'Desktop') {
                New-Item -Path $DattoBCDRConfPath -ItemType Directory -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
            }
            else{
                New-Item -Path $DattoBCDRConfPath -ItemType Directory -Force
            }
@"
    @{
        DattoBCDRModuleBaseUri              = '$DattoBCDRModuleBaseUri'
        DattoBCDRModuleApiKey               = '$DattoBCDRModuleApiKey'
        DattoBCDRModuleApiSecretKey         = '$SecureString'
        DattoBCDRModuleJSONConversionDepth  = '$DattoBCDRModuleJSONConversionDepth'
        DattoBCDRModuleUserAgent            = '$DattoBCDRModuleUserAgent'
    }
"@ | Out-File -FilePath $DattoBCDRConfig -Force
        }
        else {
            Write-Error "Failed to export Datto Module settings to [ $DattoBCDRConfig ]"
            Write-Error $_
            exit 1
        }

    }

    end {}

}
#EndRegion '.\Private\ModuleSettings\Export-DattoBCDRModuleSettings.ps1' 95
#Region '.\Private\ModuleSettings\Get-DattoBCDRModuleSettings.ps1' -1

function Get-DattoBCDRModuleSettings {
<#
    .SYNOPSIS
        Gets the saved Datto configuration settings

    .DESCRIPTION
        The Get-DattoBCDRModuleSettings cmdlet gets the saved Datto configuration settings
        from the local system

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfPath
        Define the location to store the Datto configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfFile
        Define the name of the Datto configuration file

        By default the configuration file is named:
            config.psd1

    .PARAMETER OpenConfFile
        Opens the Datto configuration file

    .EXAMPLE
        Get-DattoBCDRModuleSettings

        Gets the contents of the configuration file that was created with the
        Export-DattoBCDRModuleSettings

        The default location of the Datto configuration file is:
            $env:USERPROFILE\Celerium.DattoBCDR\config.psd1

    .EXAMPLE
        Get-DattoBCDRModuleSettings -DattoBCDRConfPath C:\Celerium.DattoBCDR -DattoBCDRConfFile MyConfig.psd1 -OpenConfFile

        Opens the configuration file from the defined location in the default editor

        The location of the Datto configuration file in this example is:
            C:\Celerium.DattoBCDR\MyConfig.psd1

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Get-DattoBCDRModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [string]$DattoBCDRConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"Celerium.DattoBCDR"}else{".Celerium.DattoBCDR"}) ),

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [string]$DattoBCDRConfFile = 'config.psd1',

        [Parameter(Mandatory = $false, ParameterSetName = 'show')]
        [switch]$OpenConfFile
    )

    begin {
        $DattoBCDRConfig = Join-Path -Path $DattoBCDRConfPath -ChildPath $DattoBCDRConfFile
    }

    process {

        if ( Test-Path -Path $DattoBCDRConfig ){

            if($OpenConfFile){
                Invoke-Item -Path $DattoBCDRConfig
            }
            else{
                Import-LocalizedData -BaseDirectory $DattoBCDRConfPath -FileName $DattoBCDRConfFile
            }

        }
        else{
            Write-Verbose "No configuration file found at [ $DattoBCDRConfig ]"
        }

    }

    end {}

}
#EndRegion '.\Private\ModuleSettings\Get-DattoBCDRModuleSettings.ps1' 89
#Region '.\Private\ModuleSettings\Import-DattoBCDRModuleSettings.ps1' -1

function Import-DattoBCDRModuleSettings {
<#
    .SYNOPSIS
        Imports the Datto BaseURI, API, & JSON configuration information to the current session

    .DESCRIPTION
        The Import-DattoBCDRModuleSettings cmdlet imports the Datto BaseURI, API, & JSON configuration
        information stored in the Datto configuration file to the users current session

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfPath
        Define the location to store the Datto configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfFile
        Define the name of the Datto configuration file

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Import-DattoBCDRModuleSettings

        Validates that the configuration file created with the Export-DattoBCDRModuleSettings cmdlet exists
        then imports the stored data into the current users session

        The default location of the Datto configuration file is:
            $env:USERPROFILE\Celerium.DattoBCDR\config.psd1

    .EXAMPLE
        Import-DattoBCDRModuleSettings -DattoBCDRConfPath C:\Celerium.DattoBCDR -DattoBCDRConfFile MyConfig.psd1

        Validates that the configuration file created with the Export-DattoBCDRModuleSettings cmdlet exists
        then imports the stored data into the current users session

        The location of the Datto configuration file in this example is:
            C:\Celerium.DattoBCDR\MyConfig.psd1

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Import-DattoBCDRModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Set')]
    Param (
        [Parameter(ParameterSetName = 'Set')]
        [string]$DattoBCDRConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"Celerium.DattoBCDR"}else{".Celerium.DattoBCDR"}) ),

        [Parameter(ParameterSetName = 'Set')]
        [string]$DattoBCDRConfFile = 'config.psd1'
    )

    begin {
        $DattoBCDRConfig = Join-Path -Path $DattoBCDRConfPath -ChildPath $DattoBCDRConfFile

        $ModuleVersion = $MyInvocation.MyCommand.Version.ToString()

        switch ($PSVersionTable.PSEdition){
            'Core'      { $UserAgent = "Celerium.DattoBCDR/$ModuleVersion - PowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.Platform) $($PSVersionTable.OS))" }
            'Desktop'   { $UserAgent = "Celerium.DattoBCDR/$ModuleVersion - WindowsPowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.BuildVersion))" }
            default     { $UserAgent = "Celerium.DattoBCDR/$ModuleVersion - $([Microsoft.PowerShell.Commands.PSUserAgent].GetMembers('Static, NonPublic').Where{$_.Name -eq 'UserAgent'}.GetValue($null,$null))" }
        }

    }

    process {

        if ( Test-Path $DattoBCDRConfig ) {
            $TempConfig = Import-LocalizedData -BaseDirectory $DattoBCDRConfPath -FileName $DattoBCDRConfFile

            # Send to function to strip potentially superfluous slash (/)
            Add-DattoBCDRBaseURI $TempConfig.DattoBCDRModuleBaseUri

            $TempConfig.DattoBCDRModuleApiSecretKey = ConvertTo-SecureString $TempConfig.DattoBCDRModuleApiSecretKey

            Set-Variable -Name "DattoBCDRModuleApiKey"              -Value $TempConfig.DattoBCDRModuleApiKey        -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleApiSecretKey"        -Value $TempConfig.DattoBCDRModuleApiSecretKey  -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleUserAgent"           -Value $TempConfig.DattoBCDRModuleUserAgent      -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleJSONConversionDepth" -Value $TempConfig.DattoBCDRModuleJSONConversionDepth -Option ReadOnly -Scope Global -Force

            Write-Verbose "Celerium.DattoBCDR Module configuration loaded successfully from [ $DattoBCDRConfig ]"

            # Clean things up
            Remove-Variable "TempConfig"
        }
        else {
            Write-Verbose "No configuration file found at [ $DattoBCDRConfig ] run Add-DattoBCDRAPIKey to get started."

            Add-DattoBCDRBaseURI

            Set-Variable -Name "DattoBCDRModuleUserAgent" -Value $UserAgent -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleBaseUri" -Value $(Get-DattoBCDRBaseURI)  -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "DattoBCDRModuleJSONConversionDepth" -Value 100 -Scope Global -Force
        }

    }

    end {}

}
#EndRegion '.\Private\ModuleSettings\Import-DattoBCDRModuleSettings.ps1' 107
#Region '.\Private\ModuleSettings\Initialize-DattoBCDRModuleSettings.ps1' -1

#Used to auto load either baseline settings or saved configurations when the module is imported
Import-DattoBCDRModuleSettings -Verbose:$false
#EndRegion '.\Private\ModuleSettings\Initialize-DattoBCDRModuleSettings.ps1' 3
#Region '.\Private\ModuleSettings\Remove-DattoBCDRModuleSettings.ps1' -1

function Remove-DattoBCDRModuleSettings {
<#
    .SYNOPSIS
        Removes the stored Datto configuration folder

    .DESCRIPTION
        The Remove-DattoBCDRModuleSettings cmdlet removes the Datto folder and its files
        This cmdlet also has the option to remove sensitive Datto variables as well

        By default configuration files are stored in the following location and will be removed:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER DattoBCDRConfPath
        Define the location of the Datto configuration folder

        By default the configuration folder is located at:
            $env:USERPROFILE\Celerium.DattoBCDR

    .PARAMETER AndVariables
        Define if sensitive Datto variables should be removed as well

        By default the variables are not removed

    .EXAMPLE
        Remove-DattoBCDRModuleSettings

        Checks to see if the default configuration folder exists and removes it if it does

        The default location of the Datto configuration folder is:
            $env:USERPROFILE\Celerium.DattoBCDR

    .EXAMPLE
        Remove-DattoBCDRModuleSettings -DattoBCDRConfPath C:\Celerium.DattoBCDR -AndVariables

        Checks to see if the defined configuration folder exists and removes it if it does
        If sensitive Datto variables exist then they are removed as well

        The location of the Datto configuration folder in this example is:
            C:\Celerium.DattoBCDR

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Internal/Remove-DattoBCDRModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy',SupportsShouldProcess, ConfirmImpact = 'None')]
    Param (
        [Parameter(ParameterSetName = 'Set')]
        [string]$DattoBCDRConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"Celerium.DattoBCDR"}else{".Celerium.DattoBCDR"}) ),

        [Parameter(ParameterSetName = 'Set')]
        [switch]$AndVariables
    )

    begin {}

    process {

        if (Test-Path $DattoBCDRConfPath) {

            Remove-Item -Path $DattoBCDRConfPath -Recurse -Force -WhatIf:$WhatIfPreference

            If ($AndVariables) {
                Remove-DattoBCDRAPIKey
                Remove-DattoBCDRBaseURI
            }

            if (!(Test-Path $DattoBCDRConfPath)) {
                Write-Output "The Celerium.DattoBCDR configuration folder has been removed successfully from [ $DattoBCDRConfPath ]"
            }
            else {
                Write-Error "The Celerium.DattoBCDR configuration folder could not be removed from [ $DattoBCDRConfPath ]"
            }

        }
        else {
            Write-Warning "No configuration folder found at [ $DattoBCDRConfPath ]"
        }

    }

    end {}

}
#EndRegion '.\Private\ModuleSettings\Remove-DattoBCDRModuleSettings.ps1' 87
#Region '.\Public\BCDR\Get-DattoBCDRAgent.ps1' -1

function Get-DattoBCDRAgent {
<#
    .SYNOPSIS
        Get Datto BCDR agents from a given device

    .DESCRIPTION
        The Get-DattoBCDRAgent cmdlet get agents from a defined
        BCDR device or for Endpoint Backup for PC agents (EB4PC)

        To get agents from the Datto BCDR the SerialNumber of the BCDR
        needs to be defined

    .PARAMETER SerialNumber
        BCDR serial number to get agents from

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRAgent

        Gets a list of Endpoint Backup for PC (EB4PC) clients and the agents
        under those clients

    .EXAMPLE
        Get-DattoBCDRAgent -SerialNumber "12345678"

        Returns the agents from the defined Datto BCDR

    .EXAMPLE
        Get-DattoBCDRAgent -SerialNumber "12345678" -Page 2 -PerPage 10

        Returns the first 10 agents from Page 2 from the defined Datto BCDR

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRAgent.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IndexByDevice')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'IndexByDevice')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'IndexByDevice')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false)]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        switch ( [bool]$SerialNumber ) {
            $true   { $ResourceUri = "/bcdr/device/$SerialNumber/asset/agent" }
            $false  { $ResourceUri = "/bcdr/agent" }
        }

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -like 'Index*') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRAgent.ps1' 109
#Region '.\Public\BCDR\Get-DattoBCDRAlert.ps1' -1

function Get-DattoBCDRAlert {
<#
    .SYNOPSIS
        Gets Datto BCDR alerts for a given device

    .DESCRIPTION
        The Get-DattoBCDRAlert cmdlet gets Datto BCDR alerts for a given device

    .PARAMETER SerialNumber
        BCDR serial number to return data for

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRAlert -SerialNumber "12345678"

        Gets the Datto BCDR with the defined SerialNumber and returns any alerts

    .EXAMPLE
        Get-DattoBCDRAlert -SerialNumber "12345678" -Page 2 -PageSize 10

        Gets the Datto BCDR with the defined SerialNumber
        with the first 10 alerts from the 2nd Page of results

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRAlert.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/bcdr/device/$SerialNumber/alert"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -like 'Index*') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRAlert.ps1' 95
#Region '.\Public\BCDR\Get-DattoBCDRAsset.ps1' -1

function Get-DattoBCDRAsset {
<#
    .SYNOPSIS
        Get Datto BCDR assets (agents and shares) for a given device

    .DESCRIPTION
        The Get-DattoBCDRAsset cmdlet gets Datto BCDR assets
        (agents and shares) for a given device

    .PARAMETER SerialNumber
        BCDR serial number to return data for

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRAsset -SerialNumber "12345678"

        Gets the Datto BCDR with the defined SerialNumber and
        returns any agents or shares

    .EXAMPLE
        Get-DattoBCDRAsset -SerialNumber "12345678" -Page 2 -PageSize 10

        Gets the Datto BCDR with the defined SerialNumber and returns
        the first 10 agents or shares from the 2nd Page of results

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRAsset.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/bcdr/device/$SerialNumber/asset"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -like 'Index*') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRAsset.ps1' 97
#Region '.\Public\BCDR\Get-DattoBCDRDevice.ps1' -1

function Get-DattoBCDRDevice {
<#
    .SYNOPSIS
        Gets Datto BCDR devices from the the Datto API

    .DESCRIPTION
        The Get-DattoBCDRDevice cmdlet gets can get a one or more
        Datto BCDR devices

    .PARAMETER SerialNumber
        BCDR serial number to return data for

        The parameter is mandatory if you want to get a specific device

    .PARAMETER ShowHiddenDevices
        Whether hidden devices should be included in your results

        Acceptable values are:
            '0', '1'

        By default '1' is returned by the API which shows hidden devices

    .PARAMETER ShowChildResellerDevices
        Whether child reseller devices should be included in your results

        Acceptable values are:
            '0', '1'

        By default '1' is returned by the API which shows child reseller devices

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRDevice

        Gets BCDR devices with any hidden or child reseller devices

    .EXAMPLE
        Get-DattoBCDRDevice -ShowHiddenDevices 0 -ShowChildResellerDevices 0

        Gets BCDR devices without any hidden or child reseller devices

    .EXAMPLE
        Get-DattoBCDRDevice -Page 2 -PageSize 10

        Gets the first 10 Datto BCDR devices from the second Page
        Hidden and child reseller devices will be included

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRDevice.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IndexByDevice')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateSet('0','1')]
        [string]$ShowHiddenDevices,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateSet('0','1')]
        [string]$ShowChildResellerDevices,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        switch ( [bool]$SerialNumber ) {
            $true   { $ResourceUri = "/bcdr/device/$SerialNumber" }
            $false  { $ResourceUri = "/bcdr/device" }
        }

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($Page)                      { $UriParameters['_page']                       = $Page }
            if ($PerPage)                   { $UriParameters['_perPage']                    = $PerPage }
            if ($ShowHiddenDevices)         { $UriParameters['showHiddenDevices']           = $ShowHiddenDevices }
            if ($ShowChildResellerDevices)  { $UriParameters['showChildResellerDevices']    = $ShowChildResellerDevices }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRDevice.ps1' 132
#Region '.\Public\BCDR\Get-DattoBCDRShare.ps1' -1

function Get-DattoBCDRShare {
<#
    .SYNOPSIS
        Gets Datto BCDR shares for a given device

    .DESCRIPTION
        The Get-DattoBCDRShare cmdlet gets Datto BCDR shares
        for a given device

    .PARAMETER SerialNumber
        BCDR serial number to return data for

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRShare -SerialNumber "12345678"

        Gets the Datto BCDR with the defined SerialNumber
        and returns any shares

    .EXAMPLE
        Get-DattoBCDRShare -SerialNumber "12345678" -Page 2 -PageSize 10

        Gets the Datto BCDR with the defined SerialNumber
        with the first 10 shares from the 2nd Page of results

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRShare.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/bcdr/device/$SerialNumber/asset/share"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRShare.ps1' 97
#Region '.\Public\BCDR\Get-DattoBCDRVMRestore.ps1' -1

function Get-DattoBCDRVMRestore {
<#
    .SYNOPSIS
        Gets Datto BCDR VM restores by serial number

    .DESCRIPTION
        The Get-DattoBCDRVMRestore cmdlet gets device VM restores
        by serial number

    .PARAMETER SerialNumber
        BCDR serial number to return data for

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRVMRestore -SerialNumber 12345

        Gest Datto VM restores from the defined device

    .EXAMPLE
        Get-DattoBCDRVMRestore -SerialNumber "12345678" -Page 2 -PerPage 10

        Gets the Datto BCDR VM restores with the defined SerialNumber
        with the first 10 restores from the 2nd Page of results

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRVMRestore.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/bcdr/device/$SerialNumber/vm-restores"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRVMRestore.ps1' 96
#Region '.\Public\BCDR\Get-DattoBCDRVolume.ps1' -1

function Get-DattoBCDRVolume {
<#
    .SYNOPSIS
        Gets an asset(s)(agent or share) for a specific
        volume on a device

    .DESCRIPTION
        The Get-DattoBCDRVolume cmdlet gets an asset(s)(agent or share)
        for a specific volume on a device

    .PARAMETER SerialNumber
        BCDR serial number to return data for

    .PARAMETER VolumeName
        Volume name (id) of the protected volume

        The content of the 'volume' field when calling
        /v1/bcdr/device/{SerialNumber}/asset

    .EXAMPLE
        Get-DattoBCDRVolume -SerialNumber "12345678" -VolumeName "0987654321"

        Gets the Datto BCDR with the defined SerialNumber and returns any
        agents or shares for the defined volume

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/BCDR/Get-DattoBCDRVolume.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$VolumeName
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/bcdr/device/$SerialNumber/asset/$VolumeName"

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri

    }

    end {}

}
#EndRegion '.\Public\BCDR\Get-DattoBCDRVolume.ps1' 66
#Region '.\Public\DTC\Get-DattoBCDRDTCAsset.ps1' -1

function Get-DattoBCDRDTCAsset {
<#
    .SYNOPSIS
        Get details for direct-to-cloud assets

    .DESCRIPTION
        The Get-DattoBCDRDTCAsset cmdlet get details for
        direct-to-cloud assets

    .PARAMETER ClientID
        ClientID for the direct-to-cloud assets

        Can be found in the organizationId

    .PARAMETER AssetsOnly
        When defined with ClientID this filters the results returned
        from the /dtc/assets endpoint

        When not defined with ClientID assets are returned from the
        /dtc/{clientId}/assets endpoint

    .PARAMETER AssetUUID
        AssetUUID for the direct-to-cloud assets

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRDTCAsset

        Gets details for direct-to-cloud assets

    .EXAMPLE
        Get-DattoBCDRDTCAsset -ClientID 123456 -AssetsOnly

        Filters results for direct-to-cloud assets for a specific client

    .EXAMPLE
        Get-DattoBCDRDTCAsset -ClientID 123456

        Gets details for direct-to-cloud assets for a specific client

    .EXAMPLE
        Get-DattoBCDRDTCAsset -ClientID 12345 -AssetUUID "123e4567-e89b-12d3-a456-426614174000"

        Gets details for a specific direct-to-cloud asset

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/DTC/Get-DattoBCDRDTCAsset.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IndexByAsset')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IndexByUUID')]
        [ValidateNotNullOrEmpty()]
        [int]$ClientID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IndexByUUID')]
        [ValidateNotNullOrEmpty()]
        [string]$AssetUUID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AssetsOnly,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'IndexByAsset')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'IndexByAsset')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'IndexByAsset')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        switch ($PSCmdlet.ParameterSetName) {
            'Index'         { $ResourceUri = "/dtc/assets" }
            'IndexByAsset'  { $ResourceUri = "/dtc/$ClientID/assets" }
            'IndexByUUID'   { $ResourceUri = "/dtc/$ClientID/assets/$AssetUUID" }
        }

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($ClientID)  { $UriParameters['clientId']    = $ClientID }
        }

        if ($PSCmdlet.ParameterSetName -ne 'IndexByUUID') {
            if ($Page)      { $UriParameters['_page']       = $Page }
            if ($PerPage)   { $UriParameters['_perPage']    = $PerPage }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}

}
#EndRegion '.\Public\DTC\Get-DattoBCDRDTCAsset.ps1' 137
#Region '.\Public\DTC\Get-DattoBCDRDTCRMMTemplate.ps1' -1

function Get-DattoBCDRDTCRMMTemplate {
<#
    .SYNOPSIS
        Get RMM templates

    .DESCRIPTION
        The Get-DattoBCDRDTCRMMTemplate cmdlet gets RMM templates
        for direct-to-cloud assets

    .PARAMETER ClientID
        ClientID for the direct-to-cloud assets

        Can be found in the organizationId

    .EXAMPLE
        Get-DattoBCDRDTCRMMTemplate

        Gets RMM templates for all direct-to-cloud assets

    .EXAMPLE
        Get-DattoBCDRDTCRMMTemplate -ClientID 123456

        Gets RMM templates for the defined direct-to-cloud assets

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/DTC/Get-DattoBCDRDTCRMMTemplate.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [int]$ClientID
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/dtc/rmm-templates"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($ClientID)  { $UriParameters['clientId']    = $ClientID }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}

}
#EndRegion '.\Public\DTC\Get-DattoBCDRDTCRMMTemplate.ps1' 71
#Region '.\Public\DTC\Get-DattoBCDRDTCStoragePool.ps1' -1

function Get-DattoBCDRDTCStoragePool {
<#
    .SYNOPSIS
        Gets storage pool usage

    .DESCRIPTION
        The Get-DattoBCDRDTCStoragePool cmdlet gets storage pool usage
        for direct-to-cloud assets

    .EXAMPLE
        Get-DattoBCDRDTCStoragePool

        Gets storage pool usage for all direct-to-cloud assets

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/DTC/Get-DattoBCDRDTCStoragePool.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param ()

    begin {

        $FunctionName       = $MyInvocation.InvocationName

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/dtc/storage-pool"

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri

    }

    end {}

}
#EndRegion '.\Public\DTC\Get-DattoBCDRDTCStoragePool.ps1' 44
#Region '.\Public\DTC\Set-DattoBCDRDTCBandwidth.ps1' -1

function Set-DattoBCDRDTCBandwidth {
<#
    .SYNOPSIS
        Updates the bandwidth settings for a single direct-to-cloud agent

    .DESCRIPTION
        The Set-DattoBCDRDTCBandwidth cmdlet updates the bandwidth
        settings for a single direct-to-cloud agent

    .PARAMETER AgentUUID
        UUID

    .PARAMETER PauseWhileMetered
        Pause the agent while on a metered connection

    .PARAMETER MaximumBandwidthInBits
        Maximum bandwidth in bits for the agent

    .PARAMETER MaximumThrottledBandwidthInBits
        Maximum throttled bandwidth in bits for the agent

    .EXAMPLE
        Set-DattoBCDRDTCBandwidth -AgentUUID "123e4567-e89b-12d3-a456-426614174000" -maximumBandwidthInBits 1000000 -MaximumThrottledBandwidthInBits 500000

        Updates the bandwidth settings for the defined single direct-to-cloud agent

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/DTC/Set-DattoBCDRDTCBandwidth.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Set', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateNotNullOrEmpty()]
        [string]$AgentUUID,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [switch]$PauseWhileMetered,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateRange(1, [int64]::MaxValue)]
        [int64]$MaximumBandwidthInBits,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateRange(1, [int64]::MaxValue)]
        [int64]$MaximumThrottledBandwidthInBits
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/dtc/agent/$AgentUUID/bandwidth"

        $Data = @{
            pauseWhileMetered               = $PauseWhileMetered
            maximumBandwidthInBits          = $MaximumBandwidthInBits
            maximumThrottledBandwidthInBits = $MaximumThrottledBandwidthInBits
        }

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess("AgentUUID: [ $AgentUUID ]", "Update Bandwidth Settings")) {
            Invoke-DattoBCDRRequest -Method PUT -ResourceUri $ResourceUri -Data $Data
        }

    }

    end {}
}
#EndRegion '.\Public\DTC\Set-DattoBCDRDTCBandwidth.ps1' 83
#Region '.\Public\Reporting\Get-DattoBCDRActivityLog.ps1' -1

function Get-DattoBCDRActivityLog {
<#
    .SYNOPSIS
        Gets a filtered list of activity logs ordered by date

    .DESCRIPTION
        The Get-DattoBCDRActivityLog cmdlet gets a filtered
        list of activity logs ordered by date

    .PARAMETER ClientName
        Defines a client name with which to do a partial/prefix match

    .PARAMETER Since
        Defines the number of days (unless overridden with sinceUnits),
        up until now, for which to produce logs

    .PARAMETER SinceUnits
        Defines the units to use for the since filter

        Available values : days, hours, minutes

    .PARAMETER Target
        Defines a comma-separated array of targetType:targetId tuples

        Example: bcdr-device:DC1234DC1234

    .PARAMETER TargetType
        Defines the type of target for which to find activity logs

        Example: bcdr-device

    .PARAMETER User
        Defines a username with which to do a partial/prefix match

    .PARAMETER Page
        Page number to return

    .PARAMETER PerPage
        Amount of items to return with each Page

    .PARAMETER AllResults
        Returns all items from an endpoint

        This can be used in unison with -PerPage to limit the number of
        sequential requests to the API

    .EXAMPLE
        Get-DattoBCDRActivityLog

        Gets the Datto BCDR platform activity logs from the past day

    .EXAMPLE
        Get-DattoBCDRActivityLog -Since 7 -SinceUnits days

        Gets the Datto BCDR platform activity logs from the past 7 day

    .EXAMPLE
        Get-DattoBCDRActivityLog -User bob -Since 7 -SinceUnits days

        Gets the Datto BCDR platform activity logs for the user
        named bob from the past 7 day

    .EXAMPLE
        Get-DattoBCDRActivityLog -Since 30 -SinceUnits days -Target 'bcdr-device:D0123456789','bcdr-device:D9876543210'

        Gets the Datto BCDR platform activity logs from the defined
        targets for the past 30 day

    .EXAMPLE
        Get-DattoBCDRActivityLog -Since 30 -SinceUnits days -Page 2 -PageSize 10

        Gets the Datto BCDR platform activity logs from the past 30 day

        Returns the second Page of 10 items

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/Reporting/Get-DattoBCDRActivityLog.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$ClientName,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Since,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [validateSet('days', 'hours', 'minutes')]
        [string]$SinceUnits,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [string[]]$Target,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$TargetType,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [string]$User,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PerPage,

        [Parameter( Mandatory = $false, ParameterSetName = 'Index')]
        [switch]$AllResults
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/report/activity-log"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($ClientName)    { $UriParameters['clientName']  = $ClientName }
            if ($Page)          { $UriParameters['_page']       = $Page }
            if ($PerPage)       { $UriParameters['_perPage']    = $PerPage }
            if ($Since)         { $UriParameters['since']       = $Since }
            if ($SinceUnits)    { $UriParameters['sinceUnits']  = $SinceUnits }
            if ($Target)        { $UriParameters['target']      = $Target }
            if ($TargetType)    { $UriParameters['targetType']  = $TargetType }
            if ($User)          { $UriParameters['user']        = $User }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters -AllResults:$AllResults

    }

    end {}

}
#EndRegion '.\Public\Reporting\Get-DattoBCDRActivityLog.ps1' 161
#Region '.\Public\SaaS\Get-DattoBCDRSaaSApplication.ps1' -1

function Get-DattoBCDRSaaSApplication {
<#
    .SYNOPSIS
        Get Datto SaaS protection backup data for a given customer

    .DESCRIPTION
        The Get-DattoBCDRApplication cmdlet gets Datto SaaS protection
        backup data for a given customer

    .PARAMETER SaasCustomerId
        ID of the Datto SaaS organization

    .PARAMETER DaysUntil
        The number of days until the report should be generated

    .EXAMPLE
        Get-DattoBCDRApplication -SaasCustomerId "123456"

        Gets the Datto SaaS protection backup data from the define customer ID and
        does not include remote IDs

    .EXAMPLE
        Get-DattoBCDRApplication -SaasCustomerId "123456" -DaysUntil 30

        Gets the Datto SaaS protection backup data from the define customer ID and
        includes reports that will generated in the next 30 days

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSApplication.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [int]$SaasCustomerId,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$DaysUntil
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/saas/$SaasCustomerId/applications"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($DaysUntil) { $UriParameters['daysUntil'] = $DaysUntil }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}
}
#EndRegion '.\Public\SaaS\Get-DattoBCDRSaaSApplication.ps1' 79
#Region '.\Public\SaaS\Get-DattoBCDRSaaSBackupStats.ps1' -1

function Get-DattoBCDRSaaSBackupStats {
<#
    .SYNOPSIS
        Gets detailed Saas backup data

    .DESCRIPTION
        The Get-DattoBCDRBackupStats cmdlet gets detailed Saas
        backup data for a given customer

    .PARAMETER SaasCustomerId
        ID of the Datto SaaS organization

    .EXAMPLE
        Get-DattoBCDRBackupStats -SaasCustomerId "123456"

        Gets detailed Saas backup data for the defined customer

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSBackupStats.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [int]$SaasCustomerId
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/saas/$SaasCustomerId/detailedBackupStats"

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri

    }

    end {}
}
#EndRegion '.\Public\SaaS\Get-DattoBCDRSaaSBackupStats.ps1' 55
#Region '.\Public\SaaS\Get-DattoBCDRSaaSDomain.ps1' -1

function Get-DattoBCDRSaaSDomain {
<#
    .SYNOPSIS
        Get Datto SaaS protection data about what
        domains are being protected

    .DESCRIPTION
        The Get-DattoBCDRDomain cmdlet gets SaaS protection data
        about what domains are being protected

    .EXAMPLE
        Get-DattoBCDRDomain

        Gets SaaS protection data about what domains are being protected

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSDomain.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param ()

    begin {

        $FunctionName       = $MyInvocation.InvocationName

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/saas/domains"

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}

}
#EndRegion '.\Public\SaaS\Get-DattoBCDRSaaSDomain.ps1' 45
#Region '.\Public\SaaS\Get-DattoBCDRSaaSSeat.ps1' -1

function Get-DattoBCDRSaaSSeat {
<#
    .SYNOPSIS
        Get Datto SaaS protection seats for a given customer

    .DESCRIPTION
        The Get-DattoBCDRSeat cmdlet gets Datto SaaS protection seats
        for a given customer

    .PARAMETER SaasCustomerId
        Defines the id of the Datto SaaS organization

    .PARAMETER SeatType
        Type of seat to return

        Allowed values:
        'User', 'Site', 'TeamSite', 'SharedMailbox', 'Team', 'SharedDrive'

    .EXAMPLE
        Get-DattoBCDRSeat -SaasCustomerId "123456"

        Gets the Datto SaaS protection seats from the define customer id

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSSeat.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [int]$SaasCustomerId,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [ValidateSet( 'User', 'SharedMailbox', 'SharedDrive', 'Site', 'TeamSite', 'Team', IgnoreCase = $False)]
        [string]$SeatType
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/saas/$SaasCustomerId/seats"

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        if ($PSCmdlet.ParameterSetName -eq 'Index') {
            if ($SeatType) { $UriParameters['seatType'] = $SeatType }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}
}
#EndRegion '.\Public\SaaS\Get-DattoBCDRSaaSSeat.ps1' 75
#Region '.\Public\SaaS\Set-DattoBCDRSaaSBulkSeatChange.ps1' -1

function Set-DattoBCDRSaaSBulkSeatChange {
<#
    .SYNOPSIS
        Sets Datto SaaS Protection bulk seat changes

    .DESCRIPTION
        The Set-DattoBCDRBulkSeatChange cmdlet is used to bulk set SaaS
        Protection seat changes

    .PARAMETER SaasCustomerId
        ID of the Datto SaaS organization

    .PARAMETER ExternalSubscriptionId
        Defines the external Subscription ID used to set SaaS bulk seat changes

        The ExternalSubscriptionId can be found by referencing
        the data returned from Get-DattoBCDRApplication

        Example:
            'Classic:Office365:654321'
            'Classic:GoogleApps:654321'

    .PARAMETER SeatType
        Defines the seat type to backup

        This is a case-sensitive value

        Seat Types can be found by referencing the data returned from Get-DattoBCDRSeat

        Example:
            Office365: 'User', 'SharedMailbox', 'Site', 'TeamSite', 'Team'
            Google:    'User', 'SharedDrive'

    .PARAMETER ActionType
        Defines what action to take against the seat

        This is a case-sensitive value

        Active (License):           The seat exists in the organization and is actively backed up, meaning the seat is protected
        Paused (Pause):             The seat exists in the organization; backups were enabled but are currently paused
        Unprotected (Unlicense):    The seat exists in the organization but backups are not enabled

        Allowed values:
            'License', 'Pause', 'Unlicense'

    .PARAMETER RemoteId
        Defines the comma separated target IDs to change

        Remote IDs can be found by referencing the data returned from Get-DattoApplication

        Example:
            ab23-bdf234-1234-asdf

    .EXAMPLE
        Set-DattoBCDRBulkSeatChange -SaasCustomerId "123456" -ExternalSubscriptionId 'Classic:Office365:654321' -SeatType "User" -ActionType License -RemoteId "ab23-bdf234-1234-asdf"

        Sets the Datto SaaS protection seats from the defined Office365 customer ID

    .EXAMPLE
        Set-DattoBCDRBulkSeatChange -SaasCustomerId "123456" -ExternalSubscriptionId 'Classic:GoogleApps:654321' -SeatType "SharedDrive" -ActionType Pause -RemoteId "ab23-bdf234-1234-asdf"

        Sets the Datto SaaS protection seats from the defined Google customer ID

    .NOTES
        The bulkSeatChange API endpoint can be used for Seat Management 2.0 only. You cannot change seat status
        in Seat Management 1.0, but you can add SaaS Protection to seats as described in Exploring Seat Management features.

        https://saasprotection.datto.com/help/M365/Content/Other_Administrative_Tasks/using-rest-api-saas-protection.htm?Highlight=api
        https://saasprotection.datto.com/help/Google/Content/Other_Administrative_Tasks/using-rest-api-saasP-GW.htm?Highlight=seats

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Set-DattoBCDRSaaSBulkSeatChange.html

#>

    [CmdletBinding(DefaultParameterSetName = 'Set', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateNotNullOrEmpty()]
        [int]$SaasCustomerId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateNotNullOrEmpty()]
        [string]$ExternalSubscriptionId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateSet( 'User', 'SharedMailbox', 'SharedDrive', 'Site', 'TeamSite', 'Team', IgnoreCase = $false)]
        [string]$SeatType,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [ValidateSet('License', 'Pause', 'Unlicense', IgnoreCase = $false)]
        [string]$ActionType,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'Set')]
        [ValidateNotNullOrEmpty()]
        [string[]]$RemoteId
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceUri = "/saas/$SaasCustomerId/$ExternalSubscriptionId/bulkSeatChange"

        $Data = @{
            seat_type   = $SeatType
            action_type = $ActionType
            ids         = $RemoteId
        }

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess("SaasCustomerId: [ $SaasCustomerId ], ExternalSubscriptionId: [ $ExternalSubscriptionId, $remoteId ]", "ActionType: [ $ActionType $SeatType ]")) {
            Invoke-DattoBCDRRequest -Method PUT -ResourceUri $ResourceUri -Data $Data
        }

    }

    end {}
}
#EndRegion '.\Public\SaaS\Set-DattoBCDRSaaSBulkSeatChange.ps1' 130
