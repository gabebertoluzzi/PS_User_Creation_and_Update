Function Update-ADUsers {
    BEGIN {
        $Credential = Read-Host -Prompt "Input admin account name"
        $Cred = Get-Credential $Credential
        #Define script path
        #$log      = $path + "\ad_users.log"
        $path     = Split-Path -parent $MyInvocation.MyCommand.Definition
        $CSVPath  = $path + "\ad_users.csv"    
        $ADServer = "mtkadcv01"
    
        #Test that the specified csv file is valid before inporting it, else throw an error and quit
        If ((Get-ChildItem $CSVPath).Extension -eq ".csv") {$csvfile = Import-Csv -path $CSVPath}
        Else {
        Write-Host "The specified file is not a valid CSV file, please check your file and try again" -ForegroundColor Red
        "The specified file is not a valid CSV file, please check your file and try again" #| Out-File $logfile -Append
        break 
        }
    
        Import-Module ActiveDirectory
    }
    
    PROCESS {
    
        $csvfile | ForEach-Object {
            $GivenName = $_.'First Name'
            $Surname = $_.'Last Name'
            $DisplayName = $_.'Display Name'
            $StreetAddress = $_.'Full address'
            $Sam = $_.UserName
            $City = $_.City
            $State = $_.State
            $PostCode = $_.'Post Code' 
    
            $Title = $_.'Job Title'
            $Company = $_.Company
            $Description = $_.Description
            $Department = $_.Department
            $Office = $_.Office
            $Phone = $_.Phone
    
         
    
    
            #Check whether $sam exisits in Active Directory. 
    
            Try {$SAMinAD = (Get-ADUser -identity $Sam -server $ADServer -Credential $Cred -ErrorAction SilentlyContinue).SamAccountName} 
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
                Else {Write-Host "DisplayName not set for $DisplayName because it is not populated in the CSV file"}
                IF ($StreetAddress) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{StreetAddress=$StreetAddress} }
                Else {Write-Host "StreetAddress not set for $DisplayName because it is not populated in the CSV file"}
                IF ($City ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{l=$City} }
                Else {Write-Host "City not set for $DisplayName because it is not populated in the CSV file"}
                If ($State) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -State $State }
                Else {Write-Host "State not set for $DisplayName because it is not populated in the CSV file" }
                IF ($PostCode) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{postalCode=$PostCode} }
                Else {Write-Host "PostCode not set for $DisplayName because it is not populated in the CSV file" }
                IF ($Title) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Title=$Title} }
                Else {Write-Host "Job Title not set for $DisplayName because it is not populated in the CSV file" }
                IF ($Company ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Company=$Company} }
                Else {Write-Host "Company not set for $DisplayName because it is not populated in the CSV file"}
                IF ($Description ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Description=$Description} }
                Else {Write-Host "Description not set for $DisplayName because it is not populated in the CSV file"}
                IF ($Office) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{physicalDeliveryOfficeName=$Office}  }
                Else {Write-Host "Office not set for $DisplayName because it is not populated in the CSV file"}
                IF ($Phone) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{telephoneNumber=$Phone}  }
                Else {Write-Host "Phone number not set for $DisplayName because it is not populated in the CSV file"}
                #Change name format to 'FirstName Lastname'
                #This is essential because some Sutton users display as sAMAccountName
                #Rename-ADObject renames the users in the $DisplayName format
    
                $newsam = (Get-ADUser -identity $sam -server $ADServer -Credential $Cred).DistinguishedName #Rename-ADObject accepts -Identity in DN format
                Try {
                    Rename-ADObject -server $ADServer -Credential $Cred -Identity $newsam -NewName $DisplayName -ErrorAction Stop
                }
                Catch [Exception] {
                    "$DisplayName not renamed; The displayname might exist in the Directory" #| Out-File $logfile -Append
                }
                
                
            }
            Else {
                Write-Host "No luck"
            }
        }#for each
    }#process
    
    
}



