[CmdletBinding()]
param
(
    #Any 5 length prefix starting with an alphabet.
    [Parameter(Mandatory = $true, 
    ParameterSetName = "Deployment", 
    Position = 1)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 1)]
    [Alias("prefix")]
    [ValidateLength(1,5)]
    [ValidatePattern("[a-z][a-z0-9]")]
    [string]$deploymentPrefix,

    #Azure AD Tenant Id.
    [Parameter(Mandatory = $true,
    ParameterSetName = "Deployment",
    Position = 2)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 2)]
    [guid]$tenantId,

    #Azure Subscription Id.
    [Parameter(Mandatory = $true,
    ParameterSetName = "Deployment",
    Position = 3)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 3)]
	[Alias("subId")]
    [guid]$subscriptionId,

    #Azure Tenant Domain name.
    [Parameter(Mandatory = $true,
    ParameterSetName = "Deployment",
    Position = 4)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 4)]
    [Alias("domain")]
    [ValidatePattern("[.]")]
    [string]$tenantDomain,

    #Subcription GlobalAdministrator Username.
    [Parameter(Mandatory = $true,
    ParameterSetName = "Deployment",
    Position = 5)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 5)]
	[Alias("userName")]
    [string]$globalAdminUsername,

    #GlobalAdministrator Password in a plain text.
    [Parameter(Mandatory = $true,
    ParameterSetName = "Deployment",
    Position = 6)]
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 6)]
	[Alias("password")]
    [securestring]$globalAdminPassword,

    #Location. Default is westcentralus.
    [Parameter(Mandatory = $false,
    ParameterSetName = "Deployment",
    Position = 7)]
    [Parameter(Mandatory = $false, 
    ParameterSetName = "CleanUp", 
    Position = 7)]
    [ValidateSet("eastus","westus2","westcentralus")]
	[Alias("loc")]
    [string]$location = "westcentralus",

    #[Optional] Strong deployment password. Auto-generates password if not provided.
    [Parameter(Mandatory = $false,
    ParameterSetName = "Deployment",
    Position = 8)]
    [Alias("dpwd")]
    [string]$deploymentPassword = 'null',
 
    #Switch to install required modules.
    [Parameter(Mandatory = $true,
    ParameterSetName = "InstallModules")]
    [switch]$installModules,
	
    #Switch to cleanup deployment resources from the subscription.
    [Parameter(Mandatory = $true, 
    ParameterSetName = "CleanUp", 
    Position = 9)]
    [switch]$clearDeployment

)

### Manage Session Configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
Set-StrictMode -Version 3
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path

. $scriptroot\scripts\pshscripts\PshFunctions.ps1
### Create Output  folder to storelogs, deploymentoutputs etc.
if(! (Test-Path -Path "$(Split-Path $MyInvocation.MyCommand.Path)\output")) {
    New-Item -Path $(Split-Path $MyInvocation.MyCommand.Path) -Name 'output' -ItemType Directory
}
$outputFolderPath = "$(Split-Path $MyInvocation.MyCommand.Path)\output"
### Install required powershell modules
$requiredModules=@{
    'AzureRM'= '4.4.0'
    'AzureAD' = '2.0.0.131';
    'SqlServer' = '21.0.17199';
    'MSOnline' = '1.1.166.0'
}

if ($installModules) {
    log "Trying to install listed modules.."
    $requiredModules
    Install-RequiredModules -moduleNames $requiredModules
    log "All the required modules are now installed. You can now re-run the script without 'installModules' switch." Cyan
    Break
}
# Remove all Azure credentials, account, and subscription information.
Clear-AzureRmContext -Scope CurrentUser -Force

### Converting deployment prefix to lowercase
$deploymentprefix = $deploymentprefix.ToLower()
## Create PSCredential Object for GlobalAdmin Account
$credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)

### Connect to AzureRM using Global Administrator Account
log "Connecting to AzureRM Subscription $subscriptionId using Global Administrator Account."
### Create PSCredential Object for GlobalAdmin Account
$credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)
$globalAdminContext =Login-AzureRmAccount -Credential $credential -Subscription $subscriptionId -ErrorAction SilentlyContinue
if($globalAdminContext -ne $null){
   log "Connection using Global Administrator Account was successful." Green
}
Else{
   log "Failed connecting to Azure using Global Administrator Account." Red
    Break
}

