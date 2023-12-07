@echo off
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12}"; "& {Invoke-WebRequest -UseBasicParsing 'https://amd64fox.github.io/Rollback-Spotify/run.ps1' | Invoke-Expression}"
pause
exit /b