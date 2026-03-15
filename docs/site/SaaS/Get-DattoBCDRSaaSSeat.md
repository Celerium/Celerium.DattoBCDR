---
external help file: Celerium.DattoBCDR-help.xml
grand_parent: SaaS
Module Name: Celerium.DattoBCDR
online version: https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSSeat.html
parent: GET
schema: 2.0.0
title: Get-DattoBCDRSaaSSeat
---

# Get-DattoBCDRSaaSSeat

## SYNOPSIS
Get Datto SaaS protection seats for a given customer

## SYNTAX

```powershell
Get-DattoBCDRSaaSSeat -SaasCustomerId <Int32> [-SeatType <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-DattoBCDRSeat cmdlet gets Datto SaaS protection seats
for a given customer

## EXAMPLES

### EXAMPLE 1
```powershell
Get-DattoBCDRSeat -SaasCustomerId "123456"
```

Gets the Datto SaaS protection seats from the define customer id

## PARAMETERS

### -SaasCustomerId
Defines the id of the Datto SaaS organization

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

### -SeatType
Type of seat to return

Allowed values:
'User', 'Site', 'TeamSite', 'SharedMailbox', 'Team', 'SharedDrive'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

[https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSSeat.html](https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Get-DattoBCDRSaaSSeat.html)

