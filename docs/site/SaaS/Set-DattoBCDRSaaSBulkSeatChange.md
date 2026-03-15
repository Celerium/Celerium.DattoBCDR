---
external help file: Celerium.DattoBCDR-help.xml
grand_parent: SaaS
Module Name: Celerium.DattoBCDR
online version: https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Set-DattoBCDRSaaSBulkSeatChange.html
parent: PUT
schema: 2.0.0
title: Set-DattoBCDRSaaSBulkSeatChange
---

# Set-DattoBCDRSaaSBulkSeatChange

## SYNOPSIS
Sets Datto SaaS Protection bulk seat changes

## SYNTAX

```powershell
Set-DattoBCDRSaaSBulkSeatChange -SaasCustomerId <Int32> -ExternalSubscriptionId <String> -SeatType <String>
 -ActionType <String> -RemoteId <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-DattoBCDRBulkSeatChange cmdlet is used to bulk set SaaS
Protection seat changes

## EXAMPLES

### EXAMPLE 1
```powershell
Set-DattoBCDRBulkSeatChange -SaasCustomerId "123456" -ExternalSubscriptionId 'Classic:Office365:654321' -SeatType "User" -ActionType License -RemoteId "ab23-bdf234-1234-asdf"
```

Sets the Datto SaaS protection seats from the defined Office365 customer ID

### EXAMPLE 2
```powershell
Set-DattoBCDRBulkSeatChange -SaasCustomerId "123456" -ExternalSubscriptionId 'Classic:GoogleApps:654321' -SeatType "SharedDrive" -ActionType Pause -RemoteId "ab23-bdf234-1234-asdf"
```

Sets the Datto SaaS protection seats from the defined Google customer ID

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
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ExternalSubscriptionId
Defines the external Subscription ID used to set SaaS bulk seat changes

The ExternalSubscriptionId can be found by referencing
the data returned from Get-DattoBCDRApplication

Example:
    'Classic:Office365:654321'
    'Classic:GoogleApps:654321'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SeatType
Defines the seat type to backup

This is a case-sensitive value

Seat Types can be found by referencing the data returned from Get-DattoBCDRSeat

Example:
    Office365: 'User', 'SharedMailbox', 'Site', 'TeamSite', 'Team'
    Google:    'User', 'SharedDrive'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ActionType
Defines what action to take against the seat

This is a case-sensitive value

Active (License):           The seat exists in the organization and is actively backed up, meaning the seat is protected
Paused (Pause):             The seat exists in the organization; backups were enabled but are currently paused
Unprotected (Unlicense):    The seat exists in the organization but backups are not enabled

Allowed values:
    'License', 'Pause', 'Unlicense'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -RemoteId
Defines the comma separated target IDs to change

Remote IDs can be found by referencing the data returned from Get-DattoApplication

Example:
    ab23-bdf234-1234-asdf

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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
The bulkSeatChange API endpoint can be used for Seat Management 2.0 only.
You cannot change seat status
in Seat Management 1.0, but you can add SaaS Protection to seats as described in Exploring Seat Management features.

https://saasprotection.datto.com/help/M365/Content/Other_Administrative_Tasks/using-rest-api-saas-protection.htm?Highlight=api
https://saasprotection.datto.com/help/Google/Content/Other_Administrative_Tasks/using-rest-api-saasP-GW.htm?Highlight=seats

## RELATED LINKS

[https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Set-DattoBCDRSaaSBulkSeatChange.html](https://celerium.github.io/Celerium.DattoBCDR/site/SaaS/Set-DattoBCDRSaaSBulkSeatChange.html)

