# Configure LCM on vEng
#
# Tested platform:
# Windows 2012 R2
# PowerShell v5 Production Preview
#
# Runs on WS1, MOF will be pushed to vEng.local.lab

[DSCLocalConfigurationManager()]
configuration vEngLCMConfig
{
    param($ComputerName,$Guid)

    Node $ComputerName
    {
        Settings
        {
            ConfigurationID = $Guid
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded = $true
#            DebugMode = 'All'
        }

        ConfigurationRepositoryWeb PullSrv
        {
            AllowUnsecureConnection = $true
            ServerURL = 'http://pull.local.lab:8080/PSDSCPullServer.svc'
#            RegistrationKey = 'eb6a3083-8746-4542-a28b-c012fb293312'
#            ConfigurationNames = @('PowerCLI')

        }

#        ReportServerWeb ReportSrv
#        {
#            ServerURL               = 'http://pull.local.lab:9080/PSDSCReportServer.svc'
#            RegistrationKey         = 'eb6a3083-8746-4542-a28b-c012fb293312'
#            AllowUnsecureConnection = $true
#        }
        
#        PartialConfiguration PowerCLI
#        {
#            Description = 'Install PowerCLI'
#            ConfigurationSource = '[ConfigurationRepositoryWeb]PullSrv'
#            RefreshMode = 'Pull'
#        }     
#
#        PartialConfiguration Folder
#        {
#            Description = 'Folders'
#            ConfigurationSource = '[ConfigurationRepositoryWeb]PullSrv'
#            DependsOn = '[PartialConfiguration]PowerCLI'
#            RefreshMode = 'Pull'
#        }     

#        PartialConfiguration Datacenter
#        {
#            Description = 'Define Datacenter and Folders'
#            ConfigurationSource = '[ConfigurationRepositoryWeb]PullSrv'
#            DependsOn = '[PartialConfiguration]PowerCLI'
#            RefreshMode = 'Pull'
#        }     
#
#        PartialConfiguration Cluster
#        {
#            Description = 'Configure Cluster'
#            ConfigurationSource = '[ConfigurationRepositoryWeb]PullSrv'
#            DependsOn = '[PartialConfiguration]Datacenter'
#            RefreshMode = 'Pull'
#        }     

    }
}

$tgtName = 'vEng.local.lab'

. "$(Split-Path $MyInvocation.MyCommand.Path)\Get-TargetGuid.ps1"
$guid = Get-TargetGuid -TargetName $tgtName

vEngLCMConfig -ComputerName $tgtName -Guid $guid -OutputPath '.\LCM'
Set-DSCLocalConfigurationManager –Computer vEng.local.lab -Path '.\LCM' –Verbose
