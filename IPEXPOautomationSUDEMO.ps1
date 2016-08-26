# IP-EXPO Virtual 2012R2 Machine Azure PowerShell Build Script
# James Pearse - SystemsUp (25/08/16)

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS VM Creation Demo Starting."

# Next we create the Script variables 

    $VerbosePreference="Continue"

## Global
 
    $rgname = "IP-EXPO-SUDEMO"
    $region = "West Europe"
    $subscription = "Developer Program Benefit"

## Storage

    $storageName = "ipexposuvmstoragelrsdemo" ## Must be globally unique and all lowercase
    $storageType = "Standard_LRS"

## Network

    $nicname = "IPEXPOVM-NIC"
    $subnet1Name = "ipexposubnet1"
    $vnetName = "IP-EXPO-VNET"
    $vnetAddressPrefix = "10.0.0.0/16"
    $vnetSubnetAddressPrefix = "10.0.1.0/24"
    $publicipname = "ipexpopip"
    $allocationMethod = "Dynamic" ### Dynamic or Static
    $ipdomain = "ipexpotest"

## Compute

    $vmName = "IP-EXPO-VM"
    $computerName = "IP-EXPO-VM"
    $vmSize = "Standard_A3"
    
###########################################################
#Do Not Edit Below This Point                             #
###########################################################

# Login to Azure RM
 
Login-AzureRMAccount

# Select Subscription

Select-AzureRmSubscription -SubscriptionName $subscription

# Create a new Resource Group

New-AzureRmResourceGroup -Name $rgname -Location $region 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO Azure Resource Group Created."

# Create a new Subnet for the Virtual machine

$newSubnetParams = @{
'Name' = $subnet1Name
'AddressPrefix' = $vnetSubnetAddressPrefix
}
$subnet = New-AzureRmVirtualNetworkSubnetConfig @newSubnetParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Subnet Created."

# Create a new Virtual Network for the subnet

$newVNetParams = @{
'Name' = $vnetname
'ResourceGroupName' = $rgname
'Location' = $region
'AddressPrefix' = $vnetAddressPrefix
}
$vNet = New-AzureRmVirtualNetwork @newVNetParams -Subnet $subnet 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Network Created."

# Create Storage account

$newStorageAcctParams = @{
'Name' = $storageName 
'ResourceGroupName' = $rgname
'Type' = $storageType
'Location' = $region
}
$storageAccount = New-AzureRmStorageAccount @newStorageAcctParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine LRS Storage Account Created."

# Next create a public IP Address

$newPublicIpParams = @{
'Name' = $publicipname
'ResourceGroupName' = $rgname
'AllocationMethod' = $allocationMethod
'DomainNameLabel' = $ipdomain
'Location' = $region
}
$publicIp = New-AzureRmPublicIpAddress @newPublicIpParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Public IP Address Created."

# Next create a network interface

$newVNicParams = @{
'Name' = $nicName
'ResourceGroupName' = $rgname
'Location' = $region
'SubnetId' = $vNet.Subnets[0].Id
'PublicIpAddressId' = $publicIp.Id
}
$vNic = New-AzureRmNetworkInterface @newVNicParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Network Interface Created."

# Next specify the performance of the VM

$newConfigParams = @{
'VMName' = $vmName
'VMSize' = $vmSize
}
$vmConfig = New-AzureRmVMConfig @newConfigParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Instance Size Selected Succesfully."

# Next create the OS

$newVmOsParams = @{
'Windows' = $true
'ComputerName' = $computerName
'Credential' = (Get-Credential -Message 'Type the name and password of the local administrator account.')
'ProvisionVMAgent' = $true
'EnableAutoUpdate' = $true
}
$vm = Set-AzureRmVMOperatingSystem @newVmOsParams -VM $vmConfig 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine OS Created."

# Next we select the OS (marketplace)

$newSourceImageParams = @{
'PublisherName' = 'MicrosoftWindowsServer'
'Version' = 'latest'
'Skus' = '2012-R2-Datacenter'
'VM' = $vm
}
 
$offer = Get-AzureRmVMImageOffer -Location $region -PublisherName 'MicrosoftWindowsServer'
 
$vm = Set-AzureRmVMSourceImage @newSourceImageParams -Offer $offer.Offer

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine OS Specified."

# Next we connect the NIC created previously 

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $vNic.Id

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine Network Interface Connected."

# Next we create the OS Disk

$osDiskName = "myDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $osDiskName + ".vhd"
 
$newOsDiskParams = @{
'Name' = 'OSDisk'
'CreateOption' = 'fromImage'

}
 
$vm = Set-AzureRmVMOSDisk @newOsDiskParams -VM $vm -VhdUri $osDiskUri

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS Virtual Machine OS Disk Created."

# Next we create the virtual machine

$newVmParams = @{
'ResourceGroupName' = $rgname
'Location' = $region
'VM' = $vm
}
New-AzureRmVM @newVmParams 

Write-Output "$(Get-Date –f $timeStampFormat) - IP-EXPO IaaS VM Creation Demo Completed."





























