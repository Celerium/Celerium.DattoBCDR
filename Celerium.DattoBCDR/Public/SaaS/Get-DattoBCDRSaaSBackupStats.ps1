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
