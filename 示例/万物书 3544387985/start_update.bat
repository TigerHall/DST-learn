@echo off
chcp 65001 >nul 2>&1

set "repoPath=%~dp0"
set "lockFile=%repoPath%.git\index.lock"

:: Check and delete git index lock file
if exist "%repoPath%.git\" (
    if exist "%lockFile%" (
        echo Deleting git index.lock file...
        del /f /q "%lockFile%" >nul 2>&1
        if errorlevel 1 (
            echo Error: Failed to delete index.lock. Please run as administrator.
        ) else (
            echo Successfully deleted index.lock.
        )
    ) else (
        echo No git index.lock file found.
    )
) else (
    echo Error: .git directory not found. Place this script in project root.
    pause
    exit /b 1
)

:: Locate PowerShell script
set "scriptPath=%~dp0update_by_git.ps1"
if not exist "%scriptPath%" (
    echo Error: update_by_git.ps1 not found in the same directory.
    pause
    exit /b 1
)

:: Execute PowerShell script with bypass policy
powershell -ExecutionPolicy Bypass -File "%scriptPath%"
pause