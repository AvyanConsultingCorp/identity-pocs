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
    [switch]$clearDeployment,

    #Switch to set password policy to expire after 60 days at domain level.
    [Parameter(Mandatory = $false,
    ParameterSetName = "Deployment",
    Position = 10)]
    [switch]$enableADDomainPasswordPolicy

)

### Manage Session Configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
Set-StrictMode -Version 3
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path

. $scriptroot\scripts\pshscripts\PshFunctions.ps1
### Create Output  folder to storeWrite-Hosts, deploymentoutputs etc.
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
    Write-Host "Trying to install listed modules.."
    $requiredModules
    Install-RequiredModules -moduleNames $requiredModules
    Write-Host "All the required modules are now installed. You can now re-run the script without 'installModules' switch." -ForegroundColor Cyan
    Break
}
# Remove all Azure credentials, account, and subscription information.
Clear-AzureRmContext -Scope CurrentUser -Force

### Converting deployment prefix to lowercase
$deploymentprefix = $deploymentprefix.ToLower()
## Create PSCredential Object for GlobalAdmin Account
$credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)

### Connect to AzureRM using Global Administrator Account
Write-Host "Connecting to AzureRM Subscription $subscriptionId using Global Administrator Account."
### Create PSCredential Object for GlobalAdmin Account
$credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)
$globalAdminContext =Login-AzureRmAccount -Credential $credential -Subscription $subscriptionId -ErrorAction SilentlyContinue
if($globalAdminContext -ne $null){
   Write-Host "Connection using Global Administrator Account was successful." -ForegroundColor Green
}
Else{
   Write-Host "Failed connecting to Azure using Global Administrator Account." -ForegroundColor Red
    Break
}

