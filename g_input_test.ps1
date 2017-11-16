
$ADServer = "mtkadcv01"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
#$log      = $path + "\create_ad_users.log"
$date     = Get-Date
#$Credential = 'a-gbertoluzzi' #Read-Host -Prompt "Input admin account name"
#$Cred = Get-Credential $Credential
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$CSVPath  = $path + "\ad_users.csv"  
$CSVContent = Get-Content -Path $CSVPath
$csvfile = Import-Csv -path $CSVPath
$DisplayName = $_.'Display Name'


import-module ActiveDirectory

#-----
$Sam = $_.UserName
#-----

$csvfile | For ($i = 0; $i -lt $csvfile.length; $i++ ) {
  Write-Host $_.UserName
}



Function Split-ToCreateOrUpdate {

       $csvfile | ForEach-Object {

            $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$Sam)"
            if (!$exists) {
               
               Write-Host "Create User track $Sam"
            }
            else {
               Write-Host "Update user $Sam"
            }
           
       }
   
}
#Split-ToCreateOrUpdate