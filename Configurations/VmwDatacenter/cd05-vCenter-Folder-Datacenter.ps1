$tgtName = 'vEng.local.lab'
$configName = 'vmw'

$vcUser = 'administrator@vsphere.local'
$vcPswd = 'Welcome2016!'
$sVcCred = @{
    TypeName = 'System.Management.Automation.PSCredential'
    ArgumentList = $vcUser,(ConvertTo-SecureString -String $vcPswd -AsPlainText -Force)
}
$vcCred = New-Object @sVcCred

Configuration vmw
{
    param(
    [System.Management.Automation.PSCredential]$Credential
    )

    Import-DscResource -ModuleName vSphereDSC
    
    Node vmw
    {
        VmwDatacenter DC1
        {
            Name = 'DC1'
            Path = '/'
            Ensure = [Ensure]::Present
            vServer = 'vcsa.local.lab'
            vCredential = $vcCred
        }

        VmwFolder Folder1
        {
            Name = 'Folder1'
            Path = '/'
            Ensure = [Ensure]::Present
            Type = 'Yellow'
            vServer = 'vcsa.local.lab'
            vCredential = $vcCred
        }
    }
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
