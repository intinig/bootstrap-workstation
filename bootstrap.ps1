param (
    [switch] $Init = $false,
    [switch] $Restart = $false,
    [switch] $BaseSystem = $false,
    [switch] $Extras = $false,
    [string] $Browser = "firefox",
    [string] $VisualStudioFlavor = "buildtools",
    [switch] $DisableVisualStudio = $false,
    [switch] $Games = $false
)

function Get-SelectedActions {
    return (((($Init -or $BaseSystem) -or $Extras) -or $Games) -or (-Not $DisableVisualStudio))
}

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

function Write-ManifestOutput {
    param(
        [string] $Package
    )

    Write-Output "[info] going to install '$Package'"
}
function Write-Manifest {
    if ($Init) {
        Write-ManifestOutput("chocolatey")
    }

    if (-Not $DisableVisualStudio) {
        if ($VisualStudioFlavor -eq "buildtools") {
            Write-ManifestOutput("Visual Studio Build Tools 2019")
        }
        else {
            Write-ManifestOutput("Visual Studio Community 2019")
        }
    }
    if ($BaseSystem) {
        Write-ManifestOutput($Browser)
        Write-ManifestOutput("slack")
        Write-ManifestOutput("git")
    }

    if ($Extras) {
        Write-ManifestOutput("discord")
        Write-ManifestOutput("vlc")
        Write-ManifestOutput("gimp")
        Write-ManifestOutput("obs-sudio")
        Write-ManifestOutput("openshot")
        Write-ManifestOutput("powershell-core")
    }

    if ($Extras) {
        Write-ManifestOutput("steam")
    }
}

if (Get-SelectedActions) {
    Write-Manifest

    $decision = PromptYesNoWithMessage "Do you want to continue?" "Proceed and apply described changes"  "Abort execution"
    if ($decision -eq 1) {
        Write-Output "[info] aborting installation, see you !"
        exit
    }

    if ($Init) {
        Add-Chocolatey
    }

    if ($BaseSystem) {
        Add-Package($Browser)
        Add-Package("slack")
        Add-Package("git")
    }

    if (-Not $DisableVisualStudio) {
        if ($VisualStudioFlavor -eq "buildtools") {
            Add-VisualStudio "visualstudio2019buildtools"
        }
        else {
            Add-VisualStudio "visualstudio2019community"
        }
    }

    if ($Extras) {
        Add-Package("steam")
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
}
