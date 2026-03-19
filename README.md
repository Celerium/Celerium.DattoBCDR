<h1 align="center">
  <br>
  <a href="http://Celerium.org"><img src="https://raw.githubusercontent.com/Celerium/Celerium.DattoBCDR/refs/heads/main/.github/images/Celerium_PoSHGallery_DattoBCDR.png" width="200"></a>
  <br>
  Celerium.DattoBCDR
  <br>
</h1>

[![Az_Pipeline][Az_Pipeline-shield]][Az_Pipeline-url]
[![GitHub_Pages][GitHub_Pages-shield]][GitHub_Pages-url]

[![PoshGallery_Version][PoshGallery_Version-shield]][PoshGallery_Version-url]
[![PoshGallery_Platforms][PoshGallery_Platforms-shield]][PoshGallery_Platforms-url]
[![PoshGallery_Downloads][PoshGallery_Downloads-shield]][PoshGallery_Downloads-url]
[![codeSize][codeSize-shield]][codeSize-url]

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

[![Blog][Website-shield]][Website-url]
[![GitHub_License][GitHub_License-shield]][GitHub_License-url]

---

## Buy me a coffee

Whether you use this project, have learned something from it, or just like it, please consider supporting it by buying me a coffee, so I can dedicate more time on open-source projects like this :)

<a href="https://www.buymeacoffee.com/Celerium" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg" alt="Buy Me A Coffee" style="width:150px;height:50px;"></a>

---

<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://celerium.org">
    <img src="https://raw.githubusercontent.com/Celerium/Celerium.DattoBCDR/refs/heads/main/.github/images/Celerium_PoSHGitHub_DattoBCDR.png" alt="Logo">
  </a>

  <p align="center">
    <a href="https://www.powershellgallery.com/packages/Celerium.DattoBCDR" target="_blank">PowerShell Gallery</a>
    ·
    <a href="https://github.com/Celerium/Celerium.DattoBCDR/issues/new/choose" target="_blank">Report Bug</a>
    ·
    <a href="https://github.com/Celerium/Celerium.DattoBCDR/issues/new/choose" target="_blank">Request Feature</a>
  </p>
</div>

---

## About The Project

