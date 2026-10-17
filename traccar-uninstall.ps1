
& {
    $Container = 'darkverse-traccar-demo'
    $Image     = 'traccar/traccar:6.16.0'
    $Data      = "$Container-data"
    $Logs      = "$Container-logs"
    $LabelValue = 'traccar-video'
    $RemovedSomething = $false

    Write-Host "`n=== Traccar Demo Uninstaller ===" -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host 'Docker CLI not found. Start Docker Desktop first.' -ForegroundColor Red
        return
    }
    & docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Docker Desktop is not running. Start it and retry.' -ForegroundColor Red
        return
    }

    if (@(& docker ps -a --format '{{.Names}}') -contains $Container) {
        $OwnedContainers = @(& docker ps -a --filter "label=darkverse.demo=$LabelValue" --format '{{.Names}}')
        if ($OwnedContainers -notcontains $Container) {
            Write-Host 'Container exists but was not created by this demo. Nothing was deleted.' -ForegroundColor Red
            return
        }
        & docker rm -f $Container | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'Failed to remove the container. No volumes will be removed.' -ForegroundColor Red
            return
        }
        Write-Host 'Removed demo container.' -ForegroundColor Green
        $RemovedSomething = $true
    }

    foreach ($Volume in @($Data, $Logs)) {
        if (@(& docker volume ls --format '{{.Name}}') -contains $Volume) {
            $OwnedVolumes = @(& docker volume ls --filter "label=darkverse.demo=$LabelValue" --format '{{.Name}}')
            if ($OwnedVolumes -contains $Volume) {
                & docker volume rm $Volume | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Removed volume $Volume" -ForegroundColor Green
                    $RemovedSomething = $true
                } else {
                    Write-Host "Could not remove volume $Volume (it may be in use)." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Skipped unrecognized volume $Volume" -ForegroundColor Yellow
            }
        }
    }

    if ($RemovedSomething) {
        & docker image rm $Image *> $null
        Write-Host 'Attempted to remove the downloaded Traccar image (Docker may retain it if in use).'
    }
    Write-Host "`nTraccar demo cleanup finished. Other Docker containers and volumes were untouched." -ForegroundColor Green
}
