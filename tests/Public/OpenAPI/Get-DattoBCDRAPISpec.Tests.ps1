<#
    .SYNOPSIS
        Pester tests for the Celerium.DattoBCDR OpenAPI functions

    .DESCRIPTION
        Pester tests for the Celerium.DattoBCDR OpenAPI functions

    .PARAMETER moduleName
        The name of the local module to import

    .PARAMETER Version
        The version of the local module to import

    .PARAMETER buildTarget
        Which version of the module to run tests against

        Allowed values:
            'built', 'notBuilt'

    .EXAMPLE
        Invoke-Pester -Path .\Tests\Public\OpenAPI\Get-DattoBCDRAPISpec.Tests.ps1

        Runs a pester test and outputs simple results

    .EXAMPLE
        Invoke-Pester -Path .\Tests\Public\OpenAPI\Get-DattoBCDRAPISpec.Tests.ps1 -Output Detailed

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

        $commandName = 'Get-DattoBCDRAPISpec'

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

        Add-DattoBCDRBaseURI

    }

    AfterAll{

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

Describe "Testing [ $commandName ] function with [ $pester_TestName ]" -Tag @('OpenAPI','Public') {

    Context "[ $commandName ] command metadata" {

        It "Should be available after module import" {
            Get-Command -Name $commandName -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It "Should expose the expected aliases" {
            $Aliases = (Get-Alias -Definition $commandName).Name

            $Aliases | Should -Contain 'Get-DattoBCDROpenAPI'
            $Aliases | Should -Contain 'Get-DattoBCDRSwagger'
        }

        It "Should expose the expected parameter sets" {
            $Command = Get-Command -Name $commandName

            $Command.DefaultParameterSet | Should -Be 'json'
            $Command.ParameterSets.Name | Should -Contain 'json'
            $Command.ParameterSets.Name | Should -Contain 'yml'
        }

        It "Should expose Raw only on the yml parameter set" {
            $Command = Get-Command -Name $commandName
            $JsonParameterSet = $Command.ParameterSets | Where-Object { $_.Name -eq 'json' }
            $YmlParameterSet = $Command.ParameterSets | Where-Object { $_.Name -eq 'yml' }

            $JsonParameterSet.Parameters.Name | Should -Not -Contain 'Raw'
            $YmlParameterSet.Parameters.Name | Should -Contain 'Raw'
        }

    }

    Context "[ $commandName ] live validation" {

        It "Default call should return OpenAPI data" -Tag 'Live' {
            $Value = & $commandName 3>$null
            $OpenApiVersion = if ($Value.PSObject.Properties.Name -contains 'items') { $Value.items.openapi } else { $Value.openapi }

            $Value | Should -Not -BeNullOrEmpty
            $OpenApiVersion | Should -Not -BeNullOrEmpty
            $OpenApiVersion | Should -Match '^3\.'
        }

        It "Raw call should return YAML data" -Tag 'Live' {
            $Value = & $commandName -Raw 3>$null
            $RawValue = if ($Value.PSObject.Properties.Name -contains 'items') { $Value.items } else { $Value }

            $Value | Should -Not -BeNullOrEmpty
            $RawValue | Should -Not -BeNullOrEmpty
            $RawValue | Should -BeOfType ([string])
            $RawValue | Should -Match 'openapi:\s*"?3\.'
        }

    }

}