if ($clearDeployment) {
    try {
        log "Looking for Resources to Delete.." Magenta
        log "List of deployment resources for deletion" -displaywithouttimestamp

        #List The Resource Group
        $resourceGroupList =@(
            (($deploymentPrefix, 'artifacts', 'rg') -join '-'),
            (($deploymentPrefix, 'workload', 'rg') -join '-')
        )
        log "Resource Groups: " Cyan -displaywithouttimestamp
        $resourceGroupList | ForEach-Object {
            $resourceGroupName = $_
            $resourceGroupObj = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
            if($resourceGroupObj-ne $null)
            {
                log "$($resourceGroupObj.ResourceGroupName)." -displaywithouttimestamp -nonewline
                $rgCount = 1 
            }
            else 
            {
                $rgCount = 0
                log "$resourceGroupName Resource group does not exist." -displaywithouttimestamp
            }
        }

        #List the Service principal
        log "Service Principals: " Cyan -displaywithouttimestamp
        $servicePrincipalObj = Get-AzureRmADServicePrincipal -SearchString $deploymentPrefix -ErrorAction SilentlyContinue
        if ($servicePrincipalObj -ne $null)
        {
            $servicePrincipalObj | ForEach-Object {
                log "$($_.DisplayName)" -displaywithouttimestamp -nonewline
            }
        }
        else{ 
            log "Service Principal does not exist for '$deploymentPrefix' prefix" Yellow
        }

        #List the AD Application
        $adApplicationObj = Get-AzureRmADApplication -DisplayNameStartWith "$deploymentPrefix Identity Web Application"
        log "AD Applications: " Cyan -displaywithouttimestamp
        if($adApplicationObj -ne $null){
            log "$($adApplicationObj.DisplayName)" -displaywithouttimestamp -nonewline
        }
        Else{
            log "AD Application does not exist for '$deploymentPrefix' prefix" Yellow -displaywithouttimestamp
        }

        #List the AD Users
        log "AD Users: " Cyan -displaywithouttimestamp
		$actors = @('NBME_SiteAdmin','NBME_ApplicationManager','NBME_Disable')
        foreach ($actor in $actors) {
            $upn = Get-AzureRmADUser -SearchString $actor
            $fullUpn = $actor + '@' + $tenantDomain
            if ($upn -ne $null )
            {
                log "$fullUpn" -displaywithouttimestamp -nonewline
            }
        }
        if ($upn -eq $null)
        {
            log "No user exist" Yellow -displaywithouttimestamp
        }
        Write-Host ""
        # Remove deployment resources
        $message = "Do you want to DELETE above listed Deployment Resources ?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Deletes Deployment Resources"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Skips Deployment Resources Deletion"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($null, $message, $options, 0)
        switch ($result){
            0 {
                # Remove ResourceGroups
                if ($rgCount -eq 1)
                {
                $resourceGroupList =@(
                    (($deploymentPrefix, 'artifacts', 'rg') -join '-'),
                    (($deploymentPrefix, 'workload',  'rg') -join '-')
                )
                $resourceGroupList | ForEach-Object { 
                    $resourceGroupName = $_
                    Get-AzureRmResourceGroup -Name $resourceGroupName | Out-Null
                        log "Deleting Resource group $resourceGroupName" Yellow -displaywithouttimestamp
                        Remove-AzureRmResourceGroup -Name $resourceGroupName -Force| Out-Null
                        log "ResourceGroup $resourceGroupName was deleted successfully" Yellow -displaywithouttimestamp
                    }
                }

                # Remove Service Principal
                if ($servicePrincipals = Get-AzureRmADServicePrincipal -SearchString $deploymentPrefix) {
                    $servicePrincipals | ForEach-Object {
                        log "Removing Service Principal - $($_.DisplayName)."
                        Remove-AzureRmADServicePrincipal -ObjectId $_.Id -Force
                        log "Service Principal - $($_.DisplayName) was removed successfully" Yellow -displaywithouttimestamp
                    }
                }

                # Remove Azure AD Users
                
                if ($upn -ne $null)
                {
                    log "Removing Azure AD User" Yellow -displaywithouttimestamp
                    foreach ($actor in $actors) {
                        try {
                            $upn = $actor + '@' + $tenantDomain
                            Get-AzureRmADUser -SearchString $upn
                            Remove-AzureRmADUser -UPNOrObjectId $upn -Force -ErrorAction SilentlyContinue
                            log "$upn delete successfully. " Yellow -displaywithouttimestamp
                        }
                        catch [System.Exception] {
                            Throw $_
                        }
                    }
                }
				
                #Remove AAD Application.
                if($adApplicationObj)
                {
                    log "Removing Azure AD Application - $deploymentPrefix Identity Web Application" Yellow -displaywithouttimestamp
                    Get-AzureRmADApplication -DisplayNameStartWith "$deploymentPrefix Identity Web Application" | Remove-AzureRmADApplication -Force
                    log "Azure AD Application - $deploymentPrefix Azure HIPAA LOS Sample removed successfully" Yellow -displaywithouttimestamp
                }
                log "Resources cleared successfully." Magenta
            }
            1 {
                log "Skipped - Resource Deletion." Cyan
            }
        }
    }
    catch {
        Throw $_
    }
}
else {
    ### Collect deployment output into Hashtable
    $outputTable = New-Object -TypeName Hashtable

    ### Set Deployment password if not already set.
    if ($deploymentPassword -eq 'null') {
       log "Deployment password was not provided. Creating strong password for deployment."
        $deploymentPassword = New-RandomPassword
       log "Deployment password $deploymentPassword generated successfully."
    }

	### Convert deploymentPasssword to SecureString.
    $secureDeploymentPassword = ConvertTo-SecureString $deploymentPassword -AsPlainText -Force

    ### Convert Service Administrator to plaintext
    $convertedGlobalAdminPassword = $globalAdminPassword | ConvertFrom-SecureString 
    $securePassword = ConvertTo-SecureString $convertedGlobalAdminPassword
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $plainGlobalAdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    #import script
    #. $scriptroot\scripts\pshscripts\Configure-AADUsers.ps1 -tenantId $tenantId -subscriptionId $subscriptionId -tenantDomain $tenantDomain -globalAdminUsername $globalAdminUsername -globalAdminPassword $securePassword -deploymentPassword $deploymentPassword
    ### Configure AAD User Accounts.
   log "Creating AAD account for solution."
    try
    {
       log "Initiating separate powershell session for creating accounts."
       #Configure-AADUsers.ps1 
       .\scripts\pshscripts\Configure-AADUsers.ps1 -tenantId $tenantId -subscriptionId $subscriptionId -tenantDomain $tenantDomain -globalAdminUsername $globalAdminUsername -globalAdminPassword $securePassword -deploymentPassword $deploymentPassword

    }
    catch [System.Exception]
    {
        log $_
    }

    log "Wait for AAD Users to be provisioned."
    Start-Sleep 10

    try {
    ### Create PSCredential Object for SiteAdmin
    $siteAdminUserName = "Reed_SiteAdmin@" + $tenantDomain
    $siteAdmincredential = New-Object System.Management.Automation.PSCredential ($siteAdminUserName, $secureDeploymentPassword)
    
    ### Connect to AzureRM using SiteAdmin
    log "Connecting to AzureRM Subscription $subscriptionId using Account($globalAdminUsername)"
    $credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)
    $globalAdminContext = Login-AzureRmAccount -Credential $credential -Subscription $subscriptionId -ErrorAction SilentlyContinue
    
	if($globalAdminContext -ne $null){
       log "Connection to AzureRM was successful using $globalAdminUsername Account." Green
    }
    Else{
       log "Failed connecting to AzureRM using $globalAdminUsername Account." Red
        break
    }
}
catch {
    
   log $_.Exception.Message
    Break
}
    Start-Sleep 10

	$adAppClientId=""
    # Create Azure Active Directory apps in default directory.
    try{
        $AppServiceURL = (("http://",$deploymentPrefix,"-identity-webapp.azurewebsites.net") -join '' )
        $displayName = "$deploymentPrefix Identity Web Application"

        if (!($identityAADApplication = Get-AzureRmADApplication -IdentifierUri $AppServiceURL)) {
        log "Creating AAD Application deployment"
        $identityAADApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $AppServiceURL -IdentifierUris $AppServiceURL -Password $secureDeploymentPassword
        $identityAdApplicationClientId = $identityAADApplication.ApplicationId.Guid
		$adAppClientId = $identityAdApplicationClientId.ToString()
        $identityAdApplicationObjectId = $identityAADApplication.ObjectId.Guid.ToString()
        log "AAD Application  was successful. AppID is $identityAdApplicationClientId" Green
        # Create a service principal for the AD Application and add a Reader role to the principal 
        log "Creating Service principal for deployment"
        $identityServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $identityAdApplicationClientId
        Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
        log "Service principal for deployment was successful - $($identityServicePrincipal.DisplayName)"
        }
		else{
            $adAppClientId = $identityAADApplication.ApplicationId.Guid.ToString()
            $identityAdApplicationObjectId = $identityAADApplication.ObjectId.Guid.ToString()
            <#$identityAdServicePrincipalObjectId = (Get-AzureRmADServicePrincipal | ?  DispLayName -eq "$deploymentPrefix Identity Application").Id.Guid#>
            
            New-AzureRmADAppCredential -ObjectId $identityAADApplication.ObjectId.Guid -Password $secureDeploymentPassword
        }
        #Connect to Azure AD.
        Connect-AzureAD -TenantId $tenantId -Credential $credential
        $replyUrl =  (('https://', $deploymentPrefix ,'-identity-webapp' ,'.azurewebsites.net/.auth/login/aad/callback') -join '')
		Set-AzureADApplication -ObjectId $identityAdApplicationObjectId -ReplyUrls $replyUrl
		 $requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
                    $resourceAccess1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope"
                    #$resourceAccess2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "5778995a-e1bf-45b8-affa-663a9f3f4d04","Role"
                    $requiredResourceAccess.ResourceAccess = $resourceAccess1
                    $requiredResourceAccess.ResourceAppId = "00000002-0000-0000-c000-000000000000" #Resource App ID for Azure ActiveDirectory
                    Set-AzureADApplication -ObjectId $identityAdApplicationObjectId -RequiredResourceAccess $requiredResourceAccess       
        
    }
    catch {
        
       log $_.Exception.Message
        Break
    }
    
    try {        
        ### Connect to AzureAD using GlobalAdmin
        log "Connecting to AzureAD using Account($globalAdminUsername)"
        $credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)
        $globalAdminAdContext = Connect-AzureAD -Credential $credential -ErrorAction SilentlyContinue -TenantId $tenantId
        #$globalAdminAdContext = Connect-MsolService -Credential $credential -ErrorAction SilentlyContinue
        
        if($globalAdminAdContext -ne $null){
           log "Connection to AzureAD was successful using $globalAdminUsername Account."  Green
           $upn='NBME_Disable@'+$tenantDomain
           log "Trying to disable $upn using $globalAdminUsername Account."  Cyan
           Set-AzureADUser -ObjectID $upn -AccountEnabled $false
           #Set-MsolUser -UserPrincipalName $upn  -BlockCredential $true
           log "Disabled $upn using $globalAdminUsername Account."  Green
    
        }
        Else{
           log "Failed connecting to AzureAD using $globalAdminUsername Account."  Red
            break
        }
    }
    catch {
        
       log $_.Exception.Message
        Break
    }

	### Create Resource Group for deployment and assigning RBAC to users.
    $components = @("artifacts","workload")
    $components | ForEach-Object { 
        $rgName = (($deploymentPrefix,$_,'rg') -join '-')
        log "Creating ResourceGroup $rgName at $location."
        New-AzureRmResourceGroup -Name $rgName -Location $location -Force -OutVariable $_
    }

	  ### Invoke ARM deployment.
        log "Initiating Identity POC Deployment." Cyan
        
        log "Invoke Background Job Deployment for Workload"
        Invoke-ARMDeployment -subscriptionId $subscriptionId -resourceGroupPrefix $deploymentPrefix -location $location -identityAdApplicationClientId $adAppClientId -steps 1 -prerequisiteRefresh

        # Pause Session for Background Job to Initiate.
        log "Waiting session for background job to initiate"
        Start-Sleep 20

        #Get deployment status
        while ((Get-Job -Name '1-create' | Select-Object -Last 1).State -eq 'Running') {
            Get-ARMDeploymentStatus -jobName '1-create'
            Start-Sleep 10
        }
        if ((Get-Job -Name '1-create' | Select-Object -Last 1).State -eq 'Completed') 
        {
            Get-ARMDeploymentStatus -jobName '1-create'
        }
        else
        {
            Get-ARMDeploymentStatus -jobName '1-create'
            log $error[0] -color Red
            Break
        }
}