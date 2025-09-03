[CmdletBinding()]
param(
    [switch]$All
)

function Get-NormalizedLanguageCountry {
    param(
        [string[]]$Tags
    )
    $Tags |
        Where-Object { $_ } |
        ForEach-Object {
            # Replace underscore with dash, split, pick first + last segment
            $norm = $_ -replace '_','-'
            $parts = $norm -split '-'
            if ($parts.Count -ge 2) {
                $lang = $parts[0].ToLower()
                $region = $parts[-1].ToUpper()
                # Basic validation: language 2-3 letters, region 2 letters or 3 digits
                if ($lang -match '^[a-z]{2,3}$' -and $region -match '^([A-Z]{2}|[0-9]{3})$') {
                    "$lang-$region"
                }
            }
        } | Sort-Object -Unique
}

if ($All) {
    $tags = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::SpecificCultures).Name
} else {
    try {
        $tags = (Get-WinUserLanguageList).LanguageTag
    } catch {
        $tags = @()
    }
    if (-not $tags -or $tags.Count -eq 0) {
        $tags = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::SpecificCultures).Name
    }
}

Get-NormalizedLanguageCountry -Tags $tags | ForEach-Object { Write-Output $_ }

<#
Usage:
  .\List-LocaleLanguageCountry.ps1
  .\List-LocaleLanguageCountry.ps1 -All

Outputs lines like:
en-US
fr-FR
es-419
#>
