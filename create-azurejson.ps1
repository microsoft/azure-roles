# Connect to Azure

$azResourceModule = Get-module -Name Az.Resources
if ($azResourceModule -eq $null) {
    Install-Module -Name Az.Resources -Repository PSGallery -Force
}

$azAccountModule = Get-module -Name Az.Accounts
if ($azAccountModule -eq $null) {
    Install-Module -Name Az.Accounts -Repository PSGallery -Force
}

$SecurePassword = ConvertTo-SecureString -String "$env:CLIENT_SECRET"-AsPlainText -Force
$TenantId = "$env:TENANT_ID"
$ApplicationId = "$env:CLIENT_ID"
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential | Out-Null

# Retrieve role definitions and create a custom object
$roleMappings = @{}
Get-AzRoleDefinition | ForEach-Object {
    $roleMappings[($_.Name -replace ' ', '')] = $_.Id
}

# Convert the custom object to JSON
$json = $roleMappings | ConvertTo-Json

# Convert JSON to PowerShell object
$jsonObject = $json | ConvertFrom-Json

# Convert to hashtable, sort it and then to custom object
$sortedHashtable = @{}
$jsonObject.PSObject.Properties | ForEach-Object { 
    if ($_.Name -notmatch "IsFixedSize|IsReadOnly|IsSynchronized|Keys") {
        $sortedHashtable[$_.Name] = $_.Value
    }
}
$sortedObject = New-Object PSObject
$sortedHashtable.GetEnumerator() | Sort-Object Name | ForEach-Object { 
    $sortedObject | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value 
}

# Convert back to JSON, specify the depth to ensure all nested objects are converted
$sortedJson = $sortedObject | ConvertTo-Json -Depth 5

# Output the sorted JSON
$sortedJson | Out-File "azure_roles.json"

git add azure_roles.json
git commit -m "updating file"
git push