#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('base', 'net', 'net-consoleapp', 'net-webapp', 'net-desktopapp', 'python', 'unity', 'iac-base', 'ansible', 'salt')]
    [string]$Profile,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9._-]*$')]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Destination,

    [string]$DotnetSdkVersion = '10.0.302',
    [string]$TargetFramework = 'net10.0',
    [string]$PythonVersion = '3.12',
    [string]$UnityVersion = '6000.3.17f1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectSlug {
    param([string]$ProjectName)

    $slug = $ProjectName.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw 'The project name does not produce a usable slug.'
    }

    return $slug
}

function Copy-TemplateContent {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][hashtable]$TokenValues
    )

    $sourceEntries = [System.Collections.Generic.List[object]]::new()
    foreach ($topLevelEntry in Get-ChildItem -LiteralPath $Source -Force) {
        if ($topLevelEntry.Name -in @('.git', '.template')) {
            continue
        }

        $sourceEntries.Add($topLevelEntry)
        if ($topLevelEntry.PSIsContainer) {
            foreach ($childEntry in Get-ChildItem -LiteralPath $topLevelEntry.FullName -Force -Recurse) {
                $sourceEntries.Add($childEntry)
            }
        }
    }

    $expandedTargets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $sourceEntries | Sort-Object @{ Expression = { $_.FullName.Length }; Ascending = $true }, @{ Expression = { $_.FullName }; Ascending = $true }) {
        $sourceRelativePath = Get-SafeRelativePath -RelativePath ([System.IO.Path]::GetRelativePath($Source, $entry.FullName))
        $targetRelativePath = Get-SafeRelativePath -RelativePath (Expand-TemplateString -Value $sourceRelativePath -TokenValues $TokenValues)
        if (-not $expandedTargets.Add($targetRelativePath)) {
            throw "Template path collision after token replacement: $targetRelativePath"
        }

        $targetPath = Join-Path $Target $targetRelativePath
        if ($entry.PSIsContainer) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        } else {
            $targetParent = Split-Path -Parent $targetPath
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            Copy-Item -LiteralPath $entry.FullName -Destination $targetPath -Force
        }
    }
}

function Assert-EmptyDestination {
    param([Parameter(Mandatory)][string]$DestinationPath)

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Container)) {
        throw "Destination must be a directory: $DestinationPath"
    }
    if (Get-ChildItem -LiteralPath $DestinationPath -Force | Select-Object -First 1) {
        throw "Destination must be empty: $DestinationPath"
    }
}

function Publish-TemplateContent {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    Assert-EmptyDestination -DestinationPath $Destination
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    foreach ($directory in Get-ChildItem -LiteralPath $Source -Directory -Recurse -Force | Sort-Object @{ Expression = { $_.FullName.Length }; Ascending = $true }, FullName) {
        $relativePath = Get-SafeRelativePath -RelativePath ([System.IO.Path]::GetRelativePath($Source, $directory.FullName))
        $targetPath = Join-Path $Destination $relativePath
        if (Test-Path -LiteralPath $targetPath) {
            throw "Destination path appeared during publication: $targetPath"
        }
        New-Item -ItemType Directory -Path $targetPath | Out-Null
    }

    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force | Sort-Object FullName) {
        $relativePath = Get-SafeRelativePath -RelativePath ([System.IO.Path]::GetRelativePath($Source, $file.FullName))
        $targetPath = Join-Path $Destination $relativePath
        if (Test-Path -LiteralPath $targetPath) {
            throw "Destination path appeared during publication: $targetPath"
        }

        $input = [System.IO.File]::OpenRead($file.FullName)
        try {
            $output = [System.IO.FileStream]::new(
                $targetPath,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            try {
                $input.CopyTo($output)
            } finally {
                $output.Dispose()
            }
        } finally {
            $input.Dispose()
        }
    }
}

function Get-SafeRelativePath {
    param([string]$RelativePath)

    if (
        [string]::IsNullOrWhiteSpace($RelativePath) -or
        [System.IO.Path]::IsPathRooted($RelativePath) -or
        ($RelativePath -split '[\\/]') -contains '..' -or
        $RelativePath -match '[*?\[\]<>|":]' -or
        $RelativePath -match '[\x00-\x1f]'
    ) {
        throw "Unsafe profile path: $RelativePath"
    }

    return ($RelativePath -replace '\\', '/')
}

