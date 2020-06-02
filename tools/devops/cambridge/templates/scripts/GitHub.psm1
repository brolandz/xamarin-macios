function Get-TargetUrl {
    $targetUrl = $Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI + "$Env:SYSTEM_TEAMPROJECT/_build/index?buildId=$Env:BUILD_BUILDID&view=ms.vss-test-web.test-result-details"
    return $targetUrl
}

function Set-GitHubStatus {
    param
    (
        [Parameter(Mandatory)]
        [String]
        [ValidateScript({
            $("error", "failure", "pending", "success").Contains($_) #validate that the status is in the range of valid values
        })]
        $Status,

        [Parameter(Mandatory)]
        [String]
        $Description,


        [Parameter(Mandatory)]
        [String]
        $Context
    )

    # assert that all the env vars that are needed are present, else we do have an error
    $envVars = @{
        "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI" = $Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI;
        "SYSTEM_TEAMPROJECT" = $Env:SYSTEM_TEAMPROJECT;
        "BUILD_BUILDID" = $Env:BUILD_BUILDID;
        "BUILD_REVISION" = $Env:BUILD_REVISION;
        "GITHUB_TOKEN" = $Env:GITHUB_TOKEN
    }

    foreach ($key in $envVars.Keys) {
        if (-not($envVars[$key])) {
            Write-Debug "Enviroment varible missing $key"
            throw [System.InvalidOperationException]::new("Enviroment varible missing $key")
        }
    }

    # use the GitHub API to set the status for the given commit
    $targetUrl = Get-TargetUrl
    $payload= @{
        state = $Status
        target_url = $targetUrl
        description = $Description
        context = $Context
    }
    $url = "https://api.github.com/repos/xamarin/xamarin-macios/statuses/$Env:BUILD_REVISION"

    $headers = @{
        Authorization =  ("token {0}" -f $Env:GITHUB_TOKEN)
    }

    return Invoke-RestMethod -Uri $url -Headers $headers -Method "POST" -Body ($payload | ConvertTo-json) -ContentType 'application/json' -PreserveAuthorizationOnRedirect
}

function New-GitHubComment {
    param
    (
        [Parameter(Mandatory)]
        [String]
        $Header,
        
        [Parameter(Mandatory)]
        [String]
        $Description,

        [String]
        $Message,

        [String]
        $Emoji #optionally use an emoji
    )

    # assert that all the env vars that are needed are present, else we do have an error
    $envVars = @{
        "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI" = $Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI;
        "SYSTEM_TEAMPROJECT" = $Env:SYSTEM_TEAMPROJECT;
        "BUILD_DEFINITIONNAME" = $Env:BUILD_DEFINITIONNAME;
        "BUILD_REVISION" = $Env:BUILD_REVISION;
        "GITHUB_TOKEN" = $Env:GITHUB_TOKEN
    }

    foreach ($key in $envVars.Keys) {
        if (-not($envVars[$key])) {
            Write-Debug "Enviroment varible missing $key"
            throw [System.InvalidOperationException]::new("Enviroment varible missing $key")
        }
    }

    $targetUrl = Get-TargetUrl
    # build the message, which will be sent to github, users can use markdown
    $fullDescription ="$Emoji $Description on [Azure DevOps]($targetUrl) ($Env:BUILD_DEFINITIONNAME) $Emoji"
    $msg = [System.Text.StringBuilder]::new()
    $msg.AppendLine($Header)
    $msg.AppendLine()
    $msg.AppendLine($fullDescription)
    if ($Message) { # only if message is not null or empty
        $msg.AppendLine()
        $msg.AppendLine($Message)
    }

    $url = "https://api.github.com/repos/xamarin/xamarin-macios/commits/$Env:BUILD_REVISION/comments"
    $payload = @{
        body = $msg.ToString()
    }

    $headers = @{
        Authorization =  ("token {0}" -f $Env:GITHUB_TOKEN)
    }

    return Invoke-RestMethod -Uri $url -Headers $headers -Method "POST" -Body ($payload | ConvertTo-Json) -ContentType 'application/json' -PreserveAuthorizationOnRedirect
}

function New-GitHubCommentFromFile {
    param (

        [Parameter(Mandatory)]
        [String]
        $Header,
        
        [Parameter(Mandatory)]
        [String]
        $Description,

        [Parameter(Mandatory)]
        [String]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf 
        })]
        $Path,

        [String]
        $Emoji #optionally use an emoji
    )

    # read the file, create a message and use the Ne-GithubComment function
    $msg = [System.Text.StringBuilder]::new()
    foreach ($line in Get-Content -Path $Path)
    {
        $msg.AppendLine($line)
    }
    New-GithubComment -Header $Header -Description $Description -Message $msg.ToString() -Emoji $Emoji
}

# module exports
Export-ModuleMember -Function Set-GitHubStatus
Export-ModuleMember -Function New-GitHubComment
Export-ModuleMember -Function New-GitHubCommentFromFile