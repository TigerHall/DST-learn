# Set global SSL verify disable (preserve original function)
git config --global http.sslVerify false
git config --global https.sslVerify false

# Define paths (force absolute path to avoid relative path issues)
$projectRoot = Resolve-Path $PSScriptRoot
$gitDir = Join-Path $projectRoot ".git"
$targetDir = Join-Path $projectRoot "_FOR_STEAM_UPLOAD"

# Additional git lock cleanup (double safety)
$lockFile = Join-Path $gitDir "index.lock"
if (Test-Path $lockFile) {
    try {
        Remove-Item -Path $lockFile -Force -ErrorAction Stop
        Write-Host "Removed existing git index.lock file."
    }
    catch {
        Write-Host "Warning: Failed to remove index.lock - $_" -ForegroundColor Yellow
    }
}

# Verify git repository existence
if (-not (Test-Path $gitDir)) {
    Write-Host "Error: .git directory not found. Script must be in project root." -ForegroundColor Red
    exit 1
}

# Git operations to pull latest master branch
Write-Host "`n=== Starting Git Update ==="
Write-Host "Resetting local changes..."
git checkout .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: git checkout . failed" -ForegroundColor Red
    exit 1
}

Write-Host "Fetching all remote branches..."
git fetch --all
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: git fetch --all failed" -ForegroundColor Red
    exit 1
}

Write-Host "Checking out master branch..."
git checkout master
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: git checkout master failed" -ForegroundColor Red
    exit 1
}

Write-Host "Hard reset to origin/master..."
git reset --hard origin/master
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: git reset --hard origin/master failed" -ForegroundColor Red
    exit 1
}

# Show git status
Write-Host "`n=== Git Status ==="
git status
Write-Host "`n=== Git Update Completed ==="

# File synchronization for Steam upload
Write-Host "`n=== Starting File Synchronization ==="
Write-Host "Target directory: $targetDir"

# Create target directory if not exists
if (-not (Test-Path $targetDir)) {
    try {
        New-Item -ItemType Directory -Path $targetDir -ErrorAction Stop | Out-Null
        Write-Host "Created target directory successfully."
    }
    catch {
        Write-Host "Error: Failed to create target directory - $_" -ForegroundColor Red
        exit 1
    }
}

# Synchronize files with Robocopy (fixed: exclude target dir + .git)
# /E: Copy all subdirectories (including empty ones)
# /MIR: Mirror mode (sync additions/deletions)
# /XD .git _FOR_STEAM_UPLOAD: Exclude git directory AND target directory
# /R:3 /W:5: Retry 3 times, wait 5s between retries
# /N*: Suppress unnecessary logs
Write-Host "Synchronizing files (exclude .git and target directory)..."
Robocopy $projectRoot $targetDir /E /MIR /XD .git _FOR_STEAM_UPLOAD /R:3 /W:5 /NFL /NDL /NJH /NJS

# Check Robocopy exit code (0-7 = normal, >=8 = error)
if ($LASTEXITCODE -ge 8) {
    Write-Host "Error: File synchronization failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "File synchronization completed successfully." -ForegroundColor Green
}

Write-Host "`n=== All Operations Finished Successfully ==="