function Assert-SupportedSchemaVersion {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ManifestName
    )

    if ($Manifest.schemaVersion -ne 2) {
        throw "$ManifestName must use schema version 2."
    }
}

function Get-EffectivePathRequirements {
    param([Parameter(Mandatory)][object[]]$Manifests)

    $effective = [ordered]@{}
    foreach ($manifest in $Manifests) {
        $property = $manifest.PSObject.Properties['pathRequirements']
        if ($null -eq $property -or $null -eq $property.Value) {
            throw "Manifest $($manifest.id) must define pathRequirements."
        }

        foreach ($requirement in @($property.Value)) {
            if ($null -eq $requirement) {
                throw "Manifest $($manifest.id) contains an empty path requirement."
            }
            $pathProperty = $requirement.PSObject.Properties['path']
            $kindProperty = $requirement.PSObject.Properties['kind']
            $statusProperty = $requirement.PSObject.Properties['status']
            if ($null -eq $pathProperty -or $null -eq $kindProperty -or $null -eq $statusProperty) {
                throw "Manifest $($manifest.id) contains an incomplete path requirement."
            }

            $path = Get-SafeRelativePath -RelativePath ([string]$pathProperty.Value)
            $kind = [string]$kindProperty.Value
            $status = [string]$statusProperty.Value
            if ($kind -notin @('file', 'directory') -or $status -notin @('required', 'optional')) {
                throw "Manifest $($manifest.id) contains an invalid path requirement for $path."
            }

            $effective["$kind|$path"] = [pscustomobject]@{
                Path = $path
                Kind = $kind
                Status = $status
            }
        }
    }

    return @($effective.Values)
}

function Expand-TemplateString {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][hashtable]$TokenValues
    )

    $result = $Value
    foreach ($tokenName in $TokenValues.Keys) {
        $result = $result.Replace("{{${tokenName}}}", [string]$TokenValues[$tokenName])
    }
    if ($result -match '{{[A-Z0-9_]+}}') {
        throw "Unresolved template token in path requirement: $Value"
    }

    return $result
}

function Resolve-PathRequirements {
    param(
        [Parameter(Mandatory)][object[]]$Requirements,
        [Parameter(Mandatory)][hashtable]$TokenValues
    )

    return @($Requirements | ForEach-Object {
        [pscustomobject]@{
            Path = Get-SafeRelativePath -RelativePath (Expand-TemplateString -Value $_.Path -TokenValues $TokenValues)
            Kind = $_.Kind
            Status = $_.Status
        }
    })
}

function Test-DirectoryHasRealContent {
    param([Parameter(Mandatory)][string]$Directory)

    return $null -ne (Get-ChildItem -LiteralPath $Directory -File -Recurse -Force |
        Where-Object { $_.Name -ne '.gitkeep' } |
        Select-Object -First 1)
}

function Remove-EmptyOptionalDirectories {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][object[]]$Requirements
    )

    $requiredPaths = @($Requirements | Where-Object { $_.Status -eq 'required' })
    $optionalDirectories = @($Requirements |
        Where-Object { $_.Status -eq 'optional' -and $_.Kind -eq 'directory' } |
        Sort-Object { $_.Path.Length } -Descending)

    foreach ($requirement in $optionalDirectories) {
        $hasRequiredDescendant = $requiredPaths | Where-Object {
            $_.Path -ne $requirement.Path -and
            $_.Path.StartsWith("$($requirement.Path)/", [System.StringComparison]::Ordinal)
        } | Select-Object -First 1
        if ($null -ne $hasRequiredDescendant) {
            continue
        }

        $directory = Join-Path $Root $requirement.Path
        if ((Test-Path -LiteralPath $directory -PathType Container) -and -not (Test-DirectoryHasRealContent -Directory $directory)) {
            Remove-Item -LiteralPath $directory -Recurse -Force
        }
    }
}

function Assert-RequiredPaths {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][object[]]$Requirements
    )

    foreach ($requirement in $Requirements | Where-Object { $_.Status -eq 'required' }) {
        $path = Join-Path $Root $requirement.Path
        $pathType = if ($requirement.Kind -eq 'file') { 'Leaf' } else { 'Container' }
        if (-not (Test-Path -LiteralPath $path -PathType $pathType)) {
            throw "Required $($requirement.Kind) path is missing: $($requirement.Path)"
        }
    }
}

