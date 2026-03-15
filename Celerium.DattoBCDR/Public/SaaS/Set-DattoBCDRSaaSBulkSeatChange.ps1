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