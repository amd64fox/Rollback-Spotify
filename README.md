<p align="center">
      <a href="https://t.me/SpotxCommunity"><img src="https://raw.githubusercontent.com/amd64fox/SpotX/main/.github/Pic/Shields/SpotX_Community.svg"></a>
      <a href="https://cutt.ly/8EH6NuH"><img src="https://raw.githubusercontent.com/amd64fox/Rollback-Spotify/main/.github/Pic/Shields/excel.svg"></a>
      </p>
<center>
    <h1 align="center">Rollback Spotify</h1>
    <h3 align="center">Downgrade Spotify and block update for Windows</h3>
</center>

***

1. <strong> Uninstall your current Spotify (you can use the [script](https://github.com/amd64fox/Uninstall-Spotify) for a complete uninstall.)</strong> 
2. <strong> Download the [version of Spotify](https://cutt.ly/8EH6NuH) you need and install it</strong>
   >**Note** 
Do not use versions from 1.1.58 and below, the developers of Spotify forcibly restricted them.

3. <strong> Now it remains to block updates, just download and run [Upd_Block.bat](https://cutt.ly/gKGHVMc)
    - or run The following command in PowerShell:
```ps1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/amd64fox/Rollback-Spotify/main/Upd_Block.ps1' | Invoke-Expression
```

***

<center>
  <h3 align="center"> Congratulations you downgraded your version of Spotify and blocked updates, good luck.</h3>
</center>