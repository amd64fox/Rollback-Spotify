@echo off
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12}"; "& {Invoke-WebRequest -UseBasicParsing 'https://cdn.statically.io/gh/amd64fox/Rollback-Spotify/main/Upd_Block.ps1' | Invoke-Expression}"
pause
exit /b