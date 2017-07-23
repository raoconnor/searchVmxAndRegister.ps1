# Search for all VMX files in all datastores and register them into VC
# VMX Raiders Revisited by LucD

# Introduction
Write-Host "----------------------------------------------------------------------------------------------------------------" 
Write-Host "This script will automatic search for all VMX files in all datastores and register them into the virtual center "
Write-Host "----------------------------------------------------------------------------------------------------------------" 
Write-Host "" 


# Set the variables to register the vms
Write-Host "Set the following to register the vms"
$Cluster = Read-Host "Enter Cluster name" 
$Datastores = Read-Host "Enter datastore name" 
$VMFolder = "Discovered virtual machine" 
 
$ESXHost = Get-Cluster $Cluster | Get-VMHost | select -First 1
 
foreach($Datastore in Get-Datastore $Datastores) {
  # Collect .vmx paths of registered VMs on the datastore
  $registered = @{}
  Get-VM -Datastore $Datastore | %{$_.Extensiondata.LayoutEx.File | where {$_.Name -like "*.vmx"} | %{$registered.Add($_.Name,$true)}}
 
   # Set up Search for .VMX Files in Datastore
  New-PSDrive -Name TgtDS -Location $Datastore -PSProvider VimDatastore -Root '\' | Out-Null
  $unregistered = @(Get-ChildItem -Path TgtDS: -Recurse| where {$_.FolderPath -notmatch ".snapshot" -and $_.Name -like "*.vmx" -and !$registered.ContainsKey($_.Name)}) 
  Remove-PSDrive -Name TgtDS
 
   #Register all .vmx Files as VMs on the datastore
   foreach($VMXFile in $unregistered) {
      New-VM -VMFilePath $VMXFile.DatastoreFullPath -VMHost $ESXHost -Location $VMFolder -RunAsync
   }
}