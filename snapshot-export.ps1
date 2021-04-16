# This script can be used for exporting Snapshots older than a set date to a storage account.
# Will also check if any snaps in storage need to be deleted.

########################################
# Parameters
########################################
param
(
    # If you are performing snapshots in a Azure Government environment, you need to specify the environment.
    # [string]$AzEnvironmentValue = "AzureUSGovernment",
    $resourceGroupName = '<Your Snapshot Resource Group>',
    # $snapshotName = '<Your Snapshot Name>',
    $resourceGroupNameStorageAccount = '<Name of the Resource Group of Destination Storage Account>',
    $storageAccountName = '<Name of Destination Storage Account>',
    $storageContainerName = '<Name of Storage Container in Storage Account for snapshot download>',
    # $destinationVHDFileName = '<Name of the new VHD file of the SnapShot>'
)

$today = (Get-Date -f yyyy-MM-dd)

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
# Export Snapshots older than set time
########################################
$expResList = Get-AzureRmResource -TagName ExportAfter -ResourceType "Microsoft.Compute/snapshots"

# TODO: Export Snapshots as needed and add to lists for later print out.
foreach($expRes in $expResList) {
    $expResIdText = $expRes.ResourceId
    $expTagText = $expRes.Tags["ExportAfter"]
    $expSnapsList = New-Object -TypeName "System.Collections.ArrayList"
    $notExpSnapsList = New-Object -TypeName "System.Collections.ArrayList"
    
    if($expTagText -lt $today){
        # TODO: Export Snapshots whose deletion date has passed.
        Remove-AzureRmResource -ResourceId $expResIdText -Force
        # TODO: Add the exported Snapshots to a exported list for later print out.
    }else{
        # TODO: Add the Snapshots that weren't exported to a Export Later list for later print out.
        Write-Output "$expResIdText should be exported on $expTagText"
    }
}

# TODO: Print out the list of exported Snapshots if any where exported.
if($expSnapsList.Length -gt 0){
    Write-Output "The following Snapshots were exported during this run:"
    foreach($expSnap in $expSnapsList) {
        # TODO: Print out Snapshot names that were exported.
        Write-Output ""
    }
}else{
    Write-Output "No Snapshots were exported during this run."
}

# TODO: Print out the list of Snapshots to be exported later if there are any to be exported later.
if($notExpSnapsList.Length -gt 0){
    Write-Output "The following Snapshots will be exported in the future:"
    foreach($notExpSnap in $notExpSnapsList) {
        Write-Output ""
    }
}else{
    Write-Output "There are currently no Snapshots up for deletion."
}