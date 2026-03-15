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
