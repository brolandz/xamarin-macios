function Get-BuildUrl {
    Write-Host $Env:BUILD_BUILDID
    $targetUrl = $Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI + "$Env:SYSTEM_TEAMPROJECT/_apis/build/builds/" + $Env:BUILD_BUILDID + "?api-version=5.1"
    return $targetUrl
}

<#
    .SYNOPSIS
        Cancels the pipeline and no other steps of job will be executed.
#>
function Stop-Pipeline {
    # assert that all the env vars that are needed are present, else we do have an error
    $envVars = @{
        "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI" = $Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI;
        "SYSTEM_TEAMPROJECT" = $Env:SYSTEM_TEAMPROJECT;
        "BUILD_BUILDID" = $Env:BUILD_BUILDID;
        "SYSTEM_ACCESSTOKEN" = $Env:SYSTEM_ACCESSTOKEN
    }

    foreach ($key in $envVars.Keys) {
        if (-not($envVars[$key])) {
            Write-Debug "Enviroment varible missing $key"
            throw [System.InvalidOperationException]::new("Enviroment varible missing $key")
        }
    }

    $url = Get-BuildUrl
    Write-Host $url

    $headers = @{
        Authorization =  ("Bearer {0}" -f $Env:SYSTEM_ACCESSTOKEN)
    }

    $payload = @{
        status = "Cancelling"
    }

    return Invoke-RestMethod -Uri $url -Headers $headers -Method "PATCH" -Body ($payload | ConvertTo-json) -ContentType 'application/json' -PreserveAuthorizationOnRedirect
}

function Test-JobSuccess {

    param (
        [Parameter(Mandatory)]
        [String]
        $Status
    )

    # return if the status is one of the failure ones
    return $Status -eq "Succeeded"
}
Export-ModuleMember -Function Stop-Pipeline