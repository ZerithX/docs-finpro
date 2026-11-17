# Menerapkan perubahan lab CampusDesk (T2, T8, T9, T10 + dasbor Grafana) ke paket dosen.
# Pemakaian (PowerShell, dari folder lab-kit ini):
#   ./apply-lab-kit.ps1 -PackageDir "D:\path\ke\Final_Project"
# PackageDir = folder paket dosen yang berisi infrastructure\, scripts\, templates\.
param([Parameter(Mandatory=$true)][string]$PackageDir)
$ErrorActionPreference = 'Stop'
foreach($d in 'infrastructure','scripts','templates'){
  if(-not (Test-Path (Join-Path $PackageDir $d))){ throw "Folder '$d' tidak ditemukan di $PackageDir. Pastikan ini folder paket dosen." }
}
$src = Join-Path $PSScriptRoot 'files'
$backup = Join-Path $PackageDir ('.lab-kit-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Get-ChildItem -Recurse -File $src | ForEach-Object {
  $rel = $_.FullName.Substring($src.Length + 1)
  $dst = Join-Path $PackageDir $rel
  if(Test-Path $dst){ $b = Join-Path $backup $rel; New-Item -ItemType Directory -Force -Path (Split-Path $b) | Out-Null; Copy-Item $dst $b }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  Copy-Item $_.FullName $dst -Force
  Write-Host "  disalin: $rel"
}
$envFile = Join-Path $PackageDir 'infrastructure\.env'
if(-not (Test-Path $envFile)){ Copy-Item (Join-Path $PackageDir 'infrastructure\.env.example') $envFile; Write-Host '  dibuat: infrastructure\.env (dari .env.example)' }
Write-Host "Selesai. File asli yang tertimpa dicadangkan di: $backup"
