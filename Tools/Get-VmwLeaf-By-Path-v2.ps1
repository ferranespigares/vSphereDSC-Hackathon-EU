function Get-VIObjectByPath{
<#
.SYNOPSIS
  Retrieve a vSphere object by it's path.
.DESCRIPTION
  This function will retrieve a vSphere object from it's path.
  The path can be absolute or relative.
  When a relative path is provided, the StartNode needs
  to be provided
.NOTES
  Author:  Luc Dekens
.PARAMETER StartNode
  The vSphere Server (vCenter or ESXi) from which to retrieve
  the objects.
  The default is $Global:DefaultVIServer
.PARAMETER Path
  A string with the absolute or relative path.
  The path shall not contain any hidden folders.
.EXAMPLE
  PS> Get-VIObjectByPath -Path '/Datacenter/Folder/VM1'
.EXAMPLE
  PS> Get-InventoryPlus -StartNode $node -Path $path
#>

  param(
    [VMware.Vim.ManagedEntity]$StartNode = (
      Get-View -Id (Get-View -Id ServiceInstance).Content.RootFolder
    ),
    [String]$Path
  )

  function Get-NodeChild{
    param(
      [VMware.Vim.ManagedEntity]$Node
    )
  
    $hidden = 'vm','host','network','datastore','Resources'
    switch($Node){
      {$_ -is [VMware.Vim.Folder]}{
        if($Node.ChildEntity){
          Get-View -Id $Node.ChildEntity
        }
      }
      {$_ -is [VMware.Vim.Datacenter]}{
        $all = @()
        $all += Get-View -Id $Node.VmFolder
        $all += Get-View -Id $Node.HostFolder
        $all += Get-View -Id $Node.DatastoreFolder
        $all += Get-View -Id $Node.NetworkFolder
        $all | %{
          if($hidden -contains $_.Name){
            Get-NodeChild -Node $_
          }
          else{
            $_
          }
        }
      }
      {$_ -is [VMware.Vim.ClusterComputeResource]}{
        $all = @()
        $all += Get-View -Id $Node.Host
        $all += Get-View -Id $Node.ResourcePool 
        $all = $all | %{
          if($hidden -contains $_.Name){
            Get-NodeChild -Node $_
          }
          else{
            $_
          }
        }
        $all
      }
      {$_ -is [VMware.Vim.ResourcePool]}{
        $all = @()
        if($Node.ResourcePool){
          $all += Get-View -Id $Node.ResourcePool
        }
        if($Node.vm){
          $all += Get-View -Id $Node.vm
        }
        $all
      }
      {$_ -is [VMware.Vim.DistributedVirtualSwitch]}{
        Get-View -Id $Node.Portgroup
      }
    }
  }

  $found = $true

  # Loop through Path
  $node = $StartNode
  foreach($qualifier in $Path.TrimStart('/').Split('/',[StringSplitOptions]::RemoveEmptyEntries)){
    $nodeMatch = @($node) | %{
      Get-NodeChild -Node $_ | where{$_.Name -eq $qualifier}
    }
    if(!$nodeMatch){
      $found = $false
      $node = $null
      break
    }
    $node = $nodeMatch
  }

  New-Object PSObject -Property @{
    Path = $Path
    Found = $found
    Node = $node
  }
}

function Test-NodePath{
    param(
        [String]$Path
    )

    $nodeObj = Get-VIObjectByPath -Path $Path
    if($nodeObj.Found){$true}else{$false}
}

foreach($entry in (Import-Csv C:\Temp\inventory.csv -UseCulture)){
    $path = $entry.Path

    Write-Host "$($Entry.Type) $($entry.Name)"

    if($entry.Path -ne 'na'){
        Write-Host -ForegroundColor Yellow "`tPath " -NoNewline
        Write-Host "$($Entry.Path)" -NoNewline

        if(Test-NodePath -Path $entry.Path){
            Write-Host -ForegroundColor Green "`tok"
        }
        else{
            Write-Host -ForegroundColor Yellow "`tnok"
        }
    }

    if($entry.BluePath -ne 'na'){
        Write-Host -ForegroundColor Cyan "`tBluePath " -NoNewline
        Write-Host "$($Entry.BluePath)" -NoNewline
    
        if(Test-NodePath -StartNode $rootFolder -Path $entry.BluePath){
            Write-Host -ForegroundColor Green "`tok"
        }
        else{
            Write-Host -ForegroundColor Yellow "`tnok"
        }
    }
}