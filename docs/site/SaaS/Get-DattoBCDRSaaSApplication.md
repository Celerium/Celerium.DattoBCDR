---
external help file: Celerium.DattoBCDR-help.xml
grand_parent: SaaS
Module Name: Celerium.DattoBCDR
online version: https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSApplication.html
parent: GET
schema: 2.0.0
title: Get-DattoBCDRSaaSApplication
---

# Get-DattoBCDRSaaSApplication

## SYNOPSIS
Get Datto SaaS protection backup data for a given customer

## SYNTAX

```powershell
Get-DattoBCDRSaaSApplication -SaasCustomerId <Int32> [-DaysUntil <Int32>] [<CommonParameters>]
```

## DESCRIPTION
The Get-DattoBCDRApplication cmdlet gets Datto SaaS protection
backup data for a given customer

## EXAMPLES

### EXAMPLE 1
```powershell
Get-DattoBCDRApplication -SaasCustomerId "123456"
```

Gets the Datto SaaS protection backup data from the define customer ID and
does not include remote IDs

### EXAMPLE 2
```powershell
Get-DattoBCDRApplication -SaasCustomerId "123456" -DaysUntil 30
```

Gets the Datto SaaS protection backup data from the define customer ID and
includes reports that will generated in the next 30 days

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

### -DaysUntil
The number of days until the report should be generated

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N\A

## RELATED LINKS

[https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSApplication.html](https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSApplication.html)

