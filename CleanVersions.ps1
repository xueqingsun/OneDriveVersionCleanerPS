#Parameters
$SiteURL = "https://your-sharepoint-site/personal/personalaccount"
$ListName = "Documents"

# 0 means don't keep old versions, just keep the current version.
$VersionsToKeep = 0

#Connect to PnP Online, support for web form login
Connect-PnPOnline -Url $SiteURL -Interactive
 
#Get the Document Library
$List = Get-PnPList -Identity $ListName

#Get the Context
$Ctx= Get-PnPContext

$global:counter=0 
#Get All Items from the List - Get 'Files
$ListItems = Get-PnPListItem -List $ListName -PageSize 5000 | Where {$_.FileSystemObjectType -eq "File"}

#Read more: https://www.sharepointdiary.com/2018/05/sharepoint-online-delete-version-history-using-pnp-powershell.html#ixzz8IMfJGoy9

" list items count: "
$ListItems.count

$TotalFiles = $ListItems.count
" ListItems.count: "
$ListItems.count

$Counter = 1
$j = 0

try
{
	$a = Get-Content -Path .\progress.txt
	$j = [int]$a
}
catch
{
}

For(; $j -lt $TotalFiles; $j++)
{
	$Item = $ListItems[$j]
	if($Item -eq $null)
	{
		continue
	}
	
	Write-Progress -Activity "Cleaning" -Status "$j / $TotalFiles" -PercentComplete (100.0*$j / $TotalFiles)
	
    #Get File Versions
    $File = $Item.File
	
	if($File -ne $null)
	{	
		$Versions = $File.Versions		
		$Ctx.Load($File)
		$Ctx.Load($Versions)
		
		try
		{
			$Ctx.ExecuteQuery()
		}
		catch
		{
			continue
		}
		
		$VersionsCount = $Versions.Count
		$VersionsToDelete = $VersionsCount - $VersionsToKeep
		If($VersionsToDelete -gt 0)
		{
			Write-host -f Yellow "Scanning File ($Counter of $TotalFiles):"$Item.FieldValues.FileRef
			write-host -f Cyan "`t Total Number of Versions of the File:" $VersionsCount
			$VersionCounter= 0
			#Delete versions
			For($i=0; $i -lt $VersionsToDelete; $i++)
			{
				If($Versions[$VersionCounter].IsCurrentVersion)
				{
					$VersionCounter++
					Write-host -f Magenta "`t`t Retaining Current Major Version:" $Versions[$VersionCounter].VersionLabel
					Continue
				}
				Write-host -f Cyan "`t Deleting Version:" $Versions[$VersionCounter].VersionLabel
				$Versions[$VersionCounter].DeleteObject()
			}
			$Ctx.ExecuteQuery()
			Write-Host -f Green "`t Version History is cleaned for the File:"$File.Name
		}
		else
		{
			Write-Host -NoNewLine -f Cyan "."
		}
	}
	
	$j > .\progress.txt
    $Counter++
}
