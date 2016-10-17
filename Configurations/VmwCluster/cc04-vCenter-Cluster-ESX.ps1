﻿enum Ensure {
   Absent
   Present
}

$tgtName = 'vEng.local.lab'
$configName = 'vmw'
 
Configuration $configName
{
    param(
    [System.Management.Automation.PSCredential]$Credential
    )

    Import-DscResource -ModuleName vSphereDSC

    Node $AllNodes.NodeName
    {
        $number = 0
        foreach($cluster in $Node.Cluster)
        {
            $number++
            $clusterName = "Cluster$number"
            VmwCluster $clusterName
            {
                Name = $cluster.ClusterName
                Path = $cluster.Path
                Ensure = $cluster.Ensure
                HA = $cluster.HA
                DRS = $cluster.DRS
                DPM = $cluster.DPM
                VSAN = $cluster.VSAN
                vServer = $Allnodes.Server
                vCredential = $Allnodes.Credential
            }
        }
        $number = 0
        foreach($esx in $Node.VMHost)
        {
            $number++
            $esxName = "ESXi$number"
            VmwVMHost $esxName
            {
                Name = $esx.VMHostName
                Path = $esx.Path
                License = $esx.License
                Ensure = $esx.Ensure
                MaintenanceMode = $esx.MainteneceMode
                eCredential = $esx.eCredential
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

#region ESXi Account
$esxUser = 'root'
$esxPswd = 'Welcome2016'
$sEsxCred = @{
    TypeName = 'System.Management.Automation.PSCredential'
    ArgumentList = $esxUser,(ConvertTo-SecureString -String $esxPswd -AsPlainText -Force)
}
$esxCred = New-Object @sEsxCred
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
            Cluster = @(
                @{
                    ClusterName = 'Cluster1'
                    Path = '/Homelab'
                    Ensure = [Ensure]::Present
                    HA = $true
                    DRS = $true
                    DPM = $false
                    VSAN = $false
                },
                @{
                    ClusterName = 'Cluster2'
                    Path = '/Homelab'
                    Ensure = [Ensure]::Present
                    HA = $false
                    DRS = $false
                    DPM = $false
                    VSAN = $false
                }
            )
            VMHost = @(
                @{
                    VMHostName = 'esx1.local.lab'
                    Path = '/Homelab/Cluster1'
                    License = 'X56A1-J0JA8-P8C9J-0CEKH-1RLMN'
                    Ensure = [Ensure]::Present
                    MaintenanceMode = $false
                    eCredential = $esxCred
                }
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
