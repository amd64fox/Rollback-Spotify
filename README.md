<p align="center">
      <a href="https://loadspot.pages.dev"><img src="https://raw.githubusercontent.com/amd64fox/Rollback-Spotify/main/.github/Pic/Shields/excel.svg"></a>
      </p>
<center>
    <h1 align="center">Rollback Spotify</h1>
    <h3 align="center">Downgrade Spotify and block update for Windows</h3>
</center>

***

just download and run [Rollback-Spotify.bat](https://raw.githack.com/amd64fox/Rollback-Spotify/main/Rollback-Spotify.bat)
    - or run The following command in PowerShell:
```ps1
iwr -useb 'https://amd64fox.github.io/Rollback-Spotify/run.ps1' | iex
```

or specific version

```ps1
iex "& { $(iwr -useb 'https://amd64fox.github.io/Rollback-Spotify/run.ps1') } -version 1.2.24.756-x64"
```

or latest version x86/x64/arm64

```ps1
iex "& { $(iwr -useb 'https://amd64fox.github.io/Rollback-Spotify/run.ps1') } -version last-x64"
```

## Options
```text
-v, -version      Specifies the version to be installed
                  Examples: 1.2.24.756 (architecture will be detected automatically),
                  1.2.24.756-x64 (specific architecture), last (latest version for your OS),
                  last-x64 (latest version with specific architecture)

-u, -uninstall    Automatically uninstalls any existing Spotify version

-n, -not_block    Skips blocking of automatic updates after installation

-b, -buildtype    Filters versions by build type
                  [possible values: "release", "master", "all"] [default:"release"]
                  Warning: "master" builds can be unstable and are for testing only
```

## Credits
The file download function was taken from the [PsDownload](https://github.com/DanGough/PsDownload) module, thanks to [Dan Gough](https://github.com/DanGough)
