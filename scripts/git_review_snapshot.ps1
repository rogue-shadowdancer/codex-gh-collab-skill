[CmdletBinding()]
param(
    [string]$RepoPath = ".",
    [string]$BaseRef = "",
    [string]$HeadRef = "HEAD",
    [int]$MaxCommits = 20
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

function Resolve-BaseRef {
    param(
        [string]$RequestedBaseRef
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedBaseRef)) {
        return $RequestedBaseRef
    }

    $originHeadRef = Try-Git -Arguments @("symbolic-ref", "refs/remotes/origin/HEAD")
    if ($originHeadRef) {
        return ($originHeadRef | Select-Object -First 1).Trim() -replace "^refs/remotes/", ""
    }

    throw "BaseRef was not provided and origin/HEAD could not be inferred."
}

$repoRoot = (Invoke-Git -Arguments @("rev-parse", "--show-toplevel") | Select-Object -First 1).Trim()
$resolvedBaseRef = Resolve-BaseRef -RequestedBaseRef $BaseRef
$currentBranch = (Try-Git -Arguments @("branch", "--show-current") | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    $currentBranch = "DETACHED"
}

[void](Invoke-Git -Arguments @("rev-parse", "--verify", $resolvedBaseRef))
[void](Invoke-Git -Arguments @("rev-parse", "--verify", $HeadRef))

$mergeBase = (Invoke-Git -Arguments @("merge-base", $resolvedBaseRef, $HeadRef) | Select-Object -First 1).Trim()
$commits = Invoke-Git -Arguments @("log", "--oneline", "--decorate", "$mergeBase..$HeadRef", "-n", $MaxCommits.ToString())
$nameStatus = Invoke-Git -Arguments @("diff", "--name-status", "--find-renames", $mergeBase, $HeadRef)
$diffStat = Invoke-Git -Arguments @("diff", "--stat", "--find-renames", $mergeBase, $HeadRef)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Repo path: $repoRoot")
$lines.Add("Current branch: $currentBranch")
$lines.Add("Base ref: $resolvedBaseRef")
$lines.Add("Head ref: $HeadRef")
$lines.Add("Merge base: $mergeBase")
$lines.Add("")
$lines.Add("Commits in scope:")
if ($commits.Count -eq 0) {
    $lines.Add("(none)")
} else {
    foreach ($line in $commits) {
        $lines.Add($line.ToString())
    }
}

$lines.Add("")
$lines.Add("Changed files:")
if ($nameStatus.Count -eq 0) {
    $lines.Add("(none)")
} else {
    foreach ($line in $nameStatus) {
        $lines.Add($line.ToString())
    }
}

$lines.Add("")
$lines.Add("Diffstat:")
if ($diffStat.Count -eq 0) {
    $lines.Add("(none)")
} else {
    foreach ($line in $diffStat) {
        $lines.Add($line.ToString())
    }
}

$lines -join [Environment]::NewLine