function Read-ProfileManifest {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$ProfileId
    )

    $directory = Join-Path $SourceRoot "$ProfileId-template"
    $manifestPath = Join-Path $directory '.template/profile.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Profile manifest is missing: $manifestPath"
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    if ($manifest.id -ne $ProfileId) {
        throw "Profile manifest id does not match directory: $ProfileId"
    }
    Assert-SupportedSchemaVersion -Manifest $manifest -ManifestName "Profile manifest $ProfileId"

    return [pscustomobject]@{ Id = $ProfileId; Directory = $directory; Manifest = $manifest }
}

function Resolve-ProfileChain {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)]$BaseManifest
    )

    if ($ProfileId -eq 'base') {
        return @()
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $reversed = [System.Collections.Generic.List[object]]::new()
    $currentId = $ProfileId
    while ($currentId -ne 'base') {
        if (-not $seen.Add($currentId)) {
            throw "Profile inheritance cycle detected at: $currentId"
        }
        $entry = Read-ProfileManifest -SourceRoot $SourceRoot -ProfileId $currentId
        if ($entry.Manifest.requiredBaseSchemaVersion -ne $BaseManifest.schemaVersion) {
            throw "Profile $currentId requires base schema $($entry.Manifest.requiredBaseSchemaVersion)."
        }
        $reversed.Add($entry)
        $parentProperty = $entry.Manifest.PSObject.Properties['parentProfile']
        if ($null -eq $parentProperty -or [string]::IsNullOrWhiteSpace([string]$parentProperty.Value)) {
            throw "Profile $currentId must declare parentProfile."
        }
        $parentId = [string]$parentProperty.Value
        if ($parentId -eq 'base' -and $entry.Manifest.requiredParentSchemaVersion -ne $BaseManifest.schemaVersion) {
            throw "Profile $currentId requires parent schema $($entry.Manifest.requiredParentSchemaVersion)."
        }
        $currentId = $parentId
    }

    $ordered = @($reversed.ToArray()[($reversed.Count - 1)..0])
    for ($index = 1; $index -lt $ordered.Count; $index++) {
        $parent = $ordered[$index - 1]
        $child = $ordered[$index]
        if ($child.Manifest.parentProfile -ne $parent.Id -or $child.Manifest.requiredParentSchemaVersion -ne $parent.Manifest.schemaVersion) {
            throw "Profile inheritance is incompatible for: $($child.Id)"
        }
    }
    return $ordered
}

function Merge-ProfileFragment {
    param(
        [Parameter(Mandatory)][string]$ProfileDirectory,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$DestinationDirectory,
        [Parameter(Mandatory)]$Fragment
    )

    $sourceRelativePath = Get-SafeRelativePath -RelativePath $Fragment.source
    $targetRelativePath = Get-SafeRelativePath -RelativePath $Fragment.target
    $sourcePath = Join-Path $ProfileDirectory $sourceRelativePath
    $targetPath = Join-Path $DestinationDirectory $targetRelativePath

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Profile fragment is missing: $sourcePath"
    }
    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        throw "Profile fragment target is missing: $targetPath"
    }

    $fragmentText = [System.IO.File]::ReadAllText($sourcePath).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd()
    $marker = "`n# Profile overlay: $ProfileId`n"
    [System.IO.File]::AppendAllText($targetPath, $marker + $fragmentText + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Replace-Tokens {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][hashtable]$TokenValues
    )

    $textExtensions = @(
        '.asmdef', '.axaml', '.cs', '.cshtml', '.csproj', '.editorconfig', '.gitattributes', '.gitignore',
        '.env', '.json', '.md', '.meta', '.props', '.ps1', '.py', '.sh', '.slnx', '.toml',
        '.txt', '.unity', '.xml', '.yaml', '.yml'
    )

    Get-ChildItem -LiteralPath $Root -File -Recurse -Force | Where-Object {
        $extension = [System.IO.Path]::GetExtension($_.Name).ToLowerInvariant()
        $textExtensions -contains $extension -or $_.Name -in @('.editorconfig', '.gitattributes', '.gitignore', 'Dockerfile')
    } | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName).Replace("`r`n", "`n").Replace("`r", "`n")
        foreach ($tokenName in $TokenValues.Keys) {
            $content = $content.Replace("{{${tokenName}}}", [string]$TokenValues[$tokenName])
        }
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    }

    $remainingTokens = Get-ChildItem -LiteralPath $Root -File -Recurse -Force | ForEach-Object {
        Select-String -LiteralPath $_.FullName -Pattern '{{[A-Z0-9_]+}}' -AllMatches -ErrorAction SilentlyContinue
    }
    if ($remainingTokens) {
        $paths = $remainingTokens | Select-Object -ExpandProperty Path -Unique
        throw "Unresolved template tokens found in: $($paths -join ', ')"
    }
}

