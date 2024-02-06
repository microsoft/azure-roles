# Connect to Azure
#Connect-AzAccount

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
