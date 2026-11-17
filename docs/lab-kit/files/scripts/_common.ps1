$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$InfraDir = Join-Path $RootDir 'infrastructure'
$EnvFile = Join-Path $InfraDir '.env'
if (-not (Test-Path $EnvFile)) { throw "Missing $EnvFile. Copy .env.example to .env first." }
Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*([^#][^=]*)=(.*)$') { [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process') }
}
# [CampusDesk T8] Fungsi sederhana (tanpa [Parameter]) agar `-d` tidak dibaca PowerShell sebagai -Debug.
function Compose { docker compose --env-file $EnvFile -f (Join-Path $InfraDir 'docker-compose.yml') @args }
