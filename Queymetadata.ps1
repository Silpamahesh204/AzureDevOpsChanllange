#Connect Azure 

$subscriptionname = "ROBT-Subscription"
$tenantID = Read-Host " Please provide the teanant ID"
#$Username ="TestUser"
#Get credentials#
$cred=Get-Credential

#$Cred = New-Object System.Management.Automation.PSCredential ("username", $password)

#Connect Azure Account
Connect-AzAccount -Subscription $subscriptionname -Credential $cred -Tenant $tenantID 

$InstanceServer = "http://169.254.169.254/"
$InstanceServerMetadata = $InstanceServer + "/metadata/instance"

$proxy=New-Object System.Net.WebProxy
$WebSession= New-Object Microsoft.PowerShell.Commands.WebRequestSession
$WebSession.Proxy =$proxy

#Get the Metadat in json format
$Metaddatauri= $InstanceServerMetadata + "?api-version=2021-02-01"

$Metadata= Invoke-RestMethod -Method Get -Uri $Metaddatauri -Headers @{"Metadata"="true"} | ConvertTo-Json

Write-Host "The Auzre instance metadata" + $Metadata
