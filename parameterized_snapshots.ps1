########################################
# Parameters
########################################
param
(
    # If you are performing snapshots in a Azure Government environment, you need to specify the environment.
    # [string]$AzEnvironmentValue = "AzureUSGovernment",
    [string]$SnapFrequency = "No_Value_Provided"    
)

# Set values based on the provided frequency parameter
switch ($SnapFrequency) {
    daily { 
        # $deletionTime = (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
        $frequencyTag = "Daily"
    }
    weekly {
        # $deletionTime = (Get-Date).AddDays(28).ToString('yyyy-MM-dd')
        $frequencyTag = "Weekly"
    }
    hourly {
        # $deletionTime = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
        $frequencyTag = "Hourly"
    }
    default {
        throw "No matching value provided for `$SnapFrequency: $SnapFrequency. Snapshots will not be created."
        break
    }
}

$deletionTime = (Get-Date).AddDays(366).ToString('yyyy-MM-dd')

########################################
# Azure RunAs Connect
########################################
$connectionName = "AzureRunAsConnection"

try{
    $Conn = Get-AutomationConnection -Name $connectionName
    "Logging into Azure..."
    Connect-AzureRmAccount `
        -ServicePrincipal -TenantID $Conn.TenantID `
        -ApplicationId $Conn.ApplicationID `
        -CertificateThumbprint $Conn.CertificateThumbprint `
        # -Environment $AzEnvironmentValue
}
catch{
    if(!$Conn){
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
if($err) {
    throw $err
}

########################################
# Start Snapshot Process
########################################
# Get VMs with Snapshot tag
$tagResList = Get-AzureRmResource -TagName Snapshot -TagValue "True" -ResourceType "Microsoft.Compute/VirtualMachines" | foreach {$_.ResourceId}

foreach($tagRes in $tagResList) {
    $vmInfo = Get-AzureRmVM -ResourceGroupName $tagRes.Split("/")[4] -Name $tagRes.Split("/")[8]

    # Get list of tags on the VM and set them to a variable
    $vmTags = (Get-AzureRmVM -ResourceGroupName $tagRes.Split("/")[4] -Name $tagRes.Split("/")[8]).Tags

    # Update Snapshot Key/Value pair to False so we don't accidentally try to snapshot snapshots later.
    $vmTags.set_Item("Snapshot", "False")

    # Add the Deletion Date tag table
    "Setting Deletion Date for Snapshots to $deletionTime."
    $vmTags.Add('DeleteAfter', $deletionTime)

    "Updating Managed By tag for Snapshots to Automation Runbook."

    if ($vmTags.ContainsKey("Managed By"))
    {
        $vmTags.set_Item("Managed By", "Automation Runbook")
        Write-Output "Managed By tag successfully updated to Automation Runbook."
    }
    else
    {
        $vmTags.Add("Managed By", "Automation Runbook")
        Write-Output "Managed By tag successfully added, and set to Automation Runbook."
    }

    # Set local variables
    $location = $vmInfo.Location
    $resourceGroupName = $vmInfo.ResourceGroupName
    $timestamp = (Get-Date -f yyyy-MM-dd-HH-mm-ss)

    # Snapshot name of OS data disk
    $snapshotName = $vmInfo.Name + "-" + $frequencyTag + "-at-" + $timestamp

    # TODO: Check if OS disk has relevant SnapFrequency tag first before snapshotting it.
    # Create snapshot configuration
    $snapshot = New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy -Tag $vmTags
    
    # Take snapshot
    New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

    # TODO: Check if storage disk has relevant SnapFrequency tag first before snapshotting it.
    if($vmInfo.StorageProfile.DataDisks.Count -ge 1){
        # Condition with more than one data disks
        for($i=0; $i -le $vmInfo.StorageProfile.DataDisks.Count - 1; $i++){
            # Snapshot name of OS data disk
            $snapshotName = $vmInfo.StorageProfile.DataDisks[$i].Name + "-" + $frequencyTag + "-at-" + $timestamp

            # Create snapshot configuration
            $snapshot = New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $location -CreateOption copy -Tag $vmTags

            # Take snapshot
            New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName
        }
    }
    else{
        $vmInfoName = $vmInfo.Name
        Write-Output "$vmInfoName doesn't have any additional data disk."
    }
}

########################################
# Delete Snapshots older than set time
# Checks if deletion date has passed.
########################################
$delResList = Get-AzureRmResource -TagName DeleteAfter -ResourceType "Microsoft.Compute/snapshots"
$today = (Get-Date -f yyyy-MM-dd)

foreach($delRes in $delResList) {
    $delResIdText = $delRes.ResourceId
    $delTagText = $delRes.Tags["DeleteAfter"]
    
    if($delTagText -lt $today){
        Remove-AzureRmResource -ResourceId $delResIdText -Force
        Write-Output "$delResIdText has been deleted."
    }else{
        Write-Output "$delResIdText should be deleted on $delTagText"
    }
}