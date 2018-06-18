
   
#----------------------------------------------------------
#STATIC VARIABLES
#Git test
#----------------------------------------------------------
#TODO -explain $path
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$CSVPath  = $path + "\full_list_ad_users.csv"
#TODO -server needed?  
$ADServer = "mtkadcv01"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
#TODO -create individual log files
$logpath  = $path + "\LOG_ad_users.log"
$date     = Get-Date
#TODO -clean below line
#$Credential = #'a-gbertoluzzi' #Read-Host -Prompt "Input admin account name"
$Cred = Get-Credential $Credential

#----
# IMPORT MODULES
Import-Module ActiveDirectory
#----

Function Get-ImplementStatus {
##
# Checks the implement column, for 'y' or 'n' or 'disable' (case insensitive)
# if 'y' continue on to updating user or creating user (All one split function).
# if 'disable' go to function disable Disable-MedNetUser
# else (implied 'n') log "$user skipped"
##
    
    # Get CSV, which contains formatted user info
    Import-CSV $CSVPath | ForEach-Object {
        
        # Get username as var, use in later functions
        $sam = $_.UserName

        if ($_.Implement -eq "y") {

            # Creates new user or updates info of existing users
            Split-CreateUpdate

        } elseif ($_.Implement -eq "DISABLE") {

            #TODO -add group removal to the disable function
            Write-Host "DISABLE track chosen"
            Disable-MedNetUser

        } else {

            # Log info
            #TODO -consolidate info for singular log files, more effective info
            "user $Sam skipped for 'n' implement cmd.`n" | Out-File $logpath -Append 
        }
        
    }
}

Function Split-CreateUpdate {
# Main function pipeline.  
# Pipes to Initialize-MedNetUser or Update-MedNetUser.   
        $sam = $_.UserName
        
        #Try   { $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)" }
        #Catch { Write-Host "User $Sam not found" }
        #TODO -clean up the below $exists variable use.  
        $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)"
       
        if ( ! $exists ) {

            Write-Host "`nFrom function Split-ToCreateOrUpdate; Create track chosen for user $Sam"
            Initialize-MedNetUser
            "user $Sam created.`n" | Out-File $logpath -Append 

        } else {

            Write-Host "`nFrom function Split-ToCreateOrUpdate; Update track chosen for user: $sam"
            Update-MedNetUser
            "User $Sam updated.`n`n" | Out-File $logpath -Append 
            
        }   

}


