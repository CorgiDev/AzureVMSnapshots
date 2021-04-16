# This script can be used for deleting Snapshots older than a set date.
# This is used if you do not use the export script since it will only delete from the main set of resources and not from the storage account.

########################################
# Parameters
########################################
param
(
    # If you are performing snapshots in a Azure Government environment, you need to specify the environment.
    # [string]$AzEnvironmentValue = "AzureUSGovernment", 
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
# Delete Snapshots older than set time
# Checks if deletion date has passed.
########################################
$delResList = Get-AzureRmResource -TagName DeleteAfter -ResourceType "Microsoft.Compute/snapshots"

# TODO: Delete Snapshots as needed and add to lists for later print out.
foreach($delRes in $delResList) {
    $delResIdText = $delRes.ResourceId
    $delTagText = $delRes.Tags["DeleteAfter"]
    $delSnapsList = New-Object -TypeName "System.Collections.ArrayList"
    $notDelSnapsList = New-Object -TypeName "System.Collections.ArrayList"
    
    if($delTagText -lt $today){
        Remove-AzureRmResource -ResourceId $delResIdText -Force
        $delSnapsList.Add($delResIdText)

    }else{
        $notDelText = "$delResIdText ($delTagText)"
        $notDelSnapsList.Add($notDelText)
    }
}

# TODO: Print out the list of deleted Snapshots if any where deleted.
if($delSnapsList.Length -gt 0){
    Write-Output "The following Snapshots were deleted during this run:"
    foreach($delSnap in $delSnapsList) {
        # TODO: Print out Snapshot names that were deleted.
        Write-Output $delSnap
    }
}else{
    Write-Output "No Snapshots were deleted during this run."
}

# TODO: Print out the list of Snapshots to be deleted later if there are any to be deleted later.
if($notDelSnapsList.Length -gt 0){
    Write-Output "The following Snapshots will be deleted in the future:"
    foreach($notDelSnap in $notDelSnapsList) {
        Write-Output $notDelSnap
    }
}else{
    Write-Output "There are currently no Snapshots up for deletion."
}