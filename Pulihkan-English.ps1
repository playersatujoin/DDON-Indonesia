<#
Memulihkan hanya ARC dalam manifest cadangan; mod/perubahan lain tidak ditimpa.
Contoh: .\Pulihkan-English.ps1 -CheckOnly
         .\Pulihkan-English.ps1 -GamePath "D:\Dragon's Dogma Online"
Jika penunjuk hilang, gunakan -BackupPath dengan direktori sesi di DDON-Indonesia-backup.
#>
[CmdletBinding()]
param(
    [string]$GamePath = "D:\Dragon's Dogma Online",
    [string]$BackupPath = '',
    [switch]$CheckOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DDON-Indonesia.Common.ps1')

function Invoke-DDONRestore {
    $context = Get-DDONContext $GamePath $PSScriptRoot
    Assert-DDONStopped
    Assert-DDONReceiptSlots $context
    $lock = $null
    $backup = $null
    $started = $false
    try {
        if (-not $CheckOnly) { $lock = Enter-DDONLock $context }
        $backup = Get-DDONBackup $context $BackupPath
        if ($null -eq $backup) { throw 'Cadangan belum ditemukan. Gunakan -BackupPath jika penunjuk sesi hilang.' }
        # Periksa SEMUA cadangan dan SEMUA target dahulu. Satu mod berbeda membatalkan seluruh pemulihan.
        $states = Get-DDONStates $backup.entries
        $changes = @($backup.entries | Where-Object { $states[$_.relative_path] -eq 'patched' })
        if ($CheckOnly) { Write-Host "Pemeriksaan berhasil: $($backup.entries.Count) ARC, $($changes.Count) perlu dipulihkan."; return }
        Write-DDONState $context $backup 'RESTORING'
        $started = $true
        foreach ($entry in $changes) {
            Set-DDONAtomicFile $entry.source $entry.target $entry.original_sha256 $entry.original_size $entry.patched_sha256
        }
        foreach ($entry in $backup.entries) { Assert-DDONFile $entry.target $entry.original_sha256 $entry.original_size }
        Write-DDONState $context $backup 'RESTORED'
        Write-Host "English asli dipulihkan: $($backup.entries.Count) ARC. Cadangan tetap disimpan."
    } catch {
        $failure = $_.Exception.Message
        if ($backup -and $started) {
            try { Write-DDONState $context $backup 'RESTORE_INTERRUPTED' $failure }
            catch { $failure += " Catatan gagal ditulis: $($_.Exception.Message)" }
            $failure += ' Cadangan tetap tersedia; jalankan pemulihan lagi setelah penyebabnya teratasi.'
        }
        throw $failure
    } finally { if ($null -ne $lock) { $lock.Dispose() } }
}

try { Invoke-DDONRestore }
catch { [Console]::Error.WriteLine("Pemulihan dihentikan: $($_.Exception.Message)"); exit 1 }