The [Celerium.DattoBCDR](https://www.powershellgallery.com/packages/Celerium.DattoBCDR) offers users the ability to extract data from Datto into third-party reporting tools and aims to abstract away the details of interacting with Datto's API endpoints in such a way that is consistent with PowerShell nomenclature. This gives system administrators and PowerShell developers a convenient and familiar way of using Datto's API to create documentation scripts, automation, and integrations.

- :book: Project documentation can be found on [Github Pages](https://celerium.github.io/Celerium.DattoBCDR/)
- :book: Datto's REST API documentation on their management portal [here](https://portal.dattobackup.com/integrations/api) *[ Requires a login ]*.
- OpenAPI Spec in [`json` format](<https://api.datto.com/v1/api/spec>) *[ No Auth required ]*.
  - OpenAPI Spec in **raw** [`yaml` format](https://api.datto.com/v1/api/spec/raw) *[ No Auth required ]*.

Datto features a REST API that makes use of common HTTP request methods. In order to maintain PowerShell best practices, only approved verbs are used.

- GET -> `Get-`
- PUT -> `Set-`

Additionally, PowerShell's `verb-noun` nomenclature is respected. Each noun is prefixed with `Datto` in an attempt to prevent naming problems.

For example, one might access the `/bcdr/device` endpoint by running the following PowerShell command with the appropriate parameters:

```posh
Get-DattoBCDRDevice -SerialNumber 12345
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Install

This module can be installed directly from the [PowerShell Gallery](https://www.powershellgallery.com/packages/Celerium.DattoBCDR) with the following command:

```posh
Install-Module -Name Celerium.DattoBCDR
```

- :information_source: This module supports PowerShell 5.0+ and *should* work in PowerShell Core.
- :information_source: If you are running an older version of PowerShell, or if PowerShellGet is unavailable, you can manually download the *main* branch and place the *Celerium.DattoBCDR* folder into the (default) `C:\Program Files\WindowsPowerShell\Modules` folder.

Project documentation can be found on [Github Pages](https://celerium.github.io/Celerium.DattoBCDR/)

- A full list of functions can be retrieved by running `Get-Command -Module Celerium.DattoBCDR`.
- Help info and a list of parameters can be found by running `Get-Help <command name>`, such as:

```posh
Get-Help Get-DattoBCDRDevice
Get-Help Get-DattoBCDRDevice -Full
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Initial Setup

After installing this module, you will need to configure the *API access tokens* that are used to talk with the Datto API.

1. Run `Add-DattoBCDRAPIKey -ApiKeyPublic 12345 -ApiKeySecret 123456789`
   - It will prompt you to enter your API access tokens if you do not specify them.
   - Datto API access tokens are generated via the Datto portal at *Admin > Integrations*
   <br>

2. [**optional**] Run `Export-DattoBCDRModuleSettings`
   - This will create a config file at `%UserProfile%\Celerium.DattoBCDR` that holds the *base uri* & *API access tokens* information.
   - Next time you run `Import-Module -Name Celerium.DattoBCDR`, this configuration file will automatically be loaded.
   - :warning: Exporting module settings encrypts your API access tokens in a format that can **only be unencrypted by the user principal** that encrypted the secret. It makes use of .NET DPAPI, which for Windows uses reversible encrypted tied to your user principal. This means that you **cannot copy** your configuration file to another computer or user account and expect it to work.
   - :warning: However in Linux\Unix operating systems the secret keys are more obfuscated than encrypted so it is recommend to use a more secure & cross-platform storage method.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Calling an API resource is as simple as running `Get-DattoBCDR<resourceName>`

- The following is a table of supported functions and their corresponding API resources:
- Example scripts can be found in the [examples](https://github.com/Celerium/Celerium.DattoBCDR/tree/main/examples) folder of this repository.

| Category  | EndpointUri                                                    | Method                         | Function                           |
|-----------|----------------------------------------------------------------|--------------------------------|------------------------------------|
| BCDR      | /bcdr/agent                                                    | GET                            | Get-DattoBCDRAgent                 |
| BCDR      | /bcdr/device                                                   | GET                            | Get-DattoBCDRDevice                |
| BCDR      | /bcdr/device/{serialNumber}                                    | GET                            | Get-DattoBCDRDevice                |
| BCDR      | /bcdr/device/{serialNumber}/alert                              | GET                            | Get-DattoBCDRAlert                 |
| BCDR      | /bcdr/device/{serialNumber}/asset                              | GET                            | Get-DattoBCDRAsset                 |
| BCDR      | /bcdr/device/{serialNumber}/asset/{volumeName}                 | GET                            | Get-DattoBCDRVolume                |
| BCDR      | /bcdr/device/{serialNumber}/asset/agent                        | GET                            | Get-DattoBCDRAgent                 |
| BCDR      | /bcdr/device/{serialNumber}/asset/share                        | GET                            | Get-DattoBCDRShare                 |
| BCDR      | /bcdr/device/{serialNumber}/vm-restores                        | GET                            | Get-DattoBCDRVMRestore             |
| DTC       | /dtc/{clientId}/assets                                         | GET                            | Get-DattoBCDRDTCAsset              |
| DTC       | /dtc/{clientId}/assets/{assetUuid}                             | GET                            | Get-DattoBCDRDTCAsset              |
| DTC       | /dtc/agent/{agentUuid}/bandwidth                               | PUT                            | Set-DattoBCDRDTCBandwidth          |
| DTC       | /dtc/assets                                                    | GET                            | Get-DattoBCDRDTCAsset              |
| DTC       | /dtc/rmm-templates                                             | GET                            | Get-DattoBCDRDTCRMMTemplate        |
| DTC       | /dtc/storage-pool                                              | GET                            | Get-DattoBCDRDTCStoragePool        |
| OpenAPI   | /api/spec                                                      | GET                            | Get-DattoBCDRAPISpec               |
| OpenAPI   | /api/spec/raw                                                  | GET                            | Get-DattoBCDRAPISpec               |
| Reporting | /report/activity-log                                           | GET                            | Get-DattoBCDRActivityLog           |
| SaaS      | /saas/{SaasCustomerId}/{externalSubscriptionId}/bulkSeatChange | PUT                            | Set-DattoBCDRSaaSBulkSeatChange    |
| SaaS      | /saas/{sassCustomerId}/detailedBackupStats                     | GET                            | Get-DattoBCDRSaaSBackupStats       |
| SaaS      | /sass/{sassCustomerId}/applications                            | GET                            | Get-DattoBCDRSaaSApplication       |
| SaaS      | /sass/{sassCustomerId}/seats                                   | GET                            | Get-DattoBCDRSaaSSeat              |
| SaaS      | /sass/domains                                                  | GET                            | Get-DattoBCDRSaaSDomain            |

Each `Get-DattoBCDR*` function will respond with the raw data that Datto's API provides.

- :warning: Returned data is mostly structured the same but can vary between commands.
- pagination - Information about the number of pages of results are available and other metadata.
- items - The actual information requested (this is what most people care about)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Contributing

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

See the [CONTRIBUTING](https://github.com/Celerium/Celerium.DattoBCDR/blob/master/.github/CONTRIBUTING.md) guide for more information about contributing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the MIT license. See [LICENSE](https://github.com/Celerium/Celerium.DattoBCDR/blob/master/LICENSE) for more information.

[![GitHub_License][GitHub_License-shield]][GitHub_License-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[Az_Pipeline-shield]:               https://img.shields.io/azure-devops/build/AzCelerium/Celerium.DattoBCDR/17?style=for-the-badge&label=DevOps_Build
[Az_Pipeline-url]:                  https://dev.azure.com/AzCelerium/Celerium.DattoBCDR/_build?definitionId=17

[GitHub_Pages-shield]:              https://img.shields.io/github/actions/workflow/status/celerium/Celerium.DattoBCDR/pages%2Fpages-build-deployment?style=for-the-badge&label=GitHub%20Pages
[GitHub_Pages-url]:                 https://github.com/Celerium/Celerium.DattoBCDR/actions/workflows/pages/pages-build-deployment

[GitHub_License-shield]:            https://img.shields.io/github/license/celerium/Celerium.DattoBCDR?style=for-the-badge
[GitHub_License-url]:               https://github.com/Celerium/Celerium.DattoBCDR/blob/main/LICENSE

[PoshGallery_Version-shield]:       https://img.shields.io/powershellgallery/v/Celerium.DattoBCDR?include_prereleases&style=for-the-badge
[PoshGallery_Version-url]:          https://www.powershellgallery.com/packages/Celerium.DattoBCDR

[PoshGallery_Platforms-shield]:     https://img.shields.io/powershellgallery/p/Celerium.DattoBCDR?style=for-the-badge
[PoshGallery_Platforms-url]:        https://www.powershellgallery.com/packages/Celerium.DattoBCDR

[PoshGallery_Downloads-shield]:     https://img.shields.io/powershellgallery/dt/Celerium.DattoBCDR?style=for-the-badge
[PoshGallery_Downloads-url]:        https://www.powershellgallery.com/packages/Celerium.DattoBCDR

[website-shield]:                   https://img.shields.io/website?up_color=blue&url=https%3A%2F%2Fcelerium.org&style=for-the-badge&label=Blog
[website-url]:                      https://celerium.org

[codeSize-shield]:                  https://img.shields.io/github/repo-size/celerium/Celerium.DattoBCDR?style=for-the-badge
[codeSize-url]:                     https://github.com/Celerium/Celerium.DattoBCDR

[contributors-shield]:              https://img.shields.io/github/contributors/celerium/Celerium.DattoBCDR?style=for-the-badge
[contributors-url]:                 https://github.com/Celerium/Celerium.DattoBCDR/graphs/contributors

[forks-shield]:                     https://img.shields.io/github/forks/celerium/Celerium.DattoBCDR?style=for-the-badge
[forks-url]:                        https://github.com/Celerium/Celerium.DattoBCDR/network/members

[stars-shield]:                     https://img.shields.io/github/stars/celerium/Celerium.DattoBCDR?style=for-the-badge
[stars-url]:                        https://github.com/Celerium/Celerium.DattoBCDR/stargazers

[issues-shield]:                    https://img.shields.io/github/issues/Celerium/Celerium.DattoBCDR?style=for-the-badge
[issues-url]:                       https://github.com/Celerium/Celerium.DattoBCDR/issues
