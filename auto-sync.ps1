# Auto-sync script: monitors local changes and keeps `origin/main` in sync.
# It will commit local edits with a timestamp, then pull --rebase and push.

param(
    [int]$IntervalSeconds = 300,
    [string]$Branch = "main"
)

$repoPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoPath

git rev-parse --is-inside-work-tree 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Not a git repository: $repoPath"
}

git remote get-url origin 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Remote 'origin' is not configured."
}

Write-Host "Auto-sync started for: $repoPath"
Write-Host "Branch: $Branch"
Write-Host "Interval: $IntervalSeconds seconds"
Write-Host "Press Ctrl+C to stop."

while ($true) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Fetch first so pull/push status is always current.
    git fetch origin $Branch 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[$now] Fetch failed; retrying on next cycle." -ForegroundColor Yellow
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    $status = git status --porcelain
    if ($status) {
        Write-Host "[$now] Local changes detected. Creating commit..." -ForegroundColor Cyan

        git add -A
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[$now] git add failed; retrying later." -ForegroundColor Yellow
            Start-Sleep -Seconds $IntervalSeconds
            continue
        }

        $commitMsg = "Auto-sync: $now"
        git commit -m $commitMsg 1>$null 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$now] Commit created: $commitMsg" -ForegroundColor Green
        } else {
            Write-Host "[$now] Nothing new to commit after staging." -ForegroundColor DarkGray
        }
    }

    git pull --rebase origin $Branch 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        git rebase --abort 1>$null 2>$null
        Write-Host "[$now] Pull --rebase failed (possible conflict). Resolve manually and restart." -ForegroundColor Yellow
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    git push origin $Branch 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[$now] Sync complete." -ForegroundColor Green
    } else {
        Write-Host "[$now] Push failed; will retry next cycle." -ForegroundColor Yellow
    }

    Start-Sleep -Seconds $IntervalSeconds
}
