function New-JiraHeader {
    <#
    .SYNOPSIS
        Generate the auth header for a JIRA request
    .DESCRIPTION
        Using password and username generate auth header.
    #>
    Param ([string]$jira_username, [string]$jira_password)
    $pair = "$($jira_username):$($jira_password)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    return @{Authorization = $basicAuthValue}
}
Export-ModuleMember -Function New-JiraHeader

function Get-JiraIssueAttachments {
    <#
    .SYNOPSIS
        Get all attachments on a JIRA issue
    .DESCRIPTION
        Get all JIRA issue attachments
    #>
    Param ([string]$issueId, [System.Collections.IDictionary]$headers, [String]$url)
    $content = Invoke-WebRequest -Uri $url/rest/api/latest/issue/$issueId -Headers $headers -ContentType "application/json"
    $jsonobj = $content.content | ConvertFrom-Json
    return $jsonobj.fields.attachment
}
Export-ModuleMember -Function Get-JiraIssueAttachments

function Get-JiraIssueCSV {
    <#
    .SYNOPSIS
        Get asll JIRA attachments that end in .csv
    .DESCRIPTION
        Get all .CSV attachments on a JIRA issue
    #>
    Param ([System.Object]$attachments, [System.Collections.IDictionary]$headers)
    $csv_files = @()
    foreach ($file in $attachments) {
        if ($file.filename.Contains("csv")) {
            $csv_files += $file
        }
    }
    return $csv_files
}
Export-ModuleMember -Function Get-JiraIssueCSV

function Get-LatestJiraIssueCSVByDateModified {
    <#
    .SYNOPSIS
        Get the latest .CSV by created date attached to a JIRA issue
    .DESCRIPTION
        Get the latest .CSV by created date attached to a JIRA issue
    #>
    Param ([System.Object]$csvFiles)
    $latest_csv = [System.Object]
    $latest_date = 0
    foreach ($csv in $csvFiles) {
        if ($csv.created.Ticks -gt $latest_date) {
            $latest_date = $csv.created.Ticks
            $latest_csv = $csv
        }
    }
    return $latest_csv
}
Export-ModuleMember -Function Get-LatestJiraIssueCSVByDateModified

function Get-MostRecentJIRSCSV {
    <#
    .SYNOPSIS
        Parent function to leverage above tasks to return the latest CSV file from a JIRA issue
    .DESCRIPTION
        Parent function to leverage above tasks to return the latest CSV file from a JIRA issue
    #>
    Param ([string]$issueID, [System.Collections.IDictionary]$headers, [String]$url)
    $attachments = Get-JiraIssueAttachments -issue $issueId -headers $headers -url $url
    $csvFiles = Get-JiraIssueCSV -attachments $attachments
    $latest_csv = Get-LatestJiraIssueCSVByDateModified -csvFiles $csvFiles
    return $latest_csv
}
Export-ModuleMember -Function Get-MostRecentJIRSCSV

function Get-JiraAttachment {  
    <#
    .SYNOPSIS
        Download Jira attachment
    .DESCRIPTION
        Download Jira attachment
    #>  
    Param ([string]$contentUrl, [System.Collections.IDictionary]$headers, [string]$filename)
    $filename = "$(Get-Random)-$filename"
    Invoke-WebRequest -Uri $contentUrl -Headers $headers -OutFile $filename
    return $filename
}
Export-ModuleMember -Function Get-JiraAttachment

function Add-JiraComment {
    <#
    .SYNOPSIS
        Add Jira comments
    .DESCRIPTION
        Add Jira comments
    #>  
    Param ([string]$issueId, [System.Collections.IDictionary]$headers, [String]$jira_url, [string]$comment)
    
    if ($headers.'Content-Type') {$headers.'Content-Type' = "application/json"}
    else {$headers.Add("Content-Type","application/json")}
    
    if ($headers.'X-Atlassian-Token') {$headers.'X-Atlassian-Token' = "no-check"}
    else {$headers.Add("X-Atlassian-Token","no-check")}

    $body_hash = @{
        body = $comment;
    } 
    $body = $body_hash | ConvertTo-Json
    $response = Invoke-WebRequest -Uri $jira_url/rest/api/latest/issue/$issueId/comment -Headers $headers -Method Post -Body $body -Verbose
    return $response
}
Export-ModuleMember -Function Add-JiraComment

function Add-JiraAttachment {
    <#
    .SYNOPSIS
        Upload Jira attachment
    .DESCRIPTION
        Upload Jira attachment
    #>  
    Param ([string]$issueId, [System.Collections.IDictionary]$headers, [String]$jira_url, [string]$file)
    
    if ($headers.'Content-Type') {$headers.'Content-Type' = "multipart/form-data"}
    else {$headers.Add("Content-Type","multipart/form-data")}
    
    if ($headers.'X-Atlassian-Token') {$headers.'X-Atlassian-Token' = "no-check"}
    else {$headers.Add("X-Atlassian-Token","no-check")}

    $form = @{ file = Get-Item $file }
    $response = Invoke-WebRequest -Form $form -Uri $jira_url/rest/api/latest/issue/$issueId/attachments -Headers $headers -Method Post -Verbose
    return $response
}
Export-ModuleMember -Function Add-JiraAttachment

function Read-CSV {
    <#
    .SYNOPSIS
        Read CSV from local
    .DESCRIPTION
        Read CSV from local
    #>
    Param ([string]$filename)
    Write-Output $filename
    return Import-Csv -Path .\$filename
}
Export-ModuleMember -Function Read-CSV

function Remove-CSV {
    <#
    .SYNOPSIS
        Remove CSV from local
    .DESCRIPTION
        Remove CSV from local
    #>
    Param ([string]$filename)
    Write-Output "Deleting $filename"
    Remove-Item $filename
}
Export-ModuleMember -Function Remove-CSV
