<#
Pemasangan lokal dengan cadangan terverifikasi. Tidak menutup game secara paksa.
Contoh: .\Pasang-Terjemahan.ps1 -CheckOnly
         .\Pasang-Terjemahan.ps1 -GamePath "D:\Dragon's Dogma Online"
Jalankan sesuai kebijakan PowerShell yang berlaku pada komputer Anda.
#>
[CmdletBinding()]
param(
    [string]$GamePath = "D:\Dragon's Dogma Online",
    [switch]$CheckOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DDON-Indonesia.Common.ps1')

function Invoke-DDONInstall {
    $context = Get-DDONContext $GamePath $PSScriptRoot
    Assert-DDONStopped
    $package = Get-DDONPackage $context
    Assert-DDONReceiptSlots $context
    $lock = $null
    $backup = $null
    $attempted = New-Object 'System.Collections.Generic.List[object]'
    try {
        if (-not $CheckOnly) { $lock = Enter-DDONLock $context }
        $states = Get-DDONStates $package.entries
        $oldBackup = Get-DDONBackup $context
        $patched = @($package.entries | Where-Object { $states[$_.relative_path] -eq 'patched' })
        if ($patched.Count -gt 0 -and ($null -eq $oldBackup -or $oldBackup.manifest.package_manifest_sha256 -ne $package.hash)) {
            throw 'Ada file yang sudah ditambal tanpa cadangan paket yang cocok. Pulihkan paket sebelumnya dahulu.'
        }
        if ($oldBackup -and $oldBackup.manifest.package_manifest_sha256 -eq $package.hash) {
            if ($oldBackup.entries.Count -ne $package.entries.Count) { throw 'Daftar cadangan tidak cocok dengan paket.' }
            for ($i=0; $i -lt $package.entries.Count; $i++) {
                foreach ($field in @('relative_path','original_sha256','patched_sha256','original_size','patched_size')) {
                    if ([string]$package.entries[$i].$field -cne [string]$oldBackup.entries[$i].$field) { throw 'Isi cadangan tidak cocok dengan paket.' }
                }
            }
        }
        $changes = @($package.entries | Where-Object { $states[$_.relative_path] -eq 'original' -and $_.original_sha256 -ne $_.patched_sha256 })
        if ($CheckOnly) { Write-Host "Pemeriksaan berhasil: $($package.entries.Count) ARC, $($changes.Count) perlu dipasang."; return }
        if ($changes.Count -eq 0 -and $oldBackup -and $oldBackup.manifest.package_manifest_sha256 -eq $package.hash) {
            Write-DDONState $context $oldBackup 'INSTALLED'
            Write-Host 'Seluruh file paket sudah terpasang; tidak ada file game yang diubah.'
            return
        }
        if ($oldBackup -and $oldBackup.manifest.package_manifest_sha256 -eq $package.hash) {
            $backup = $oldBackup
        } else {
            $sessionName = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0,12)
            $sessionPath = Join-DDONSafe $context.backupRoot $sessionName
            New-DDONDirectory $sessionPath
            foreach ($entry in $package.entries) {
                # Semua sumber pada sesi baru harus asli; hash dicek ulang sebelum disalin.
                Assert-DDONFile $entry.target $entry.original_sha256 $entry.original_size
                $destination = Join-DDONSafe $sessionPath $entry.relative_path
                New-DDONDirectory ([IO.Path]::GetDirectoryName($destination))
                Copy-DDONNewFile $entry.target $destination
                Assert-DDONFile $destination $entry.original_sha256 $entry.original_size
            }
            $backupManifest = [ordered]@{
                schema='DDON-Indonesia-backup-v1'; game_path=$context.game; created_utc=[DateTime]::UtcNow.ToString('o')
                package_manifest_sha256=$package.hash; package_manifest=$package.manifest; files=$package.manifest.files
            }
            Write-DDONJson (Join-DDONSafe $sessionPath 'backup-manifest.json') $backupManifest
            $backup = Get-DDONBackup $context $sessionPath
        }
        # Penunjuk pemulihan ditulis sebelum satu pun ARC diganti.
        Write-DDONState $context $backup 'INSTALLING'
        Write-Host "Cadangan terverifikasi: $($backup.path)"
        foreach ($entry in $changes) {
            $attempted.Add($entry)
            Set-DDONAtomicFile $entry.source $entry.target $entry.patched_sha256 $entry.patched_size $entry.original_sha256
        }
        foreach ($entry in $package.entries) { Assert-DDONFile $entry.target $entry.patched_sha256 $entry.patched_size }
        Write-DDONState $context $backup 'INSTALLED'
        Write-Host "Terjemahan terpasang: $($package.entries.Count) ARC. Cadangan tetap disimpan."
    } catch {
        $failure = $_.Exception.Message
        $recoveryErrors = @()
        if ($backup -and $attempted.Count -gt 0) {
            for ($i=$attempted.Count-1; $i -ge 0; $i--) {
                $entry = $attempted[$i]
                try {
                    $current = Get-DDONHash $entry.target
                    if ($current -eq $entry.original_sha256) { continue }
                    if ($current -ne $entry.patched_sha256) { throw "Perubahan lain dipertahankan: $($entry.relative_path)" }
                    $original = Join-DDONSafe $backup.path $entry.relative_path
                    Set-DDONAtomicFile $original $entry.target $entry.original_sha256 $entry.original_size $entry.patched_sha256
                } catch { $recoveryErrors += $_.Exception.Message }
            }
        }
        if ($backup) {
            $status = if ($recoveryErrors.Count -eq 0) { 'INSTALL_FAILED_RECOVERED' } else { 'RECOVERY_REQUIRED' }
            try { Write-DDONState $context $backup $status ($failure + ' ' + ($recoveryErrors -join '; ')) }
            catch { $recoveryErrors += "Catatan gagal ditulis: $($_.Exception.Message)" }
        }
        if ($recoveryErrors.Count -gt 0) { $failure += " Pemulihan perlu dilanjutkan dengan Pulihkan-English.ps1. " + ($recoveryErrors -join '; ') }
        throw $failure
    } finally { if ($null -ne $lock) { $lock.Dispose() } }
}

try { Invoke-DDONInstall }
catch { [Console]::Error.WriteLine("Pemasangan dihentikan: $($_.Exception.Message)"); exit 1 }
