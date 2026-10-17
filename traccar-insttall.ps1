
& {
    $Container = 'darkverse-traccar-demo'
    $Image     = 'traccar/traccar:6.16.0'
    $Data      = "$Container-data"
    $Logs      = "$Container-logs"
    $Label     = 'darkverse.demo=traccar-video'

    Write-Host "`n=== Traccar Demo Installer ===" -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host 'Docker CLI not found. Install and start Docker Desktop first.' -ForegroundColor Red
        return
    }

    $DockerOS = & docker info --format '{{.OSType}}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Docker Desktop is not running. Start Docker Desktop and retry.' -ForegroundColor Red
        return
    }
    if ($DockerOS -ne 'linux') {
        Write-Host 'Switch Docker Desktop to Linux containers and retry.' -ForegroundColor Red
        return
    }

    if (@(& docker ps -a --format '{{.Names}}') -contains $Container) {
        Write-Host 'Demo container already exists. Run the uninstall block before reinstalling.' -ForegroundColor Yellow
        return
    }
    foreach ($Volume in @($Data, $Logs)) {
        if (@(& docker volume ls --format '{{.Name}}') -contains $Volume) {
            Write-Host "Volume $Volume already exists. Run the uninstall block first." -ForegroundColor Yellow
            return
        }
    }
    foreach ($Port in @(8082, 5055)) {
        if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1) {
            Write-Host "TCP port $Port is already in use. Free it before installing." -ForegroundColor Red
            return
        }
    }

    Write-Host 'Downloading official Traccar image...' -ForegroundColor Cyan
    & docker pull $Image
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Image download failed. No demo container was created.' -ForegroundColor Red
        return
    }

    foreach ($Volume in @($Data, $Logs)) {
        & docker volume create --label $Label $Volume | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to create volume $Volume. Run the uninstall block to clean up." -ForegroundColor Red
            return
        }
    }

    Write-Host 'Starting Traccar...' -ForegroundColor Cyan
    & docker run -d `
        --name $Container `
        --label $Label `
        --restart unless-stopped `
        -p '127.0.0.1:8082:8082' `
        -p '5055:5055/tcp' `
        -v "${Data}:/opt/traccar/data" `
        -v "${Logs}:/opt/traccar/logs" `
        $Image | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Container startup failed. Check port usage and run the uninstall block.' -ForegroundColor Red
        return
    }

    Write-Host "`nTraccar demo container created successfully." -ForegroundColor Green
    Write-Host 'Dashboard (on this PC): http://localhost:8082'
    Write-Host 'Phone/Traccar Client (same LAN): http://WINDOWS-PC-IP:5055'
    Write-Host 'Wait for the application to initialize, then register the first admin account.'
    Write-Host "Container logs: docker logs -f $Container"
    & docker ps --filter "name=^/${Container}$"
}
