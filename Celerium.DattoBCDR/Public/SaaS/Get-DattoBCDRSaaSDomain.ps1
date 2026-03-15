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
