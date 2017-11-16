
$ADServer = "mtkadcv01"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
#$log      = $path + "\create_ad_users.log"
$date     = Get-Date
$Credential = 'a-gbertoluzzi' #Read-Host -Prompt "Input admin account name"
$Cred = Get-Credential $Credential
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$CSVPath  = $path + "\ad_users.csv"  
$CSVContent = Get-Content -Path $CSVPath
$csvfile = Import-Csv -path $CSVPath
$DisplayName = $_.'Display Name'


import-module ActiveDirectory



Function Split-ToCreateOrUpdate {

       $csvfile | ForEach-Object {
            $Sam = $_.UserName
            $DisplayName = $_.'Display Name'
            $Description = $_.Description
            $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$Sam)"
            if (!$exists) {
               
              # New-ADUsers
               Write-Host "Create User track $Sam"
            }
            else {
               #Write-Host "Update user $Sam"

            IF ($DisplayName) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{displayName=$DisplayName} }
            Else {Write-Host "DisplayName not set for $DisplayName because it is not populated in the CSV file"}  
            } 
            IF ($Description ) { Set-ADUser -server $ADServer -Credential $Cred -Identity $sam -Replace @{Description=$Description} }
            Else {Write-Host "Description not set for $DisplayName because it is not populated in the CSV file"}
            
           
       }
   
}
Split-ToCreateOrUpdate