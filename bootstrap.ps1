param (
    [switch] $Init = $false,
    [switch] $Restart = $false
)

function Add-Chocolatey {
    if (Get-Command "choco" -errorAction SilentlyContinue) {
        Write-Output "[info] 'chocolatey' already installed"
    }
    else {
        $ExecutionPolicy = Get-ExecutionPolicy
        if ($ExecutionPolicy -eq "Restricted") {
            Write-Output "[info] ExecutionPolicy is restricted, changing it to Bypass"
            Set-ExecutionPolicy Bypass -Scope Process -Force
        }
        else {
            Write-Output "[info] ExecutionPolicy is '$ExecutionPolicy', not changing it"
        }
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).path)\..\.."
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
}

function Get-Package {
    param (
        [string] $packageName
    )

    return !(choco list -l $packageName | Select-String "^0 packages installed")
}

function Add-Package {
    param (
        [string] $packageName
    )

    if (Get-Package $packageName) {
        Write-Output "[info] '$packageName' already installed"
    }
    else {
        choco install -y $packageName
    }
}

function Add-Pip-Package {
    param (
        [string] $packageName
    )

    if (Get-Command $packageName -ErrorAction SilentlyContinue) {
        Write-Output "[info] '$packageName' already installed"
    }
    else {
        pip3 install $packageName
    }

}

function Add-VisualStudio {
    param ([string] $vsFlavor)

    $check = choco list -l $vsFlavor | Select-String "^0 packages installed"

    if ($check) {
        $commonParams = "--includeRecommended
                --add Microsoft.Net.Component.4.6.2.TargetingPack
                --add Microsoft.Net.Component.4.6.2.SDK
                --add Microsoft.Net.Component.4.5.TargetingPack
                --add Microsoft.Net.Component.3.5.DeveloperTools"

        if ($vsFlavor -like "visualstudio2019community") {
            $packageParams = "--add Microsoft.VisualStudio.Workload.NativeDesktop
            --add Microsoft.VisualStudio.Workload.CoreEditor
            --add Microsoft.VisualStudio.Workload.ManagedDesktop
            --add Microsoft.VisualStudio.Workload.NativeGame
            --add  Microsoft.VisualStudio.Workload.NetCoreTools"
        }
        else {
            $packageParams = "--add Microsoft.VisualStudio.Workload.VCTools
            --add Microsoft.VisualStudio.Workload.NetCoreBuildTools
            --add Microsoft.VisualStudio.Workload.MSBuildTools"
        }

        choco install -y $vsFlavor -Force --package-parameters "$commonParams $packageParams"
    }
    else {
        Write-Output "[info] '$vsFlavor' already installed"
    }
}

function PromptYesNoWithMessage {
    param(
        [string] $Question,
        [string] $YesMessage,
        [string] $NoMessage
    )

    $ChoiceYes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', $YesMessage
    $ChoiceNo = New-Object System.Management.Automation.Host.ChoiceDescription '&No', $NoMessage
    $choices = $ChoiceYes, $ChoiceNo
    return $Host.UI.PromptForChoice('', $Question, $choices, 0)
}

function Write-Manifest {
    if ($Init) {
        Write-Output "[info] going to install 'chocolatey'"
    }
}

Write-Manifest

$decision = PromptYesNoWithMessage "Do you want to continue?" "Proceed and apply described changes"  "Abort execution"
if ($decision -eq 1) {
    Write-Output "[info] aborting installation, see you !"
    exit
}

if ($Init) {
    Add-Chocolatey
}

if ($Restart) {
    $decision = PromptYesNoWithMessage("You need to reboot to complete setup. Do you want to do it now?", "Restart workstation", "Do not restart, will do it manually")
    if ($decision -eq 0) {
        Restart-Computer
    }
    else {
        Write-Host 'Setup complete. Have fun!'
    }
}
