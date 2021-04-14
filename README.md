# AzureVMSnapshots
Create snapshots of Azure VM disks on a schedule using Azure Runbooks.

## Runbooks

### Module Requirements

The Powershell modules listed below are required for the Runbooks included here to function, and will most likely need to be imported. The list contains the names for the `Az` versions and their matching `AzureRM` version name.

- Az.Accounts / AzureRm.Profile
- Az.Compute / AzureRm.Compute
- Az.Resources / AzureRm.Resources

**NOTE:** Currently, my script uses AzureRM. I will create a second copy that uses the Az equivalents at a later date, but will keep the AzureRM version in case you currently do not have the Az modules imported.

### Module Import

The necessary modules can be imported by:

1. Going to the **Automation Account** containing the relevant Runbooks in Azure.
2. Scroll down to the  **Shared Resources** section.
3. Select the **Modules Gallery** link.
4. Search for the module you wish to import and select it from the results.
5. Click **Import** in the window displays.

### RunAs Account Notes

When you connect with the RunAs account in your Runbook within a Azure Gov environment, you have to add an additional parameter to the connection to specify what Gov environment it is. Otherwise the connection won't work right.

```powershell
-Environment AzureUSGovernment
```
If you are connecting to a regular consumer Azure instance, you do not need this `Environment` parameter.

## Snapshots

From [Azure's documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/incremental-snapshots),

>A blob snapshot is a read-only version of a blob that is captured at a point in time. Once a snapshot has been created, it can be read, copied, or deleted, but not modified. Snapshots provide a way to back up a blob as it appears at a moment in time. Until REST version 2015-04-05, you had the ability to copy full snapshots. With the REST version 2015-07-08 and above, you can also copy incremental snapshots.

Snapshots make restoring a backup faster and/or allow you to quickly examine a point-in-time by attaching to a VM. However, they should not be treated as a main backup/recovery option. Instead, *File-Level Backups* should be used for true backup/recovery. If you would like to learn more about the differences between *Snapshots* and *File-Level Backups*, check out the *[Backup vs Snapshot: What's the difference?](https://blog.sepusa.com/snapshots-vs-backups)* article by SEP Software.

An important note on Snapshots, you can **ONLY** make a full Snapshot of a Managed Disk. A VM might have several Managed Disks attached to it. It will have at least one for the OS disk, but may have more. You can learn more 

### How long to keep Snapshots?

Keeping lots of Snapshots can significantly increase Azure spend. So it is recommended that they only be kept for a limited amount of time. 

- *hourly_snapshots.ps1* : Hourly snapshots will be kept for **24 hours**.
  - *Not currently implemented.*
- *daily_snapshots.ps1* : Daily snapshots will be kept for **5 days**.
  - *Not currently implemented.*
- *weekly_snapshots.ps1* : Weekly snapshots will be kept for **4 weeks**.

### Tagging for Snapshots

Make sure any VMs and their respective disks that you want Snapshots of have the `Snapshot : True` tag. Also make sure that any kind of Terraform or Ansible scripts you have that create those resources have that tagging reflected in them if you manually apply the tags. That way you do not accidentally destroy any resources.

After a new snapshot is created, it should be tagged with `Delete After : <date>` with the `<date>` being based on the type of snapshot taken.

## File-Level Backups

File-level backs up are a more true backup solution, and should be implemented as well in addition to Snapshots.

### How long to keep Backups

## Resources

- [Starwind Software - Automating Disk Snapshots using Azure Runbook](https://www.starwindsoftware.com/blog/automating-disk-snapshots-using-azure-runbook)
- [Automate Disk Snapshots in Azure](https://medium.com/techmanyu/automate-disk-snapshots-in-azure-ed2599aaa8e1)
- [Using Azure Automation to create a snapshot of all Azure VMs](http://techgenix.com/azure-automation-create-vm-snapshot/)
- [Step-by-Step Guide: How to backup/restore encrypted Azure VM using Azure Backup?](https://www-rebeladmin-com.cdn.ampproject.org/v/s/www.rebeladmin.com/2019/10/step-step-guide-backup-restore-encrypted-azure-vm-using-azure-backup/amp/?amp_js_v=a6&amp_gsa=1&usqp=mq331AQHKAFQArABIA%3D%3D#aoh=16140237219390&referrer=https%3A%2F%2Fwww.google.com&amp_tf=From%20%251%24s&ampshare=https%3A%2F%2Fwww.rebeladmin.com%2F2019%2F10%2Fstep-step-guide-backup-restore-encrypted-azure-vm-using-azure-backup%2F)

### Microsoft Documentation

- [Backup and disaster recovery for Azure IaaS disks](https://docs.microsoft.com/en-us/azure/virtual-machines/backup-and-disaster-recovery-for-azure-iaas-disks)
- [Create a snapshot using the portal or Azure CLI](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/snapshot-copy-managed-disk_)
- [Create a snapshot using the portal or PowerShell](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/snapshot-copy-managed-disk)
- [Back up Azure unmanaged Virtual Machine disks with incremental snapshots](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/incremental-snapshots)
- [Create an incremental snapshot for managed disks](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-incremental-snapshots?tabs=azure-powershell)
- [Azure Government documentation](https://docs.microsoft.com/en-us/azure/azure-government/)