---
external help file: Celerium.DattoBCDR-help.xml
grand_parent: SaaS
Module Name: Celerium.DattoBCDR
online version: https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSBackupStats.html
parent: GET
schema: 2.0.0
title: Get-DattoBCDRSaaSBackupStats
---

# Get-DattoBCDRSaaSBackupStats

## SYNOPSIS
Gets detailed Saas backup data

## SYNTAX

```powershell
Get-DattoBCDRSaaSBackupStats -SaasCustomerId <Int32> [<CommonParameters>]
```

## DESCRIPTION
The Get-DattoBCDRBackupStats cmdlet gets detailed Saas
backup data for a given customer

## EXAMPLES

### EXAMPLE 1
```powershell
Get-DattoBCDRBackupStats -SaasCustomerId "123456"
```

Gets detailed Saas backup data for the defined customer

## PARAMETERS

### -SaasCustomerId
ID of the Datto SaaS organization

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N\A

## RELATED LINKS

[https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSBackupStats.html](https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSBackupStats.html)