if ($clearDeployment) {
}
else {
    ### Collect deployment output into Hashtable
    $outputTable = New-Object -TypeName Hashtable

    ### Set Deployment password if not already set.
    if ($deploymentPassword -eq 'null') {
       Write-Host "Deployment password was not provided. Creating strong password for deployment."
        $deploymentPassword = New-RandomPassword
       Write-Host "Deployment password $deploymentPassword generated successfully."
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
   Write-Host "Creating AAD account for solution."
    try
    {
       Write-Host "Initiating separate powershell session for creating accounts."
       #Configure-AADUsers.ps1 
       .\scripts\pshscripts\Configure-AADUsers.ps1 -tenantId $tenantId -subscriptionId $subscriptionId -tenantDomain $tenantDomain -globalAdminUsername $globalAdminUsername -globalAdminPassword $securePassword -deploymentPassword $deploymentPassword

    }
    catch [System.Exception]
    {
        Write-Host $_
    }

    Write-Host "Wait for AAD Users to be provisioned."
    Start-Sleep 10

    try {
    ### Create PSCredential Object for SiteAdmin
    $siteAdminUserName = "Reed_SiteAdmin@" + $tenantDomain
    $siteAdmincredential = New-Object System.Management.Automation.PSCredential ($siteAdminUserName, $secureDeploymentPassword)
    
    ### Connect to AzureRM using SiteAdmin
    Write-Host "Connecting to AzureRM Subscription $subscriptionId using Account($globalAdminUsername)"
    $credential = New-Object System.Management.Automation.PSCredential ($globalAdminUsername, $globalAdminPassword)
    $globalAdminContext = Login-AzureRmAccount -Credential $credential -Subscription $subscriptionId -ErrorAction SilentlyContinue
    
	if($globalAdminContext -ne $null){
       Write-Host "Connection to AzureRM was successful using Reed_SiteAdmin Account." -ForegroundColor Green
    }
    Else{
       Write-Host "Failed connecting to AzureRM using Reed_SiteAdmin Account." -ForegroundColor Red
        break
    }
}
catch {
    
   Write-Host $_.Exception.Message
    Break
}
    Start-Sleep 10

	$adAppClientId=""
    # Create Azure Active Directory apps in default directory.
    try{
        $AppServiceURL = (("http://",$deploymentPrefix,"-identity-webapp.azurewebsites.net") -join '' )
        $displayName = "$deploymentPrefix Identity Web Application"

        if (!($identityAADApplication = Get-AzureRmADApplication -IdentifierUri $AppServiceURL)) {
        Write-Host "Creating AAD Application deployment"
        $identityAADApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $AppServiceURL -IdentifierUris $AppServiceURL -Password $secureDeploymentPassword
        $identityAdApplicationClientId = $identityAADApplication.ApplicationId.Guid
		$adAppClientId = $identityAdApplicationClientId.ToString()
        $identityAdApplicationObjectId = $identityAADApplication.ObjectId.Guid.ToString()
        Write-Host "AAD Application  was successful. AppID is $identityAdApplicationClientId" -ForegroundColor Green
        # Create a service principal for the AD Application and add a Reader role to the principal 
        Write-Host "Creating Service principal for deployment"
        $identityServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $identityAdApplicationClientId
        Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal
        Write-Host "Service principal for deployment was successful - $($identityServicePrincipal.DisplayName)"
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
                    $resourceAccess2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "5778995a-e1bf-45b8-affa-663a9f3f4d04","Role"
                    $requiredResourceAccess.ResourceAccess = $resourceAccess1,$resourceAccess2
                    $requiredResourceAccess.ResourceAppId = "00000002-0000-0000-c000-000000000000" #Resource App ID for Azure ActiveDirectory
                    Set-AzureADApplication -ObjectId $identityAdApplicationObjectId -RequiredResourceAccess $requiredResourceAccess       
        <#$ServicePrincipalId = (Get-AzureADServicePrincipal -SearchString $displayName).ObjectId.ToString()#>
        <#if ($ServicePrincipalId) {
            log "ServicePrincipal $displayName was found."
			
			log "Add reply url $replyUrl"
			Set-AzureADApplication -ObjectId $identityAdApplicationObjectId -ReplyUrls $replyUrl

            if (Get-AzureADServiceAppRoleAssignment -ObjectId $ServicePrincipalId) {
                if ((Get-AzureADServiceAppRoleAssignment -ObjectId $ServicePrincipalId).PrincipalDisplayName -contains 'Alice_ApplicationManager') {
                    log "AAD ServiceApp Role Assignment for Alice_ApplicationManager already exists."
                }
                else {
                    log "Updating ReplyUrl and AppRoles on $displayName."
                    # Update Azure AD Application with Response URLs and App Roles.
                    $manifest = Get-Content "$scriptroot\scripts\jsonscripts\aad.manifest.json" | ConvertFrom-Json
                    $requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
                    $resourceAccess1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope"
                    $resourceAccess2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "5778995a-e1bf-45b8-affa-663a9f3f4d04","Role"
                    $requiredResourceAccess.ResourceAccess = $resourceAccess1,$resourceAccess2
                    $requiredResourceAccess.ResourceAppId = "00000002-0000-0000-c000-000000000000" #Resource App ID for Azure ActiveDirectory
                    Set-AzureADApplication -ObjectId $identityAdApplicationObjectId -AppRoles $manifest.appRoles -RequiredResourceAccess $requiredResourceAccess       
            }
            }
            else {
                log "Updating ReplyUrl and AppRoles on $displayName."
                # Update Azure AD Application with Response URLs and App Roles.
                $manifest = Get-Content "$scriptroot\scripts\jsonscripts\aad.manifest.json" | ConvertFrom-Json
                $requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
                $resourceAccess1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope"
                $resourceAccess2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "5778995a-e1bf-45b8-affa-663a9f3f4d04","Role"
                $requiredResourceAccess.ResourceAccess = $resourceAccess1,$resourceAccess2
                $requiredResourceAccess.ResourceAppId = "00000002-0000-0000-c000-000000000000"
                Set-AzureADApplication -ObjectId $healthCareAdApplicationObjectId -AppRoles $manifest.appRoles -ReplyUrls $replyUrl `
                    -RequiredResourceAccess $requiredResourceAccess
            }
        }
        else {
            log "Error: Could not find ServicePrincipal with DisplayName - $displayName." Red
            Break
        }#>
    }
    catch {
        
       log $_.Exception.Message
        Break
    }

	### Create Resource Group for deployment and assigning RBAC to users.
    $components = @("artifacts","workload")
    $components | ForEach-Object { 
        $rgName = (($deploymentPrefix,$_,'rg') -join '-')
        Write-Host "Creating ResourceGroup $rgName at $location."
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

            
 #   try {
 #   $resourceGroupPrefix=$deploymentPrefix
 #   $deploymentHash = Get-StringHash(($subscriptionId,$resourceGroupPrefix ) -join '-')
 #   Publish-BuildingBlocksTemplates $deploymentHash
 #   $parameters=Get-Content 'templates/scenario1.parameters.json'|ConvertFrom-Json
	#$parameters.parameters.deployPackageURI.value="$ScriptRoot/artifacts/scenario/one/webapp/ScenarioOne.zip"
	#Remove-Item "$scriptroot\templates\scenario1.parameters.json"
	#($parameters | ConvertTo-Json -Depth 2) | Out-File "$scriptroot\templates\scenario1.parameters.json"

 #     ### Invoke ARM deployment.
 #   Write-Host "Intiating Identity Deployment."
 #   $resourceGroupdeploy=(($deploymentPrefix,'workload',$environment,'rg') -join '-')
	#New-AzureRmResourceGroupDeployment -Name 'deploy-scenario1' -ResourceGroupName "$resourceGroupdeploy"  -TemplateFile "$ScriptRoot/templates/resources/microsoft.web/app.webapp.json" -TemplateParameterFile "$ScriptRoot/templates/scenario1.parameters.json"
 #   Start-Sleep 20

 #   }
 #   catch {
 #       Write-Host $_.Exception.Message
 #       exit 1337
 #   }
}