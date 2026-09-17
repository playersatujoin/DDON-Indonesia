# Fungsi lokal bersama. Tidak mengunduh apa pun dan tidak mengubah kebijakan PowerShell.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DDONFullPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -notmatch '^[A-Za-z]:[\\/]') {
        throw "Gunakan jalur lokal absolut dengan huruf drive: $Path"
    }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Assert-DDONNoLink([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Tautan/junction tidak diizinkan: $cursor"
            }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
}

function Join-DDONSafe([string]$Root, [string]$Relative) {
    $rootFull = Get-DDONFullPath $Root
    if ([string]::IsNullOrWhiteSpace($Relative) -or $Relative -match '[\x00-\x1f:*?"<>|]' -or
        [IO.Path]::IsPathRooted($Relative)) { throw "Jalur relatif tidak sah: $Relative" }
    $parts = @($Relative -split '[\\/]')
    foreach ($part in $parts) {
        if (-not $part -or $part -eq '.' -or $part -eq '..' -or $part -match '[ .]$' -or
            $part -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') {
            throw "Bagian jalur tidak sah: $Relative"
        }
    }
    $full = [IO.Path]::GetFullPath([IO.Path]::Combine($rootFull, ($parts -join '\')))
    if (-not $full.StartsWith($rootFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Jalur keluar dari direktori yang diizinkan: $Relative"
    }
    Assert-DDONNoLink $full
    return $full
}

function Assert-DDONStopped {
    $running = @(Get-Process -ErrorAction Stop | Where-Object {
        $_.ProcessName -match '^(?i:DDO|DDON)(?:$|[_-]|32$|64$)'
    })
    if ($running.Count -gt 0) {
        throw ('Tutup game dan peluncur DDON dahulu: ' + (($running | Select-Object -ExpandProperty ProcessName -Unique) -join ', '))
    }
}

function Get-DDONHash([string]$Path) {
    Assert-DDONNoLink $Path
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File tidak ditemukan: $Path" }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}

function Assert-DDONFile([string]$Path, [string]$Hash, [long]$Size) {
    if ((Get-DDONHash $Path) -ne $Hash -or (Get-Item -LiteralPath $Path -Force).Length -ne $Size) {
        throw "Hash/ukuran file tidak cocok: $Path"
    }
}

function Read-DDONJson([string]$Path) {
    Assert-DDONNoLink $Path
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Berkas metadata tidak ditemukan: $Path" }
    try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "JSON tidak dapat dibaca: $Path. $($_.Exception.Message)" }
}

function Assert-DDONField($Object, [string]$Name) {
    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) { throw "Metadata kehilangan kolom $Name." }
}

function Get-DDONEntries($Files, [string]$GamePath, [string]$SourceRoot) {
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $entries = @()
    foreach ($file in @($Files)) {
        foreach ($field in @('relative_path','original_sha256','patched_sha256','original_size','patched_size')) {
            Assert-DDONField $file $field
        }
        $relative = [string]$file.relative_path
        if ($relative -notmatch '^(?i:nativePC[\\/]rom[\\/]).+\.arc$') {
            throw "Target harus berupa ARC dalam nativePC/rom: $relative"
        }
        $target = Join-DDONSafe $GamePath $relative
        if (-not $seen.Add($target)) { throw "Target ganda dalam manifest: $relative" }
        foreach ($field in @('original_sha256','patched_sha256')) {
            if ([string]$file.$field -notmatch '^[a-fA-F0-9]{64}$') { throw "Hash manifest tidak sah: $relative" }
        }
        foreach ($field in @('original_size','patched_size')) {
            $size = 0L
            if (-not [long]::TryParse([string]$file.$field, [ref]$size) -or $size -lt 0) {
                throw "Ukuran manifest tidak sah: $relative"
            }
        }
        $entries += [pscustomobject]@{
            relative_path = ($relative -replace '\\','/')
            original_sha256 = ([string]$file.original_sha256).ToLowerInvariant()
            patched_sha256 = ([string]$file.patched_sha256).ToLowerInvariant()
            original_size = [long]$file.original_size
            patched_size = [long]$file.patched_size
            target = $target
            source = (Join-DDONSafe $SourceRoot $relative)
        }
    }
    if ($entries.Count -eq 0) { throw 'Manifest tidak memiliki file.' }
    return $entries
}

function Get-DDONContext([string]$GamePath, [string]$PackagePath) {
    $game = Get-DDONFullPath $GamePath
    $package = Get-DDONFullPath $PackagePath
    Assert-DDONNoLink $game
    Assert-DDONNoLink $package
    $rom = Join-DDONSafe $game 'nativePC/rom'
    if (-not (Test-Path -LiteralPath $rom -PathType Container)) { throw "Direktori game tidak ditemukan: $rom" }
    return [pscustomobject]@{
        game = $game
        package = $package
        backupRoot = (Join-DDONSafe $game 'DDON-Indonesia-backup')
        pointer = (Join-DDONSafe $game 'DDON-Indonesia-backup/current.json')
        receipt = (Join-DDONSafe $package 'installation-receipt.json')
        outputPointer = (Join-DDONSafe $package 'rollback-pointer.json')
    }
}

function Get-DDONPackage($Context) {
    $manifestPath = Join-DDONSafe $Context.package 'manifest.json'
    $manifestHash = Get-DDONHash $manifestPath
    $manifest = Read-DDONJson $manifestPath
    foreach ($name in @('status','coverage_snapshot','files','archives')) { Assert-DDONField $manifest $name }
    if ($manifest.status -cne 'COMPLETE_TEXT_COVERAGE') { throw 'Paket belum lengkap. Status harus COMPLETE_TEXT_COVERAGE.' }
    foreach ($name in @('issues','source_units','processed')) { Assert-DDONField $manifest.coverage_snapshot $name }
    if ([string]$manifest.coverage_snapshot.issues -ne '0' -or
        [long]$manifest.coverage_snapshot.processed -ne [long]$manifest.coverage_snapshot.source_units -or
        [long]$manifest.coverage_snapshot.source_units -le 0) {
        throw 'Cakupan manifest belum lengkap atau masih memiliki masalah.'
    }
    $patch = Join-DDONSafe $Context.package 'patch'
    $entries = @(Get-DDONEntries $manifest.files $Context.game $patch)
    if ($entries.Count -ne [long]$manifest.archives) { throw 'Jumlah ARC tidak sesuai manifest.' }
    foreach ($entry in $entries) { Assert-DDONFile $entry.source $entry.patched_sha256 $entry.patched_size }
    if ((Get-DDONHash $manifestPath) -ne $manifestHash) { throw 'Manifest berubah saat diperiksa. Ulangi setelah pembuatan paket selesai.' }
    return [pscustomobject]@{ manifest=$manifest; hash=$manifestHash; entries=$entries }
}

function New-DDONDirectory([string]$Path) {
    Assert-DDONNoLink $Path
    [void][IO.Directory]::CreateDirectory($Path)
    Assert-DDONNoLink $Path
}

function Enter-DDONLock($Context) {
    New-DDONDirectory $Context.backupRoot
    $lockPath = Join-DDONSafe $Context.backupRoot '.operation.lock'
    try { return [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { throw 'Pemasangan/pemulihan lain sedang berjalan, atau direktori cadangan tidak dapat ditulis.' }
}

function Write-DDONJson([string]$Path, $Value) {
    Assert-DDONNoLink $Path
    New-DDONDirectory ([IO.Path]::GetDirectoryName($Path))
    $temp = $Path + '.ddon-' + [guid]::NewGuid().ToString('N') + '.tmp'
    $created = $false
    try {
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($Value | ConvertTo-Json -Depth 20))
        $stream = [IO.File]::Open($temp, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $created = $true
        try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        Assert-DDONNoLink $Path
        if (Test-Path -LiteralPath $Path) { [IO.File]::Replace($temp,$Path,[NullString]::Value) }
        else { [IO.File]::Move($temp,$Path) }
    } finally { if ($created -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force } }
}

function Copy-DDONNewFile([string]$Source, [string]$Destination) {
    Assert-DDONNoLink $Source
    Assert-DDONNoLink $Destination
    $inputStream = $null
    $outputStream = $null
    $created = $false
    $success = $false
    try {
        $inputStream = [IO.File]::Open($Source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        $outputStream = [IO.File]::Open($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $created = $true
        $inputStream.CopyTo($outputStream)
        $outputStream.Flush($true)
        $success = $true
    } finally {
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($created -and -not $success -and (Test-Path -LiteralPath $Destination)) { Remove-Item -LiteralPath $Destination -Force }
    }
}

function Set-DDONAtomicFile([string]$Source, [string]$Target, [string]$NewHash, [long]$NewSize, [string]$ExpectedHash) {
    Assert-DDONStopped
    Assert-DDONFile $Source $NewHash $NewSize
    Assert-DDONNoLink $Target
    $temp = $Target + '.ddon-' + [guid]::NewGuid().ToString('N') + '.tmp'
    $created = $false
    try {
        Copy-DDONNewFile $Source $temp
        $created = $true
        Assert-DDONFile $temp $NewHash $NewSize
        # Periksa lagi tepat sebelum pergantian agar perubahan setelah preflight tetap terlindungi.
        Assert-DDONStopped
        if ((Get-DDONHash $Target) -ne $ExpectedHash) { throw "File berubah saat proses berlangsung: $Target" }
        [IO.File]::Replace($temp,$Target,[NullString]::Value)
        Assert-DDONFile $Target $NewHash $NewSize
    } finally { if ($created -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force } }
}

function Get-DDONBackup($Context, [string]$BackupPath = '') {
    $expectedHash = $null
    if (-not $BackupPath) {
        if (-not (Test-Path -LiteralPath $Context.pointer)) { return $null }
        $pointer = Read-DDONJson $Context.pointer
        foreach ($field in @('schema','game_path','backup_path','backup_manifest_sha256')) { Assert-DDONField $pointer $field }
        if ($pointer.schema -cne 'DDON-Indonesia-pointer-v1' -or
            -not ([string]$pointer.game_path).Equals($Context.game,[StringComparison]::OrdinalIgnoreCase)) {
            throw 'Penunjuk cadangan tidak sesuai dengan game ini.'
        }
        $BackupPath = [string]$pointer.backup_path
        $expectedHash = [string]$pointer.backup_manifest_sha256
        if ($expectedHash -notmatch '^[a-fA-F0-9]{64}$') { throw 'Hash penunjuk cadangan tidak sah.' }
    }
    $backup = Get-DDONFullPath $BackupPath
    if (-not $backup.StartsWith($Context.backupRoot + '\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Cadangan harus berada dalam DDON-Indonesia-backup milik game ini.'
    }
    # Hanya satu direktori sesi, bukan akar cadangan atau subdirektori bebas.
    $relative = $backup.Substring($Context.backupRoot.Length + 1)
    if ($relative -notmatch '^\d{8}T\d{6}Z-[a-f0-9]{12}$') { throw 'Nama direktori sesi cadangan tidak sah.' }
    $backup = Join-DDONSafe $Context.backupRoot $relative
    $manifestPath = Join-DDONSafe $backup 'backup-manifest.json'
    $hash = Get-DDONHash $manifestPath
    if ($expectedHash -and $hash -ne $expectedHash) { throw 'Manifest cadangan berubah; pemulihan dihentikan.' }
    $manifest = Read-DDONJson $manifestPath
    foreach ($field in @('schema','game_path','package_manifest_sha256','package_manifest','files')) { Assert-DDONField $manifest $field }
    if ($manifest.schema -cne 'DDON-Indonesia-backup-v1' -or
        -not ([string]$manifest.game_path).Equals($Context.game,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Manifest cadangan tidak sesuai dengan game ini.'
    }
    $snapshot = $manifest.package_manifest
    foreach ($field in @('status','coverage_snapshot','files','archives')) { Assert-DDONField $snapshot $field }
    if ($snapshot.status -cne 'COMPLETE_TEXT_COVERAGE' -or [string]$snapshot.coverage_snapshot.issues -ne '0') {
        throw 'Cadangan tidak berasal dari paket lengkap yang sah.'
    }
    $entries = @(Get-DDONEntries $manifest.files $Context.game $backup)
    $snapshotEntries = @(Get-DDONEntries $snapshot.files $Context.game $backup)
    if ($entries.Count -ne $snapshotEntries.Count -or $entries.Count -ne [long]$snapshot.archives) {
        throw 'Daftar file cadangan tidak sesuai manifest paket.'
    }
    for ($i=0; $i -lt $entries.Count; $i++) {
        foreach ($field in @('relative_path','original_sha256','patched_sha256','original_size','patched_size')) {
            if ([string]$entries[$i].$field -cne [string]$snapshotEntries[$i].$field) { throw 'Isi daftar cadangan berbeda dari manifest paket.' }
        }
        Assert-DDONFile $entries[$i].source $entries[$i].original_sha256 $entries[$i].original_size
    }
    return [pscustomobject]@{ path=$backup; hash=$hash; manifest=$manifest; entries=$entries }
}

function Get-DDONStates($Entries) {
    $states = @{}
    foreach ($entry in $Entries) {
        $hash = Get-DDONHash $entry.target
        if ($hash -eq $entry.original_sha256) { $states[$entry.relative_path] = 'original' }
        elseif ($hash -eq $entry.patched_sha256) { $states[$entry.relative_path] = 'patched' }
        else { throw "File game berbeda dari versi asli/paket. Perubahan Anda dipertahankan: $($entry.relative_path)" }
    }
    return $states
}

function Assert-DDONReceiptSlots($Context) {
    foreach ($path in @($Context.receipt, $Context.outputPointer, $Context.pointer)) {
        if (Test-Path -LiteralPath $path) {
            $existing = Read-DDONJson $path
            Assert-DDONField $existing 'schema'
            if ($existing.schema -notin @('DDON-Indonesia-receipt-v1','DDON-Indonesia-pointer-v1')) {
                throw "File metadata sudah digunakan untuk keperluan lain: $path"
            }
            Assert-DDONField $existing 'game_path'
            if (-not ([string]$existing.game_path).Equals($Context.game,[StringComparison]::OrdinalIgnoreCase)) {
                throw "Metadata paket sudah menunjuk game di lokasi lain: $path"
            }
        }
    }
}

function Write-DDONState($Context, $Backup, [string]$Status, [string]$Detail = '') {
    Assert-DDONReceiptSlots $Context
    $pointer = [ordered]@{
        schema='DDON-Indonesia-pointer-v1'; game_path=$Context.game; backup_path=$Backup.path
        backup_manifest_sha256=$Backup.hash; updated_utc=[DateTime]::UtcNow.ToString('o')
        status=$Status
    }
    Write-DDONJson $Context.pointer $pointer
    Write-DDONJson $Context.outputPointer $pointer
    $receipt = [ordered]@{
        schema='DDON-Indonesia-receipt-v1'; game_path=$Context.game; backup_path=$Backup.path
        backup_manifest_sha256=$Backup.hash; package_manifest_sha256=$Backup.manifest.package_manifest_sha256
        status=$Status; updated_utc=[DateTime]::UtcNow.ToString('o'); files=@($Backup.entries.relative_path); detail=$Detail
    }
    Write-DDONJson $Context.receipt $receipt
    Write-DDONJson (Join-DDONSafe $Backup.path 'receipt.json') $receipt
}
