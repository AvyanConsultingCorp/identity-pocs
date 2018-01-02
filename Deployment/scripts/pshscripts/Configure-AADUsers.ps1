<#
.SYNOPSIS
    Connects the AzureAD and Create User accounts.
.EXAMPLE
    ScenarioOne.ps1 -tenantId "46d804b6-210b-4a4a-9304-83b93e71784d" -subscriptionId "fb828b18-79dd-400c-919a-a393d88835e5" -tenantDomain "pcidemoxoutlook560.onmicrosoft.com"
    -globalAdminUsername "mohuyap@avyanconsulting.com" -globalAdminPassword <Service or Global Administrator Password> `
    -deploymentPassword "abcde!fgh@123"
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]	
    [guid]$tenantId,
    [Parameter(Mandatory = $true)]
    [guid]$subscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$tenantDomain,
    [Parameter(Mandatory = $true)]
    [string]$globalAdminUsername,
    [Parameter(Mandatory = $true)]
    [securestring]$globalAdminPassword,
    [Parameter(Mandatory = $true)]
    [string]$deploymentPassword
)

### Manage Session Configuration
$Host.UI.RawUI.WindowTitle = "NBME - Configure AAD Users"
$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'
Set-StrictMode -Version 3

### Create PSCredential Object
#$password = ConvertFrom-SecureString -String $globalAdminPassword -AsPlainText -Force
$test = $globalAdminPassword | ConvertFrom-SecureString
$SecurePassword = ConvertTo-SecureString $test
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername,$SecurePassword)

### Connect AzureAD
Connect-AzureAD -Credential $credential -TenantId $tenantId
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = $deploymentPassword
$passwordProfile.ForceChangePasswordNextLogin = $false

### Create AAD Users
$actors = @('Mike','Sean_SiteAdmin','Tim_WebUser')
foreach ($user in $actors) {
    $upn = $user + '@' + $tenantDomain
    Write-Host -ForegroundColor Yellow "`nChecking if $upn exists in AAD."
    if (!(Get-AzureADUser -SearchString $upn))
    {
        Write-Host -ForegroundColor Yellow  "`n$upn does not exist in the directory. Creating account for $upn."
        try {
			foreach($user in $actors)
			{		
            $userObj = New-AzureADUser -DisplayName $user -PasswordProfile $passwordProfile `
            -UserPrincipalName $upn -AccountEnabled $true -MailNickName $user
            Write-Host -ForegroundColor Yellow "`n$upn created successfully."
            if ($upn -eq ($user+'@'+$tenantDomain)) {
            #Get the Compay AD Admin ObjectID
            $companyAdminObjectId = Get-AzureADDirectoryRole | Where-Object {$_."DisplayName" -eq "Company Administrator"} | Select-Object ObjectId
            Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $userObj.ObjectId			
				if($user -eq 'Mike')
				{
					New-AzureRmRoleAssignment -SignInName $upn -RoleDefinitionName 'Owner'
				}
				else{

					New-AzureRmRoleAssignment -SignInName $upn -RoleDefinitionName 'contributor'
					}


            #Make the new user the company admin aka Global AD administrator
            
            Write-Host "`nSuccessfully granted AD permissions to $upn" -ForegroundColor Yellow
					
				}
            }
        }
        catch {
            throw $_
        }
    }
}