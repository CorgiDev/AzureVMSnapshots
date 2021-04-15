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
# Export Snapshots older than set time
########################################
$delResList = Get-AzureRmResource -TagName DeleteAfter -ResourceType "Microsoft.Compute/snapshots"

# Export Snapshots and add them to one of 2 lists for later print out.
foreach($delRes in $delResList) {
    $delResIdText = $delRes.ResourceId
    $delTagText = $delRes.Tags["DeleteAfter"]
    
    if($delTagText -lt $today){
        # TODO: Export Snapshots and 
        # TODO: Add to export list
        Write-Output "$delResIdText has been deleted."
    }else{
        # TODO: Add to export later list
        Write-Output "$delResIdText should be deleted on $delTagText"
    }
}

foreach($delRes in $delResList) {
    $delResIdText = $delRes.ResourceId
    $delTagText = $delRes.Tags["DeleteAfter"]
    
    if($delTagText -lt $today){
        # TODO: Print out list of exported Snapshots and their location they were exported to.
        Remove-AzureRmResource -ResourceId $delResIdText -Force
        Write-Output "$delResIdText has been deleted."
    }else{
        # TODO: Print out list of Snapshots to be exported later and their export date.
        Write-Output "$delResIdText should be deleted on $delTagText"
    }
}