Function Initialize-MedNetUser {
# Creates new users with the New-ADuser cmdlet
    New-ADUser $Sam -Credential $Cred -GivenName $_.FirstName -Surname $_.LastName `
    -DisplayName $_.'Display Name' -UserPrincipalName ($Sam + "@" + $dnsroot) `
    -StreetAddress $_.'Street Address' -City $_.City -State $_.State -PostalCode `
    $_.'Zip Code' -Country $_.Country -Title $_.'Job Title' -Company $_.Company `
    -Description $_.Description -EmailAddress $_.'Email Address' -OfficePhone $_.Phone `
    -OtherAttributes @{ProxyAddresses="SMTP:" + $_.'Email Address'} `
    -Department $_.Department -Path $_.TargetOU -Manager $_.Manager -Confirm



    # Department Assignments switch
    
    $a = $($_.Department)

    # Assigns the predetermined groups.  
    switch ($a) 
        {             
            "Sales" {
                    $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "mednet_sales")
            
                    for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                    {
                        Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                    }

                    Write-Host "User added to Sales"
            } 
            
            "IT" {
                    $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "imednet_devs", "mednet_it", "mednet_stash_users", "mednet_sysadmin", "mednet_vcenter_admins")
            
                    for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                    {
                        Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                    }
            } 

            "Finance" {
                        $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "mednet_payroll", "mednet_finance")
            
                        for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                        {
                            Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                        }
            }
            
            "HR" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "MedNet_HumanResources")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }
            
            "Admin" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "mednet_payroll", "mednet_finance")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "Development" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "imednet_devs", "MedNet_Stash_Users", "MedNet_TestRail")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "Test Automation" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "imednet_devs", "MedNet_AutomationGroup", "MedNet_Stash-ReadOnly", "MedNet_TestRail")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "SQA" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "MedNet_AutomationGroup", "MedNet_SQA", "MedNet_Stash-ReadOnly", "MedNet_TestRail")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "Compliance" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "MedNet_AutomationGroup", "MedNet_QA")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "TPO" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "MedNet_ProjectManagement", "MedNet_TPO")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            "Product Management" {
                $groupsToAdd = ("Mednet_Users", "MedNet_VPN", "MedNet_JiraUsers", "imednet_devs", "MedNet_ProductManagement", `
                "MedNet_Stash-ReadOnly", "MedNet_TestRail")
            
                for ($i = 0; $i -lt $groupsToAdd.Length; $i++)
                {
                    Add-ADGroupMember -Credential $Cred -Identity $groupsToAdd[$i] -members $sam
                }
            }

            default {"The department was not found, user not added to group"}
        }

    
    Write-Host "New AD User $sam created"
    "[ACTION - CREATION]`t New AD User $sam created in location $TargetOU" | Out-File $logpath -append
    Write-Host "Renaming object"
    #Rename-ADObject -Credential $Cred "CN=$sam,OU=Employees,OU=Users,OU=Mednet,DC=mednetstudy,DC=com" -NewName $cnName
    $newdn = (Get-ADUser $sam).DistinguishedName
    Write-Host "DN:" + $newdn
    $another = (Get-ADuser $sam).givenName + " " + (Get-ADuser $sam).Surname
    Write-Host "Given Name + suname : " + $another
    Rename-ADObject -Credential $Cred -Identity $newdn -NewName $another

}

Function Update-MedNetUser{    
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
        $Sn = $_.'Last Name'
        $DisplayName = $_.'Display Name'
        $StreetAddress = $_.'Street Address'
        $Sam = $_.UserName
        $City = $_.City
        $State = $_.State
        $PostalCode = $_.'Zip Code' 
        $Country = $_.'Country' 
        $Title = $_.'Job Title'
        $Company = $_.Company
        $Description = $_.Description
        $Department = $_.Department
        $Office = $_.Office
        $Phone = $_.Phone
        $Mail = $_.'Email Address'
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
            # Last name
            IF ($Sn) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{sn=$Sn} }
            #Else {"DisplayName not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # First Name
            IF ($GivenName) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{givenName=$GivenName} }
            #Else {"FirstName not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Display Name
            IF ($DisplayName) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{displayName=$DisplayName} }
            #Else {"DisplayName not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Street Address
            IF ($StreetAddress) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{StreetAddress=$StreetAddress} }
            #Else {"StreetAddress not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # City
            IF ($City ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{l=$City} }
            #Else {"City not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # State
            If ($State) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -State $State }
            #Else {"State not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Zip Code
            IF ($PostalCode) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{postalCode=$PostalCode} }
            #Else {"PostCode not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            #Country did not accept the -Replace switch. It works with the -Country switch
            IF ($Country) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam  -Country $Country }
            #Else {"Country not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Job Title
            IF ($Title) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Title=$Title} }
            #Else {"Job Title not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Company
            IF ($Company ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Company=$Company} }
            #Else {"Company not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Description
            IF ($Description ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Description=$Description} }
            #Else {"Description not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Department
            IF ($Department) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Department=$Department}  }
            #Else {"Department not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Office //Not needed
            IF ($Office) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{physicalDeliveryOfficeName=$Office}  }
            #Else {"Office not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Main phone number
            IF ($Phone) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{telephoneNumber=$Phone}  }
            #Else {"Phone number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            # Email address
            IF ($Mail) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{mail=$Mail}  }
            #Else {"Maile number not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }
            #Manager did not accept the -Replace switch. It works with the -manager switch
            IF ($Manager) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Manager $Manager} 
            #Else {"Manager not set for $DisplayName because it is not populated in the CSV file" | Out-File $logpath -Append }

            
            <#
            ## THESE ARE NOT MY COMMENTS.  
            #Change name format to 'FirstName Lastname'
            #This is essential because some Sutton users display as sAMAccountName
            #Rename-ADObject renames the users in the $DisplayName format
    
            
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
    
}

Function Disable-MedNetUser {
    Write-Host "Remove-MedNetUser function activated for user: $Sam"
    # Disable AD user and remove them from all AD Security groups
    # 1. Disable the account
    # 2. Remove account from groups  

    # 1.  Disable logic
    Disable-ADAccount -Identity $Sam -Credential $Cred

    # 2.  Remove logic
    # TODO get group membership, 
    Get-ADUser -Identity $Sam -Properties MemberOf -Credential $Cred | ForEach-Object {
        $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false -Credential $Cred
      }
}




# Implementation of functions:
Get-ImplementStatus

