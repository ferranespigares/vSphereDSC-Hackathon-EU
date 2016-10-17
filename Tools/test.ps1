$Esx = get-vmhost esx1.local.lab | get-view

        $Esx.UpdateViewData('ConfigManager.NetworkSystem')
        $netSystem = Get-View -Id $Esx.ConfigManager.NetworkSystem
        
        $spec = New-Object VMware.Vim.HostVirtualSwitchSpec
        $spec.Mtu = $MTU
        $spec.numPorts = $NumberOfPorts
        $spec.Policy = New-Object VMware.Vim.HostNetworkPolicy
        if($ANic -or $SNic){
            $spec.Policy.NicTeaming = New-Object VMware.Vim.HostNicTeamingPolicy
            $spec.Policy.NicTeaming.NicOrder = New-Object VMware.Vim.HostNicOrderPolicy
            # When Nic Teaming is used, the Bridge needs to be defined as well
            $spec.Bridge = New-Object VMware.Vim.HostVirtualSwitchBondBridge

            if($ANic){
                  $spec.Policy.NicTeaming.NicOrder.activeNic = $ANic
                  $spec.Bridge.NicDevice += $ANic
            }
            if($SNic){
                  $spec.Policy.NicTeaming.NicOrder.standbyNic = $SNic
                  $spec.Bridge.NicDevice += $SNic
            }
        }
