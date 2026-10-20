@echo off
title WebGIS Flores Timur Launcher
echo ======================================================
echo    Menjalankan WebGIS Flores Timur (Acara 6)
echo ======================================================
echo Membuka web server lokal dan menampilkan peta di browser...
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0server.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Server dihentikan atau terjadi error.
    pause
)
