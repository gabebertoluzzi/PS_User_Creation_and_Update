<#
EXAMPLE
    To update user’s from a CSV file called User_Info.csv:
    PS Z:\> Update-ADUsers -CSVPath C:\CSV\User_Info.csv -Credential 70411lab\admin -ADServer servername
#>
   
#----------------------------------------------------------
#STATIC VARIABLES
#----------------------------------------------------------
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$CSVPath  = $path + "\ad_users.csv"    
$ADServer = "mtkadcv01"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
$logpath  = $path + "\LOG_ad_users.log"
$date     = Get-Date
$Credential = 'a-gbertoluzzi' #Read-Host -Prompt "Input admin account name"
$Cred = Get-Credential $Credential

#----
# MORE STUFF
Import-Module ActiveDirectory
#----



Function Split-ToCreateOrUpdate {
 
    Import-CSV $CSVPath | ForEach-Object {
        $sam = $_.UserName
        
        #Try   { $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)" }
        #Catch { Write-Host "User $Sam not found" }
        $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)"
        if (!$exists) {
            

            Write-Host "`nCreate track chosen for user $Sam"
            New-ADUsers
        }
        else {
            #Update-SomeUsers
            Write-Host "`nUpdate track chosen for user: $sam"
            Update-ToHost
            Update-SomeUsers
            
        }   
    }

}


Function Update-ToHost {
    Write-Host "Update-ToHost function $sam"
}

Function New-ADUsers {
# Creates new users with the New-ADuser cmdlet
    New-ADUser $Sam -Credential $Cred -GivenName $_.'First Name' -Surname $_.'Last Name' `
    -DisplayName $_.'Display Name' -UserPrincipalName ($Sam + "@" + $dnsroot) `
    -StreetAddress $_.'Street Address' -City $_.City -State $_.State -PostalCode `
    $_.'Zip Code' -Country $_.Country -Title $_.'Job Title' -Company $_.Company `
    -Description $_.Description -EmailAddress $_.'Email Address' -OfficePhone $_.Phone `
    -Path $_.TargetOU
    
    Write-Host "New AD User $sam created"
    "[ACTION - CREATION]`t New AD User $sam created in location $TargetOU" | Out-File $logpath -append
<#
  New-ADUser $sam -GivenName $_.First Name -Initials $_.Initials `
  -Surname $_.LastName -DisplayName ($_.LastName + "," + $_.Initials + " " + $_.GivenName) `
  -Office $_.OfficeName -Description $_.Description -EmailAddress $_.Mail `
  -StreetAddress $_.StreetAddress -City $_.City -State $_.State `
  -PostalCode $_.PostalCode -Country $_.Country -UserPrincipalName ($sam + "@" + $dnsroot) `
  -Company $_.Company -Department $_.Department -EmployeeID $_.EmployeeID `
  -Title $_.Title -OfficePhone $_.Phone -AccountPassword $setpass -Manager $_.Manager `
  -profilePath $_.ProfilePath -scriptPath $_.ScriptPath -homeDirectory $_.HomeDirectory `
  -homeDrive $_.homeDrive -Enabled $enabled -PasswordNeverExpires $expires
    #>
}

Function Update-SomeUsers{    
    #Updates existing users 
    #Test that the specified csv file is valid before inporting it, else throw an error and quit
    If ((Get-ChildItem $CSVPath).Extension -eq ".csv") {
        $csvfile = Import-Csv -path $CSVPath
    }
    Else {
        Write-Host "The specified file is not a valid CSV file, please check your file and try again" -ForegroundColor Red
        "The specified file is not a valid CSV file, please check your file and try again" #| Out-File $logfile -Append
        break 
    }


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
    
        #Check whether $sam exisits in Active Directory. 
    
        Try {
            $SAMinAD = (Get-ADUser -identity $Sam -server $ADServer `
            -Credential $Cred -ErrorAction SilentlyContinue).SamAccountName
        } 
        Catch { 
            Write-Host "No SAMinAD"
            Write-Host "$Sam"
        }
        #Execute set-aduser below only if $sam is in AD and also is in the excel file, else ignore#
        #If($SAMinAD -eq $sam -and $SAMinAD -ne $null ) {
        If($sam -ne $null ) {
    
            #added the 'if clause' to ensure that blank fields in the CSV are ignored.
            #the object names must be the LDAP names. get values using ADSI Edit
            IF ($DisplayName) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{displayName=$DisplayName} }
            Else {"DisplayName not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($StreetAddress) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{StreetAddress=$StreetAddress} }
            Else {"StreetAddress not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($City ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{l=$City} }
            Else {"City not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            If ($State) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -State $State }
            Else {"State not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($PostCode) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{postalCode=$PostCode} }
            Else {"PostCode not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            #Country did not accept the -Replace switch. It works with the -Country switch
            IF ($Country) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam  -Country $Country }
            Else {"Country not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Title) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Title=$Title} }
            Else {"Job Title not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Company ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Company=$Company} }
            Else {"Company not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Description ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Description=$Description} }
            Else {"Description not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Department) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Department=$Department}  }
            Else {"Department not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Office) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{physicalDeliveryOfficeName=$Office}  }
            Else {"Office not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Phone) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{telephoneNumber=$Phone}  }
            Else {"Phone number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            IF ($Mail) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{mail=$Mail}  }
            Else {"Maile number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            #Manager did not accept the -Replace switch. It works with the -manager switch
            IF ($Manager -and $ManagerDN) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Manager $ManagerDN} 
            Else {"Manager not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            #Change name format to 'FirstName Lastname'
            #This is essential because some Sutton users display as sAMAccountName
            #Rename-ADObject renames the users in the $DisplayName format
    
            <#
            $newsam = (Get-ADUser -identity $sam -server $ADServer -Credential $Cred).DistinguishedName #Rename-ADObject accepts -Identity in DN format
            Try {
                Rename-ADObject -server $ADServer -Credential $Cred -Identity $newsam -NewName $DisplayName -ErrorAction Stop
            }
            Catch [Exception] {
                "$DisplayName not renamed; The displayname might exist in the Directory" #| Out-File $logfile -Append
            }#>
                
                
            }
            Else {
                Write-Host "No luck"
            }
        #for each
    
}#func
    





Split-ToCreateOrUpdate
