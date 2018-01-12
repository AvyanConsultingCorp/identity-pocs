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
Login-AzureRmAccount -Credential $credential -SubscriptionId $subscriptionId

### Connect AzureAD
Connect-AzureAD -Credential $credential -TenantId $tenantId
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = $deploymentPassword
$passwordProfile.ForceChangePasswordNextlogin = $false
$alluser = New-Object System.Collections.ArrayList
$Disableduser = New-Object System.Collections.ArrayList
$outputFile = New-Object System.Object

### Create AAD Users
$actors = @('NBME_SiteAdmin','NBME_ApplicationManager','NBME_Disable')
foreach ($user in $actors) {
    $upn = $user + '@' + $tenantDomain
	if($user -eq 'NBME_Disable')
	{
		[void]$Disableduser.Add($upn)
	}
	[void]$alluser.Add($upn)
    Write-Host -ForegroundColor Yellow "`nChecking if $upn exists in AAD."
    if (!(Get-AzureADUser -SearchString $user ))
    {
        Write-Host -ForegroundColor Yellow  "`n$upn does not exist in the directory. Creating account for $upn."
        try {
            $userObj = New-AzureADUser -DisplayName $user -PasswordProfile $passwordProfile `
            -UserPrincipalName $upn -AccountEnabled $true -MailNickName $user
            Write-Host -ForegroundColor Yellow "`n$upn created successfully."
            if ($upn -eq ($user+'@'+$tenantDomain)) {
            #Get the Compay AD Admin ObjectID
            $companyAdminObjectId = Get-AzureADDirectoryRole | Where-Object {$_."DisplayName" -eq "Company Administrator"} | Select-Object ObjectId
            Add-AzureADDirectoryRoleMember -ObjectId $companyAdminObjectId.ObjectId -RefObjectId $userObj.ObjectId			
				if($user -eq 'NBME_SiteAdmin')
				{
                    New-AzureRmRoleAssignment -SignInName $upn -RoleDefinitionName 'Owner'
                    #Make the new user the company admin aka Global AD administrator			
				}
				else
				{
                    New-AzureRmRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor'			

				}


            
            Write-Host "`nSuccessfully granted AD permissions to $upn" -ForegroundColor Yellow
					
				}
        }
        catch {
            throw $_
        }
    }
}

  $scriptRoot = Split-Path $MyInvocation.MyCommand.Path
  $outputFile | Add-Member NoteProperty -Name "AllUsers" -Value $alluser
  $outputFile | Add-Member NoteProperty -Name "Disable user" -Value $Disableduser
  $outputFile | Add-Member NoteProperty -Name "Password" -Value $deploymentPassword
  $jsonoutput = $outputFile | ConvertTo-Json
  $scriptpath = split-path $scriptRoot
  $outputpath = split-path $scriptpath 
  $jsonoutput | Out-File $outputpath\output\usersScenarioOne.txt
  