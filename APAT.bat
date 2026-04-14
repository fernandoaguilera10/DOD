@echo off
REM APAT — Auditory Physiology Analysis Tool
REM Double-click this file on Windows to launch the app.

REM Derive Code Archive path from this script's location
set "CODE_DIR=%~dp0"
REM Remove trailing backslash
if "%CODE_DIR:~-1%"=="\" set "CODE_DIR=%CODE_DIR:~0,-1%"

REM Build MATLAB startup command
set "MCMD=cd('%CODE_DIR:\=/%'); addpath(fullfile(pwd,'private')); APAT_app"

REM Find matlab.exe (checks common install locations across versions)
set "MATLAB_EXE="
for /d %%V in ("%ProgramFiles%\MATLAB\R*") do set "MATLAB_EXE=%%V\bin\matlab.exe"
for /d %%V in ("%ProgramFiles(x86)%\MATLAB\R*") do set "MATLAB_EXE=%%V\bin\matlab.exe"

if not defined MATLAB_EXE (
    echo MATLAB not found. Please install MATLAB and try again.
    pause
    exit /b 1
)

REM Launch MATLAB with APAT_app as startup command
start "" "%MATLAB_EXE%" -nosplash -r "%MCMD%"
