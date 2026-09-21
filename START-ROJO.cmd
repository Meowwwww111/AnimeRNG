@echo off
setlocal
cd /d "%~dp0"
if not exist default.project.json (
  echo Missing default.project.json. Run this inside the cloned AnimeRNG repository.
  pause
  exit /b 1
)
if exist rojo.exe (
  rojo.exe serve default.project.json
) else (
  where rojo >nul 2>nul
  if errorlevel 1 (
    echo Rojo was not found. Place rojo.exe beside this file, or add Rojo to PATH.
    pause
    exit /b 1
  )
  rojo serve default.project.json
)
pause
