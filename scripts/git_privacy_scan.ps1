[CmdletBinding()]
param(
    [string]$RepoPath = "."
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & git -C $RepoPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0) {
        $message = ($output | Out-String).Trim()
        throw "git $($Arguments -join ' ') failed.`n$message"
    }

    return $output
}

$repoRoot = (Invoke-Git -Arguments @("rev-parse", "--show-toplevel") | Select-Object -First 1).Trim()
$filePaths = Get-ChildItem -Path $repoRoot -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch '[\\/]\.git([\\/]|$)' } |
    Select-Object -ExpandProperty FullName

$patterns = @(
    [pscustomobject]@{ Name = "Windows home path"; Regex = 'C:\\Users\\' },
    [pscustomobject]@{ Name = "Unix home path"; Regex = '/(Users|home)/[^/\s]+' },
    [pscustomobject]@{ Name = "GitHub token"; Regex = 'gh[pousr]_[A-Za-z0-9_]+' },
    [pscustomobject]@{ Name = "Fine-grained GitHub token"; Regex = 'github_pat_[A-Za-z0-9_]+' },
    [pscustomobject]@{ Name = "Private key header"; Regex = '-----BEGIN (RSA|OPENSSH|EC|DSA|PGP)? ?PRIVATE KEY-----' },
    [pscustomobject]@{ Name = "AWS access key"; Regex = 'AKIA[0-9A-Z]{16}' }
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Repo path: $repoRoot")
$lines.Add("")
$lines.Add("Working tree scan:")

foreach ($pattern in $patterns) {
    if ($filePaths.Count -eq 0) {
        $matches = @()
    } else {
        $matches = Select-String -Path $filePaths -Pattern $pattern.Regex -AllMatches -ErrorAction SilentlyContinue
    }

    if (-not $matches -or $matches.Count -eq 0) {
        $lines.Add("- $($pattern.Name): none")
        continue
    }

    $locations = $matches |
        ForEach-Object {
            $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $_.Path)
            "{0}:{1}" -f $relativePath, $_.LineNumber
        } |
        Sort-Object -Unique

    $lines.Add("- $($pattern.Name): $($locations.Count) match(es)")
    foreach ($location in $locations) {
        $lines.Add("  $location")
    }
}

$lines.Add("")
$lines.Add("Remote URL scan:")
$remoteLines = Invoke-Git -Arguments @("remote", "-v")
$suspiciousRemotes = $remoteLines |
    Where-Object {
        $_ -match 'https://[^@\s/]+@' -or $_ -match 'https://[^/\s]+:[^@\s]+@'
    } |
    Sort-Object -Unique

if (-not $suspiciousRemotes -or $suspiciousRemotes.Count -eq 0) {
    $lines.Add("- No remote URLs with embedded userinfo detected")
} else {
    $lines.Add("- Review remote URLs with embedded userinfo before publication")
    foreach ($remoteLine in $suspiciousRemotes) {
        $lines.Add("  $remoteLine")
    }
}

$lines.Add("")
$lines.Add("Git history identities:")
$historyEmails = Invoke-Git -Arguments @("log", "--format=%ae") |
    ForEach-Object { $_.ToString().Trim() } |
    Where-Object { $_ } |
    Sort-Object -Unique
$reviewEmails = $historyEmails | Where-Object { $_ -notmatch 'users\.noreply\.github\.com$' }

if (-not $reviewEmails -or $reviewEmails.Count -eq 0) {
    $lines.Add("- No non-noreply commit emails detected in current history")
} else {
    $lines.Add("- Review these commit emails before public release")
    foreach ($email in $reviewEmails) {
        $lines.Add("  $email")
    }
}

$lines -join [Environment]::NewLine
