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

        This is a case-sensitive value

        Allowed values:
        'User', 'Site', 'TeamSite', 'SharedMailbox', 'Team', 'SharedDrive'

    .EXAMPLE
        Get-DattoBCDRSeat -SaasCustomerId "123456"

        Gets the Datto SaaS protection seats from the define customer id

    .EXAMPLE
        Get-DattoSeat -saasCustomerId "123456" -seatType "User"
        Gets the Datto SaaS protection seats from the define customer id filtered to 'User' seats

    .EXAMPLE
        Get-DattoSeat -saasCustomerId "123456" -seatType "User", "SharedMailbox"
        Gets the Datto SaaS protection seats from the define customer id filtered to 'User' & 'SharedMailbox' seats

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
        [string[]]$SeatType
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
            if ($SeatType) { $UriParameters['seatType'] = $SeatType -join ',' }
        }

        #EndRegion  [ Parameter Translation ]

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false
        Set-Variable -Name $QueryParameterName -Value $UriParameters -Scope Global -Force -Confirm:$false

        Invoke-DattoBCDRRequest -Method GET -ResourceUri $ResourceUri -UriFilter $UriParameters

    }

    end {}
}
