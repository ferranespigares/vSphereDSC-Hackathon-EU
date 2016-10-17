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
            VSS = @(
                @{
                    Name = 'VSS1'
                    Path = '/DC1/Cluster1'
                    Ensure = [Ensure]::Present
                    MTU = 1500
                    NumberOfPorts = 120
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
