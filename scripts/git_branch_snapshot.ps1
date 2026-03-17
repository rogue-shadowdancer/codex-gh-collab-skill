[CmdletBinding()]
param(
    [string]$RepoPath = ".",
    [int]$MaxGraphCommits = 30
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

function Try-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & git -C $RepoPath @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0) {
        return $null
    }

    return $output
}

$repoRoot = (Invoke-Git -Arguments @("rev-parse", "--show-toplevel") | Select-Object -First 1).Trim()
$currentBranch = (Try-Git -Arguments @("branch", "--show-current") | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    $currentBranch = "DETACHED@" + ((Invoke-Git -Arguments @("rev-parse", "--short", "HEAD") | Select-Object -First 1).Trim())
}

$originHeadRef = Try-Git -Arguments @("symbolic-ref", "refs/remotes/origin/HEAD")
$defaultBranch = if ($originHeadRef) {
    ($originHeadRef | Select-Object -First 1).Trim() -replace "^refs/remotes/origin/", ""
} else {
    "unknown"
}

$status = Invoke-Git -Arguments @("status", "--short", "--branch")
$remotes = Invoke-Git -Arguments @("remote", "-v")
$branchRows = Invoke-Git -Arguments @(
    "for-each-ref",
    "--format=%(refname:short)|%(upstream:short)|%(upstream:trackshort)|%(objectname:short)|%(subject)",
    "refs/heads"
)
$graph = Invoke-Git -Arguments @("log", "--graph", "--decorate", "--oneline", "--all", "-n", $MaxGraphCommits.ToString())

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Repo path: $repoRoot")
$lines.Add("Current branch: $currentBranch")
$lines.Add("Default remote branch: $defaultBranch")
$lines.Add("")
$lines.Add("Status:")
foreach ($line in $status) {
    $lines.Add($line.ToString())
}

$lines.Add("")
$lines.Add("Remotes:")
foreach ($line in $remotes) {
    $lines.Add($line.ToString())
}

$lines.Add("")
$lines.Add("Local branches:")
foreach ($row in $branchRows) {
    $parts = $row.ToString().Split("|", 5)
    $branchName = $parts[0]
    $upstream = if ($parts.Length -ge 2 -and $parts[1]) { $parts[1] } else { "-" }
    $track = if ($parts.Length -ge 3 -and $parts[2]) { $parts[2] } else { "-" }
    $sha = if ($parts.Length -ge 4 -and $parts[3]) { $parts[3] } else { "-" }
    $subject = if ($parts.Length -ge 5 -and $parts[4]) { $parts[4] } else { "" }
    $marker = if ($branchName -eq $currentBranch) { "*" } else { " " }
    $lines.Add(("{0} {1} -> {2} [{3}] {4} {5}" -f $marker, $branchName, $upstream, $track, $sha, $subject).TrimEnd())
}

$lines.Add("")
$lines.Add("Recent graph:")
foreach ($line in $graph) {
    $lines.Add($line.ToString())
}

$lines -join [Environment]::NewLine
