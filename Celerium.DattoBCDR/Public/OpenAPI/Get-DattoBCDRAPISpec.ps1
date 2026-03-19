function Get-DattoBCDRAPISpec {
<#
    .SYNOPSIS
        Retrieves the OpenAPI (Swagger) specification for the Datto API.

    .DESCRIPTION
        The Get-DattoBCDRAPISpec cmdlet retrieves the OpenAPI (Swagger) specification
        for the Datto API. This specification provides a detailed description of
        the API endpoints, request and response formats, and other relevant
        information.

    .PARAMETER Raw
        If specified, retrieves the raw OpenAPI specification in YAML format.

    .EXAMPLE
        Get-DattoBCDRAPISpec

        Retrieves the OpenAPI specification in JSON format.

    .EXAMPLE
        Get-DattoBCDRAPISpec -Raw

        Retrieves the OpenAPI specification in raw YAML format.

    .NOTES
        Endpoint does not require authentication.

    .LINK
        https://celerium.github.io/Celerium.DattoBCDR/site/OpenAPI/Get-DattoBCDRAPISpec.html

#>
    [CmdletBinding(DefaultParameterSetName = 'json')]
    [Alias('Get-DattoBCDROpenAPI', 'Get-DattoBCDRSwagger')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'yml')]
        [Alias('yaml', 'yml')]
        [switch]$Raw
    )

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'
        $QueryParameterName = $functionName + '_ParametersQuery' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        switch ( [bool]$Raw ) {
            $true   { $ResourceUri = "/api/spec/raw" }
            $false  { $ResourceUri = "/api/spec" }
        }

        $UriParameters = @{}

        #Region     [ Parameter Translation ]

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}

}