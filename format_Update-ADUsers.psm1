<#
# AUTHOR  : Victor Ashiedu
# WEBSITE : iTechguides.com
# BLOG    : iTechguides.com/blog
# CREATED : 19-02-2015 
# UPDATED : 25-02-2015 
# COMMENT : Update-ADUsers Function updates Active Directory users
#           attributes using information from a csv file.        
#>

Function Update-ADUsers {

<#
.SYNOPSIS
	Update-ADUsers is a PowerShell function that updates Active Directory users with information in a CSV file. 	
.DESCRIPTION
	Update-ADUsers is a PowerShell function that updates Active Directory users with information in a CSV file
	The function has full error logging, and onscreen information display informing what task it is performing
	at any point in time.
.PARAMETER ADServer
	Specifies the Domain Controler to query. This is required in W2K3 Domains where one DC
	has Active Directory web services installed. 
.PARAMETER Credential
	Specifies credential that runs the Update-ADUsers. This account MUST have write permission
	to Active Directory. 
.PARAMETER  CSVPath
	Specifies the CSV containing the user info. This must be specified with the full path to the 
	CSV file (Including the extension, .CSV. I have attached a sample CSV file with examples
	of fields populated. 
.EXAMPLE
	To update user’s from a CSV file called User_Info.csv:
	PS Z:\> Update-ADUsers -CSVPath C:\CSV\User_Info.csv -Credential 70411lab\admin -ADServer servername
#>

[CmdletBinding(DefaultParameterSetName='CSVPath')]
Param
(
[Parameter(Mandatory=$true,Position=0,ParameterSetName='CSVPath')]
[ValidateNotNullOrEmpty()]
[String]$CSVPath,
[Parameter(Mandatory=$true,Position=1,ParameterSetName='CSVPath')][ValidateNotNullOrEmpty()]
[String]$Credential,
[Parameter(Mandatory=$true,Position=2,ParameterSetName='CSVPath')]
[ValidateNotNullOrEmpty()]
[String]$ADServer
		
)

BEGIN {
# Get script Start Time (used to measure run time)
$startDTM = (Get-Date)
$Cred = Get-Credential $Credential
#Define script path
$Scriptpath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\"
$logpath = $Scriptpath + "\Errorlogs"
If (!(Test-Path $logpath)) {New-Item -ItemType Directory -Path $logpath | Out-Null} #Out-Null suppreses console info

$Logfiletime = (Get-Date).ToString('dd-MM-yyyy')
$logfile = $logpath + "\logfile_$Logfiletime.txt"
$datestamp = ((Get-Date).ToString('dd-MM-yyyy(hh:mm:ss)'))
"" | Out-File $logfile -append #appends a space on top each time for easy reading
"Update-ADUsers errors logged " + $datestamp + ": " | Out-File $logfile -append
"---------------------------------------------------" | Out-File $logfile -append #appends a line beneath each log stamp for easy reading
#Test that the specified csv file is valid before inporting it, else throw an error and quit
If ((Get-ChildItem $CSVPath).Extension -eq ".csv") {$csvfile = Import-Csv -path $CSVPath}
Else 
{
Write-Host "The specified file is not a valid CSV file, please check your file and try again" -ForegroundColor Red
"The specified file is not a valid CSV file, please check your file and try again" | Out-File $logfile -Append
break 

}
Write-Host "Importing Active Directory Modules and performing pre-tasks..." -ForegroundColor Red
#import the ActiveDirectory Module
Import-Module ActiveDirectory -WarningAction SilentlyContinue

}

PROCESS {
Write-Host "Users update in progress, this might take some time, please wait" -ForegroundColor Magenta
$csvfile | `

ForEach-Object { 

$GivenName = $_.'First Name'
$Surname = $_.'Last Name'
$DisplayName = $_.'Display Name'
$StreetAddress = $_.'Full address'
$Sam = $_.UserName
$City = $_.City
$State = $_.State
$PostCode = $_.'Post Code' 
$Country = $_.'Country/Region' 
$Title = $_.'Job Title'
$Company = $_.Company
$Description = $_.Description
$Department = $_.Department
$Office = $_.Office
$Phone = $_.Phone
$Mail = $_.Email
$Manager = $_.Manager
#This script below is useful because some domains may not have
#a uniform way of displaying DisplayNames. Some users may have
#display name as 'Lastname FirstName', others may have it as 
#'FirstNameLastname'. Below I have split the $Manager name into
#$ManagerFirstname and $ManagerLastname
IF ($Manager) {
$ManagerFirstname = $Manager.Split("")[0]
$ManagerLastname = $Manager.Split("")[-1]
#Then create different possible combinations to use in the $ManagerDN Search
$ManagerDN1 = "$ManagerFirstname" + "$ManagerLastname"
$ManagerDN2 = "$ManagerLastname" + " $ManagerFirstname"
$ManagerDN3 = "$ManagerLastname" + "$ManagerFirstname"
#Convert names to lower case. Appears to be case sensitive
$ManagerLC = $Manager.ToLower()
$ManagerDNLC1 = $ManagerDN1.ToLower()
$ManagerDNLC2 = $ManagerDN2.ToLower()
$ManagerDNLC3 = $ManagerDN3.ToLower()
}
#Included the If clause below to ignore execution if the $Manager variable
#from the csv is blank. Avoids throwing errors and saves execution time
#Used different possible displaynames to search for a managername
$ManagerDN = IF ($Manager) 
{(Get-ADUser -server $ADServer -Credential $Cred -Filter `
{(Name -like $Manager) -or (Name -like $ManagerDN1) -or (Name -like $ManagerDN2) `
-or (Name -like $ManagerDN3) -or (Name -like $ManagerLC) -or (Name -like $ManagerDNLC1) `
-or (Name -like $ManagerDNLC2) -or (Name -like $ManagerDNLC3)}).DistinguishedName} #Manager required in DN format
#Changed managerdn filter above because Sutton users have displayname reversed

#Import country codes and convert country to codes 
#for use in $Country

$Countrycsvfile = $Scriptpath + "\Country_Codes.csv"
Import-Csv -Path $Countrycsvfile |

ForEach-Object {

$CountryName =$_.'Country Name'
$CountryCode = $_.Codes

If ($Country -eq "$CountryName") {$Country = "$CountryCode"}


}

#Check whether $sam exisits in Active Directory. 

Try {$SAMinAD = (Get-ADUser -identity $sam -server $ADServer -Credential $Cred -ErrorAction SilentlyContinue).SamAccountName} 
Catch { }

#Execute set-aduser below only if $sam is in AD and also is in the excel file, else ignore#
If($SAMinAD -eq $sam -and $SAMinAD -ne $null )
{

#added the 'if clause' to ensure that blank fields in the CSV are ignored.
#the object names must be the LDAP names. get values using ADSI Edit
IF ($DisplayName) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{displayName=$DisplayName} }
Else {"DisplayName not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($StreetAddress) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{StreetAddress=$StreetAddress} }
Else {"StreetAddress not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($City ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{l=$City} }
Else {"City not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
If ($State) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -State $State }
Else {"State not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($PostCode) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{postalCode=$PostCode} }
Else {"PostCode not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
#Country did not accept the -Replace switch. It works with the -Country switch
IF ($Country) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam  -Country $Country }
Else {"Country not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Title) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Title=$Title} }
Else {"Job Title not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Company ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Company=$Company} }
Else {"Company not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Description ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Description=$Description} }
Else {"Description not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Department) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Department=$Department}  }
Else {"Department not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Office) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{physicalDeliveryOfficeName=$Office}  }
Else {"Office not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Phone) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{telephoneNumber=$Phone}  }
Else {"Phone number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
IF ($Mail) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{mail=$Mail}  }
Else {"Maile number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
#Manager did not accept the -Replace switch. It works with the -manager switch
IF ($Manager -and $ManagerDN) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Manager $ManagerDN} 
Else {"Manager not set for $DisplayName because it is not populated in the CSV file" | Out-File $logfile -Append }
#Change name format to 'FirstName Lastname'
#This is essential because some Sutton users display as sAMAccountName
#Rename-ADObject renames the users in the $DisplayName format

$newsam = (Get-ADUser -identity $sam -server $ADServer -Credential $Cred).DistinguishedName #Rename-ADObject accepts -Identity in DN format
Try {Rename-ADObject -server $ADServer -Credential $Cred -Identity $newsam -NewName $DisplayName -ErrorAction Stop}
Catch [Exception]
{"$DisplayName not renamed; The displayname might exist in the Directory" | Out-File $logfile -Append}


}
Else

{ #Log error for users that are not in Active Directory or with no Logon name in excel file
$DisplayName + " Not modified because it does not exist in AD or UserName field on excel file is empty" | Out-File $logfile -Append
}


}


}

END {

#The lins below calculates how long
#it takes to run this script
# Get End Time
$endDTM = (Get-Date)

Write-Host "Completed, total run time is"$(($endDTM-$startDTM).totalminutes) minutes". Check log file for errors and information" -ForegroundColor Cyan
}

}
   



