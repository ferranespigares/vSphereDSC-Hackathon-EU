﻿enum Ensure {
   Absent
   Present
}

$tgtName = 'vEng.local.lab'
$configName = 'Vmw'
 
Configuration $configName
{
    param(
    [System.Management.Automation.PSCredential]$Credential
    )

    Import-DscResource -ModuleName vSphereDSC

    Node $AllNodes.NodeName
    {
        $number = 0
        foreach($folder in $Node.Folders)
        {
            $number++
            $folderName = "Folder$number"
            VmwFolder $folderName
            {
                Name = $folder.FolderName
                Path = $folder.Path
                Ensure = $folder.Ensure
                Type = $folder.Type
                vServer = $Allnodes.Server
                vCredential = $Allnodes.Credential
            }
        }
    }
}

#region VCSA Account
$vcUser = 'administrator@vsphere.local'
$vcPswd = 'Welcome2016!'
$sVcCred = @{
    TypeName = 'System.Management.Automation.PSCredential'
    ArgumentList = $vcUser,(ConvertTo-SecureString -String $vcPswd -AsPlainText -Force)
}
$vcCred = New-Object @sVcCred
#endregion

$ConfigData = @{   
    AllNodes = @(
        @{
            NodeName = '*'
            Server = 'vcsa.local.lab'     
            Credential = $vcCred
            PSDscAllowPlainTextPassword=$true
            PSDscAllowDomainUser = $true
        },
        @{
            NodeName = $configName
            Folders = @(
                @{
                    FolderName = 'Folder1'
                    Path = '/'
                    Type = 'Yellow'
                    Ensure = [Ensure]::Present
                }
#                },
#                @{
#                    FolderName = 'Folder2'
#                    Path = 'Datacenters'
#                    Type = 'Blue'
#                    Ensure = [Ensure]::Present
#                }
            )
        }
    )  
} 

. "$(Split-Path $MyInvocation.MyCommand.Path)\..\..\Tools\Get-TargetGuid.ps1"
$guid = Get-TargetGuid -TargetName $tgtName

Invoke-Expression  "$($configName) -ConfigurationData `$configData -OutputPath '.\DSC'"

$pullShare = '\\pull\DSCService\Configuration\'
$mof = ".\DSC\$($configName).mof"
$tgtMof = "$pullshare\$guid.mof"

Copy-Item -Path $mof -Destination $tgtMof
New-DSCChecksum $tgtMof -Force

# For testing with Start-DscCOnfiguration
Copy-Item -Path $mof -Destination ".\DSC\$($tgtName.Split('.')[0]).mof"
