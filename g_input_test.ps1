
$ADServer = "mtkadcv01"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot

$date     = Get-Date
$Credential = 'a-gbertoluzzi' #Read-Host -Prompt "Input admin account name"
$Cred = Get-Credential $Credential

$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$log      = $path + "\LOG_ad_users.log"

$CSVPath  = $path + "\ad_users.csv"  
$CSVContent = Get-Content -Path $CSVPath
$csvfile = Import-Csv -path $CSVPath


$DisplayName = $_.'Display Name'


import-module ActiveDirectory

#-----

#-----




Function Split-ToCreateOrUpdate {

       $csvfile | ForEach-Object {
          $Sam = $_.UserName
          $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$Sam)"
          if (!$exists) {
            Write-Host "Create User track:  $Sam"
            "[ACTION]`t New user being created: $Sam`r`n" | Out-File $log -append
          }
          else {
            Write-Host "Update user track:  $Sam"
            "[ACTION]`t User being updated:  $Sam" | Out-File $log -append
          }
           
       }
   
}
Split-ToCreateOrUpdate