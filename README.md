# Bootstrap Workstation

## Instructions

Boot your new workstation for the first time, and get all the available Windows Updates. After that run:

```ps
Set-ExecutionPolicy Bypass -Scope Process -Force; & $([scriptblock]::Create((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/intinig/bootstrap-workstation/master/bootstrap.ps1'))) -Init
```