function Assert-NoUnresolvedPathTokens {
    param(
        [Parameter(Mandatory)][string]$Root
    )

    $remainingTokens = Get-ChildItem -LiteralPath $Root -Force -Recurse | Where-Object {
        $_.Name -match '{{[A-Z0-9_]+}}'
    }
    if ($remainingTokens) {
        $paths = $remainingTokens | Select-Object -ExpandProperty FullName -Unique
        throw "Unresolved template tokens found in paths: $($paths -join ', ')"
    }
}

$catalogRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $catalogRoot 'src'
$baseDirectory = Join-Path $sourceRoot 'base-template'
$baseManifestPath = Join-Path $baseDirectory '.template/template.json'

if (-not (Test-Path -LiteralPath $baseManifestPath -PathType Leaf)) {
    throw "Base template manifest is missing: $baseManifestPath"
}

$baseManifest = Get-Content -LiteralPath $baseManifestPath -Raw -Encoding utf8 | ConvertFrom-Json
Assert-SupportedSchemaVersion -Manifest $baseManifest -ManifestName 'Base template manifest'

$destinationPath = [System.IO.Path]::GetFullPath($Destination)
Assert-EmptyDestination -DestinationPath $destinationPath
$scratchPath = Join-Path ([System.IO.Path]::GetTempPath()) "repo-template-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $scratchPath | Out-Null

$slug = Get-ProjectSlug -ProjectName $Name
$tokenValues = @{
    PROJECT_NAME = $Name
    PROJECT_SLUG = $slug
    PYTHON_PACKAGE = ($slug -replace '-', '_')
    DOTNET_SDK_VERSION = $DotnetSdkVersion
    TARGET_FRAMEWORK = $TargetFramework
    PYTHON_VERSION = $PythonVersion
    UNITY_VERSION = $UnityVersion
}

try {
    Copy-TemplateContent -Source $baseDirectory -Target $scratchPath -TokenValues $tokenValues

    $profileChain = @(Resolve-ProfileChain -SourceRoot $sourceRoot -ProfileId $Profile -BaseManifest $baseManifest)
    $manifestChain = [System.Collections.Generic.List[object]]::new()
    $manifestChain.Add($baseManifest)
    foreach ($entry in $profileChain) {
        $manifestChain.Add($entry.Manifest)
    }
    $pathRequirements = Get-EffectivePathRequirements -Manifests @($manifestChain.ToArray())

    foreach ($entry in $profileChain) {
        $overlayDirectory = Join-Path $entry.Directory 'overlay'
        if (Test-Path -LiteralPath $overlayDirectory -PathType Container) {
            Copy-TemplateContent -Source $overlayDirectory -Target $scratchPath -TokenValues $tokenValues
        }

        foreach ($fragment in @($entry.Manifest.fragments)) {
            Merge-ProfileFragment -ProfileDirectory $entry.Directory -ProfileId $entry.Id -DestinationDirectory $scratchPath -Fragment $fragment
        }

        foreach ($relativePath in @($entry.Manifest.removePaths)) {
            $safePath = Get-SafeRelativePath -RelativePath $relativePath
            $pathToRemove = Join-Path $scratchPath $safePath
            if (Test-Path -LiteralPath $pathToRemove) {
                Remove-Item -LiteralPath $pathToRemove -Recurse -Force
            }
        }
    }

    Replace-Tokens -Root $scratchPath -TokenValues $tokenValues
    Assert-NoUnresolvedPathTokens -Root $scratchPath
    $resolvedPathRequirements = Resolve-PathRequirements -Requirements $pathRequirements -TokenValues $tokenValues
    Remove-EmptyOptionalDirectories -Root $scratchPath -Requirements $resolvedPathRequirements
    Assert-RequiredPaths -Root $scratchPath -Requirements $resolvedPathRequirements
    Publish-TemplateContent -Source $scratchPath -Destination $destinationPath
    Assert-RequiredPaths -Root $destinationPath -Requirements $resolvedPathRequirements
    Write-Output "Created $Profile template at $destinationPath"
} finally {
    if (Test-Path -LiteralPath $scratchPath) {
        Remove-Item -LiteralPath $scratchPath -Recurse -Force
    }
}
