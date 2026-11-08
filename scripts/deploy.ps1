param(
    [Parameter(Mandatory=$true)][string]$Image,
    [Parameter(Mandatory=$true)][string]$Version,
    [int]$Port = 8090
)
$ErrorActionPreference = 'Stop'
$dockerExe = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
if (-not (Test-Path -LiteralPath $dockerExe)) { $dockerExe = (Get-Command docker -ErrorAction Stop).Source }
function Invoke-Docker {
    param([string[]]$DockerArgs)
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $result = & $dockerExe @DockerArgs 2>&1 | ForEach-Object { "$_" }
        $dockerExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    if ($dockerExit -ne 0) { throw "docker $($DockerArgs -join ' ') failed: $result" }
    return $result
}
$network = 'tk-hw3-network'
$proxy = 'tk-hw3-proxy'
$candidate = 'tk-hw3-app-' + $Version.Substring(0,12) + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6)
$baseUrl = "http://127.0.0.1:$Port"
$proof = Join-Path $env:TEMP ('hw3-deploy-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $proof | Out-Null
$proxyExists = (& $dockerExe ps -a --filter "name=^/$proxy$" --format '{{.Names}}') -eq $proxy
$previousApps = @(& $dockerExe ps -a --filter 'label=hw3.role=app' --format '{{.Names}}')
$oldConf = $null
$oldVersion = $null
$monitor = $null
$switched = $false
$utf8 = [Text.UTF8Encoding]::new($false)
try {
    if ($proxyExists) {
        $oldVersion = (Invoke-RestMethod -Uri "$baseUrl/version.json" -TimeoutSec 5).version
        $oldConf = (Invoke-Docker -DockerArgs @('exec',$proxy,'cat','/etc/nginx/conf.d/default.conf')) -join "`n"
        [IO.File]::WriteAllText((Join-Path $proof 'phase.txt'), 'before', $utf8)
        $monitor = Start-Job -ArgumentList $baseUrl,$proof -ScriptBlock {
            param($base,$folder)
            $log = Join-Path $folder 'requests.csv'
            'Time,Phase,Path,Status,Version' | Set-Content -LiteralPath $log -Encoding utf8
            $paths = @('/','/script.js','/style.css','/version.json')
            while (-not (Test-Path -LiteralPath (Join-Path $folder 'stop.txt'))) {
                foreach ($path in $paths) {
                    $phase = [IO.File]::ReadAllText((Join-Path $folder 'phase.txt'))
                    $status = 0; $v = ''
                    try {
                        $response = Invoke-WebRequest -UseBasicParsing -Uri ($base+$path) -TimeoutSec 3 -Headers @{'Cache-Control'='no-cache'}
                        $status = [int]$response.StatusCode
                        if ($path -eq '/version.json') { $v = ($response.Content | ConvertFrom-Json).version }
                    } catch { $status = 0 }
                    ('{0},{1},{2},{3},{4}' -f [DateTime]::UtcNow.ToString('o'),$phase,$path,$status,$v) | Add-Content -LiteralPath $log -Encoding utf8
                }
                Start-Sleep -Milliseconds 100
            }
        }
        $monitorDeadline = [DateTime]::UtcNow.AddSeconds(20)
        while (-not (Test-Path -LiteralPath (Join-Path $proof 'requests.csv'))) {
            if ([DateTime]::UtcNow -gt $monitorDeadline) { throw 'Request monitor failed to start.' }
            Start-Sleep -Milliseconds 200
        }
        Start-Sleep -Seconds 2
        [IO.File]::WriteAllText((Join-Path $proof 'phase.txt'), 'during', $utf8)
    }
    Invoke-Docker -DockerArgs @('pull',$Image) | Write-Output
    $netNames = @(Invoke-Docker -DockerArgs @('network','ls','--format','{{.Name}}'))
    if ($network -notin $netNames) { Invoke-Docker -DockerArgs @('network','create',$network) | Out-Null }
    Invoke-Docker -DockerArgs @('run','-d','--name',$candidate,'--network',$network,'--label','hw3.role=app','--restart','unless-stopped',$Image) | Write-Output
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        $health = & $dockerExe inspect --format '{{.State.Health.Status}}' $candidate
        if ($health -eq 'healthy') { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'New container did not become healthy.' }
    $candidateVersion = ((Invoke-Docker -DockerArgs @('exec',$candidate,'wget','-qO-','http://127.0.0.1/version.json')) -join '') | ConvertFrom-Json
    if ($candidateVersion.version -ne $Version) { throw 'Candidate version does not match requested commit.' }
    $config = @"
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://${candidate}:80;
        proxy_http_version 1.1;
        proxy_set_header Host `$host;
        proxy_set_header Connection "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store" always;
    }
}
"@
    $configFile = Join-Path $proof 'default.conf'
    [IO.File]::WriteAllText($configFile, $config, $utf8)
    if (-not $proxyExists) {
        Invoke-Docker -DockerArgs @('create','--name',$proxy,'--network',$network,'--label','hw3.role=proxy','--restart','unless-stopped','-p',"127.0.0.1:${Port}:80",'nginx:alpine') | Out-Null
    }
    Invoke-Docker -DockerArgs @('cp',$configFile,"${proxy}:/etc/nginx/conf.d/default.conf") | Out-Null
    if ($proxyExists) {
        Invoke-Docker -DockerArgs @('exec',$proxy,'nginx','-t') | Write-Output
        Invoke-Docker -DockerArgs @('exec',$proxy,'nginx','-s','reload') | Write-Output
    } else { Invoke-Docker -DockerArgs @('start',$proxy) | Write-Output }
    $switched = $true
    $newVersionSeen = $false
    for ($i = 0; $i -lt 30; $i++) {
        try {
            if ((Invoke-RestMethod -Uri "$baseUrl/version.json" -TimeoutSec 3).version -eq $Version) { $newVersionSeen = $true; break }
        } catch { }
        Start-Sleep -Milliseconds 500
    }
    if (-not $newVersionSeen) { throw 'New version was not served through the proxy.' }
    foreach ($path in @('/','/health','/script.js','/style.css','/images/liu-bei.png')) {
        $response = Invoke-WebRequest -UseBasicParsing -Uri ($baseUrl+$path) -TimeoutSec 5
        if ($response.StatusCode -ne 200) { throw "Post-deployment check failed: $path" }
    }
    if ($monitor) { [IO.File]::WriteAllText((Join-Path $proof 'phase.txt'), 'after', $utf8) }
    # Allow old nginx workers and in-flight requests to finish before removing old apps.
    Start-Sleep -Seconds 5
    foreach ($previous in $previousApps) {
        if ($previous -and $previous -ne $candidate) { Invoke-Docker -DockerArgs @('rm','-f',$previous) | Out-Null }
    }
    Start-Sleep -Seconds 3
    if ($monitor) {
        [IO.File]::WriteAllText((Join-Path $proof 'stop.txt'), 'stop', $utf8)
        $monitor | Wait-Job -Timeout 15 | Out-Null
        if ($monitor.State -ne 'Completed') { throw 'Request monitor did not finish.' }
        Receive-Job -Job $monitor -ErrorAction Stop | Out-Null
        $rows = @(Import-Csv -LiteralPath (Join-Path $proof 'requests.csv'))
        $failed = @($rows | Where-Object { $_.Status -ne '200' })
        foreach ($phase in @('before','during','after')) {
            if (@($rows | Where-Object { $_.Phase -eq $phase }).Count -lt 1) { throw "Missing samples in phase: $phase" }
        }
        $oldSeen = @($rows | Where-Object { $_.Version -eq $oldVersion }).Count -gt 0
        $newSeen = @($rows | Where-Object { $_.Version -eq $Version }).Count -gt 0
        $summary = @"
## CD deployment verification

| Metric | Result |
|---|---|
| Total HTTP requests | $($rows.Count) |
| Successful responses | $($rows.Count - $failed.Count) |
| Failed responses | $($failed.Count) |
| Previous commit observed | $oldSeen |
| New commit observed | $newSeen |
| Old version | $oldVersion |
| New version | $Version |
| Service | http://localhost:$Port |

The sampled requests covered before, during and after replacement. This result applies to the sampled requests, not a guarantee for every possible client request.
"@
        [IO.File]::WriteAllText((Join-Path $proof 'summary.md'), $summary, $utf8)
        if ($env:GITHUB_STEP_SUMMARY) { $summary | Out-File -LiteralPath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
        if ($failed.Count -gt 0 -or -not $oldSeen -or -not $newSeen) { throw 'Continuity verification failed. See requests.csv.' }
    } else {
        $summary = "## CD initial deployment succeeded`n`nCommit: $Version`n`nService: http://localhost:$Port`n`nThis is the first deployment. Before/during/after continuity is verified on the next update."
        [IO.File]::WriteAllText((Join-Path $proof 'summary.md'), $summary, $utf8)
        if ($env:GITHUB_STEP_SUMMARY) { $summary | Out-File -LiteralPath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
    }
    Write-Output "Deployment verified: $baseUrl commit=$Version"
} catch {
    if ($oldConf) {
        $rollbackFile = Join-Path $proof 'rollback.conf'
        [IO.File]::WriteAllText($rollbackFile,$oldConf,$utf8)
        & $dockerExe cp $rollbackFile "${proxy}:/etc/nginx/conf.d/default.conf"
        & $dockerExe exec $proxy nginx -t
        if ($LASTEXITCODE -eq 0) { & $dockerExe exec $proxy nginx -s reload }
    }
    throw
} finally {
    if ($monitor) {
        [IO.File]::WriteAllText((Join-Path $proof 'stop.txt'), 'stop', $utf8)
        $monitor | Wait-Job -Timeout 10 | Out-Null
        if ($monitor.State -eq 'Running') { $monitor | Stop-Job }
        $monitor | Remove-Job -Force
    }
    if ($env:GITHUB_OUTPUT) { "proof_dir=$proof" | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
    Write-Output "Evidence folder: $proof"
}
