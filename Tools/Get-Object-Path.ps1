function Get-InventoryPlus
{
    [cmdletbinding()]
    param(
        [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server = $Global:DefaultVIServer,
        [String]$NoValue = ''
    )

    function Get-ViBlueFolderPath{
        [cmdletbinding()]
        param(
            [VMware.Vim.ManagedEntity]$Item
        )
    
        $hidden = 'Datacenters','vm'
        
        if($Item -is [VMware.Vim.VirtualMachine]){
            $Item.UpdateViewData('Parent')
            $parent = $Item.Parent    
        }
        elseif($Item -is [VMware.Vim.VirtualApp]){
            $Item.UpdateViewData('ParentFolder')
            $parent = $Item.ParentFolder
        }
    
        if($parent){
            $path = @($Item.Name)
            while($parent){
                $object = Get-View -Id $parent -Property Name,Parent
                if($hidden -notcontains $object.Name){
                    $path += $object.Name
                }
                if($object -is [VMware.Vim.VirtualApp]){
                    $object.UpdateViewData('ParentFolder')
                    if($object.ParentFolder){
                        $parent = $object.ParentFolder
                    }
                    else{
                        $object.UpdateViewData('ParentVapp')
                        if($object.ParentVapp){
                            $parent = $object.ParentVapp
                        }
                    }
                }
                else{
                    $parent = $object.Parent
                }
            }
            [array]::Reverse($path)
            return "/$($path -join '/')"
        }
        else{
            return $NoValue
        }
    }
    
    function Get-ObjectInfo{
        [cmdletbinding()]
        param(
            [parameter(ValueFromPipeline)]
            [VMware.Vim.ManagedEntity]$Object
        )
    
        Begin{
            $hidden = 'Datacenters','vm','host','network','datastore','Resources'
        }
            
        Process{
            if($hidden -notcontains $Object.Name){
                $props = [ordered]@{
                    Name = $Object.Name
                    Type = $Object.GetType().Name
                    BluePath = $NoValue
                }
                $blueFolder = $false
                $isTemplate = $false
                if($object -is [VMware.Vim.Folder]){
                    $object.UpdateViewData('ChildType')
                    if($Object.ChildType -contains 'VirtualMachine'){
                        $blueFolder = $true
                    }
                }
                $path = @($Object.Name)
                $parent = $Object.Parent
    
                if($object -is [VMware.Vim.VirtualMachine] -or $object -is [VMware.Vim.VirtualApp]){
                    $props['BluePath'] = Get-VIBlueFolderPath -Item $Object
                    if($Object -is [VMware.Vim.VirtualMachine]){
                        $Object.UpdateViewData('ResourcePool','Config.Template')
                        if($Object.Config.Template){
                            $parent = $Object.Parent
                            $props['Type'] = 'Template'
                            $isTemplate = $true
                        }
                        else{
                            $parent = $Object.ResourcePool
                        }
                    }
                }
                while($parent){
                    $Object = Get-View -Id $Parent -Property Name,Parent
                    $parent = $Object.Parent
                    if($hidden -notcontains $Object.Name){
                        $path += $Object.Name
                    }
                }
                [array]::Reverse($path)
                $path = "/$($path -join '/')"
                $props.Add('Path',$path)
    
                if($blueFolder){
                    $props['BluePath'] = $props['Path']
                    $props['Path'] = $NoValue                
                }       
                if($isTemplate){
                    $props['Path'] = $NoValue
                }
                New-Object PSObject -Property $props
            }
        }
    }
    
    $sView = @{
        Id = 'ServiceInstance'
        Server = $Server
        Property = 'Content.ViewManager','Content.RootFolder'
    }
    $si = Get-view @sView
    $viewMgr = Get-View -Id $si.Content.ViewManager
    
    $contView = $viewMgr.CreateContainerView($si.Content.RootFolder,$null,$true)
    $contViewObj = Get-View -Id $contView
    
    Get-View -Id $contViewObj.View -Property Name,Parent | 
    where{$hidden -notcontains $_.Name} | 
    Get-ObjectInfo
}

Get-InventoryPlus -NoValue 'na' | 
Export-Csv -Path c:\Temp\inventory.csv -NoTypeInformation -UseCulture
