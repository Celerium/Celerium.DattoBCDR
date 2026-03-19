<#
    .SYNOPSIS
        Pester tests for the Celerium.DattoBCDR Get-DattoBCDRSaaSSeat function

    .DESCRIPTION
        Pester tests for the Celerium.DattoBCDR Get-DattoBCDRSaaSSeat function

    .PARAMETER moduleName
        The name of the local module to import

    .PARAMETER Version
        The version of the local module to import

    .PARAMETER buildTarget
        Which version of the module to run tests against

        Allowed values:
            'built', 'notBuilt'

    .EXAMPLE
        Invoke-Pester -Path .\Tests\Public\SaaS\Get-DattoBCDRSaaSSeat.Tests.ps1

        Runs a pester test and outputs simple results

    .EXAMPLE
        Invoke-Pester -Path .\Tests\Public\SaaS\Get-DattoBCDRSaaSSeat.Tests.ps1 -Output Detailed

        Runs a pester test and outputs detailed results

    .INPUTS
        N\A

    .OUTPUTS
        N\A

    .NOTES
        N\A

    .LINK
        https://celerium.org

#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.5.0' }

#Region     [ Parameters ]

#Available in Discovery & Run
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$moduleName = 'Celerium.DattoBCDR',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$version,

    [Parameter(Mandatory=$true)]
    [ValidateSet('built','notBuilt')]
    [string]$buildTarget
)

#EndRegion  [ Parameters ]

#Region     [ Prerequisites ]

#Available inside It but NOT Describe or Context
    BeforeAll {

        if ($IsWindows -or $PSEdition -eq 'Desktop') {
            $rootPath = "$( $PSCommandPath.Substring(0, $PSCommandPath.IndexOf('\tests', [System.StringComparison]::OrdinalIgnoreCase)) )"
        }
        else{
            $rootPath = "$( $PSCommandPath.Substring(0, $PSCommandPath.IndexOf('/tests', [System.StringComparison]::OrdinalIgnoreCase)) )"
        }

        switch ($buildTarget){
            'built'     { $modulePath = Join-Path -Path $rootPath -ChildPath "\build\$moduleName\$version" }
            'notBuilt'  { $modulePath = Join-Path -Path $rootPath -ChildPath "$moduleName" }
        }

        if (Get-Module -Name $moduleName){
            Remove-Module -Name $moduleName -Force
        }

        $modulePsd1 = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

        Import-Module -Name $modulePsd1 -ErrorAction Stop -ErrorVariable moduleError *> $null

        if ($moduleError){
            $moduleError
            exit 1
        }

    }

    AfterAll{

        Remove-DattoBCDRAPIKey -WarningAction SilentlyContinue

        if (Get-Module -Name $moduleName){
            Remove-Module -Name $moduleName -Force
        }

    }

#Available in Describe and Context but NOT It
#Can be used in [ It ] with [ -TestCases @{ VariableName = $VariableName } ]
    BeforeDiscovery{

        $pester_TestName = (Get-Item -Path $PSCommandPath).Name
        $commandName = $pester_TestName -replace '.Tests.ps1',''

    }

#EndRegion  [ Prerequisites ]

Describe "Testing the [ $buildTarget ] version of [ $commandName ] function with [ $pester_TestName ]" -Tag @('SaaS','PublicFunctions') {

    Context "[ $commandName ] testing function" {

        BeforeEach {
            Add-DattoBCDRAPIKey -ApiKeyPublic '12345' -ApiKeySecret "Celerium.DattoBCDRAPIKey"
            Mock 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -MockWith {
                @{}
            }
        }

        It "[ -SaasCustomerId ] parameter is mandatory" {
            $isMandatory = (Get-Command -Name 'Get-DattoBCDRSaaSSeat').Parameters['SaasCustomerId'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory
            $isMandatory | Should -BeTrue
        }

        It "[ -SaasCustomerId ] accepts value from pipeline" {
            {123456 | Get-DattoBCDRSaaSSeat} | Should -Not -Throw
        }

        It "[ -SeatType ] parameter is optional" {
            {Get-DattoBCDRSaaSSeat -SaasCustomerId 123456} | Should -Not -Throw
        }

        It "[ -SeatType ] rejects invalid seat type values" {
            {Get-DattoBCDRSaaSSeat -SaasCustomerId 123456 -SeatType 'InvalidType'} | Should -Throw
        }

        It "[ -SeatType ] is case-sensitive" {
            {Get-DattoBCDRSaaSSeat -SaasCustomerId 123456 -SeatType 'user'} | Should -Throw
        }

        It "Generates correct ResourceUri with SaasCustomerId" {
            Get-DattoBCDRSaaSSeat -SaasCustomerId 123456

            Should -Invoke 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $ResourceUri -eq '/saas/123456/seats'
            }
        }

        It "Calls Invoke-DattoBCDRRequest with GET method" {
            Get-DattoBCDRSaaSSeat -SaasCustomerId 123456

            Should -Invoke 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It "Passes single SeatType value in UriFilter" {
            Get-DattoBCDRSaaSSeat -SaasCustomerId 123456 -SeatType 'User'

            Should -Invoke 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $UriFilter['seatType'] -eq 'User'
            }
        }

        It "Joins array of SeatTypes into comma-separated string in UriFilter" {
            Get-DattoBCDRSaaSSeat -SaasCustomerId 123456 -SeatType @('User', 'SharedMailbox')

            Should -Invoke 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $UriFilter['seatType'] -eq 'User,SharedMailbox'
            }
        }

        It "Does not include seatType in UriFilter when SeatType is not specified" {
            Get-DattoBCDRSaaSSeat -SaasCustomerId 123456

            Should -Invoke 'Invoke-DattoBCDRRequest' -ModuleName $moduleName -Times 1 -ParameterFilter {
                -not $UriFilter.ContainsKey('seatType')
            }
        }

    }

}
