enum Ensure {
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
        foreach($folder in $Node.Folder)
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
                DependsOn = $folder.DependsOn
            }
        }

        $number = 0
        foreach($datacenter in $Node.Datacenter)
        {
            $number++
            $dcName = "Datacenter$number"
            VmwDatacenter $dcName
            {
                Name = $datacenter.DatacenterName
                Path = $datacenter.Path
                Ensure = $datacenter.Ensure
                vServer = $Allnodes.Server
                vCredential = $Allnodes.Credential
                DependsOn = $datacenter.DependsOn
            }
        }

        $number = 0
        foreach($datastore in $Node.Datastore)
        {
            $number++
            $dsName = "Datastore$number"
            VmwDatastore $dsName
            {
                Name = $datastore.Name
                Path = $datastore.Path
                Ensure = $datastore.Ensure
                vServer = $Allnodes.Server
                vCredential = $Allnodes.Credential
                DependsOn = $datastore.DependsOn
            }
        }

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
                DependsOn = $cluster.DependsOn
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
                DependsOn = $esx.DependsOn
            }
        }

        $number = 0
        foreach($vss in $Node.VSS)
        {
            $number++
            $vssName = "VSS$number"
            VmwVSS $vssName
            {
                Name = $vss.Name
                Path = $vss.Path
                MTU = $vss.MTU
                NumberOfPorts = $vss.NumberOfPorts
                Ensure = $vss.Ensure
                vServer = $Allnodes.Server
                vCredential = $Allnodes.Credential
                DependsOn = $vss.DependsOn
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
            Folder = @(
                @{
                    FolderName = 'Homelab'
                    Path = '/'
                    Type = 'Yellow'
                    Ensure = [Ensure]::Present
                }
            )
            Datacenter = @(
                @{
                    DatacenterName = 'DC1'
                    Path = '/Homelab'
                    Ensure = [Ensure]::Present
                    DependsOn = '[VmwFolder]Folder1'                 }
            )
            Cluster = @(
                @{
                    ClusterName = 'Cluster1'
                    Path = '/Homelab/DC1'
                    Ensure = [Ensure]::Present
                    HA = $true
                    DRS = $true
                    DPM = $false
                    VSAN = $false
                    DependsOn = '[VmwDatacenter]Datacenter1'
                }
            )
            VMHost = @(
                @{
                    VMHostName = 'esx1.local.lab'
                    Path = '/HomeLab/DC1/Cluster1'
                    License = 'X56A1-J0JA8-P8C9J-0CEKH-1RLMN'
                    Ensure = [Ensure]::Present
                    MaintenanceMode = $true
                    eCredential = $esxCred
                    DependsOn = '[VmwCluster]Cluster1'
                },
                @{
                    VMHostName = 'esx2.local.lab'
                    Path = '/HomeLab/DC1/Cluster1'
                    License = 'X56A1-J0JA8-P8C9J-0CEKH-1RLMN'
                    Ensure = [Ensure]::Present
                    MaintenanceMode = $true
                    eCredential = $esxCred
                    DependsOn = '[VmwCluster]Cluster1'
                }
            )
            VSS = @(
                @{
                    Name = 'VSS1'
                    Path = '/Homelab/DC1/Cluster1'
                    Ensure = [Ensure]::Present
                    MTU = 1500
                    NumberOfPorts = 128
                    DependsOn = '[VmwCluster]Cluster1'
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
