### PowerShell Active Directory User Update and Creation Module.
#### MedNet_User_Control.ps1


>Current changes made, 15.mar.18
-looking into powershell module option, incorporating the functionality into the command line / powershell line
-Saved an _archive file for old functionality
-standard mednet_user_control but with todo of bamboo integration



### Overview.  

    This module has several functions, and once the module is activated and AD admin credentials are entered in the prompt all the functions will run through automatically, updating and creating new users.  To dictate what information is read by powershell change the info in the 'Implement' column of the csv sheet to 'y' or 'n'.  


### How to run:
    prereqs:
        a)  Must be connected to MedNet network.
        b?  Install RSAT then restart computer.  Required for the Active Directory module (link:  https://www.microsoft.com/en-us/download/details.aspx?id=45520)
    1.  Go to containing script folder: 
        -Open a Powershell terminal.  Navigate to the folder containing script.
        -The csv file 'ad_users.csv' MUST be in same folder.  
    2.  Run script [folderWith_MedNet_User_Control]> .\MedNet_User_Control.ps1
    3.  Enter in your admin credentials to the prompt window.  Script will now run through all steps.   


### To create new user:
    1.  Input user information to csv file.  Make sure to include the OU under "Target OU" if specific destination is wanted, 
            otherwise user will just appear under the default AD "Users" group.
    2.  Set the implementation column in CSV file to "y".  
    3.  Run script.  
    4.  Change implementation column to "n".  

### Update-SomeUsers:
    Overwrites, but doesn't erase data.  Leaving a blank line in the csv won't affect the AD info.  Only writing something new/different will change the csv data.
    1.  Update information on spreadsheet.  
    2.  Change implementation column to "y".
    3.  Run script. 
    4.  Change implementation column back to "n".



### Pending updates:
    #Department List integration:
        Currently can't update the AD security groups users are in.  Requires a separate loop/switch.  
        Department list:
        Product Management
        TPO
        Compliance
        SQA
        Test Automation
        Development
        Admin
        HR
        Finance
        IT
        Sales

    #Managers
        Can't add the manager of user yet.  Bug.  