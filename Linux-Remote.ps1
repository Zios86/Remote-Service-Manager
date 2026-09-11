# Linux backend for Remote Service Manager.
# Runs on Windows PowerShell 5.1 and uses the built-in Windows OpenSSH client.

function Assert-LinuxConnectionSettings {
    if ($script:ConnectedComputer -notmatch '^(?!-)[a-zA-Z0-9._:-]+$') {
        throw 'Имя или IP Linux-компьютера содержит недопустимые символы.'
    }
    if ([string]::IsNullOrWhiteSpace($script:LinuxUser) -or $script:LinuxUser -notmatch '^[a-zA-Z0-9._@\\-]+$') {
        throw 'Имя пользователя Linux содержит недопустимые символы. Допустимы user, user@domain и DOMAIN\user.'
    }
    if ($script:LinuxPort -lt 1 -or $script:LinuxPort -gt 65535) {
        throw 'Порт SSH должен находиться в диапазоне 1–65535.'
    }
    if ($script:LinuxKeyPath -and -not (Test-Path -LiteralPath $script:LinuxKeyPath -PathType Leaf)) {
        throw "Файл SSH-ключа не найден: $($script:LinuxKeyPath)"
    }
}

function ConvertTo-WindowsNativeArgument {
    param([AllowEmptyString()][string]$Value)
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($slashes * 2) + 1)))
            [void]$builder.Append('"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { [void]$builder.Append(('\' * $slashes)); $slashes = 0 }
        [void]$builder.Append($character)
    }
    if ($slashes -gt 0) { [void]$builder.Append(('\' * ($slashes * 2))) }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Test-LinuxTcpEndpoint {
    param([ValidateRange(1,30)][int]$TimeoutSeconds = 5)

    Assert-LinuxConnectionSettings
    $client = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $null
    try {
        $asyncResult = $client.BeginConnect(
            $script:ConnectedComputer,
            $script:LinuxPort,
            $null,
            $null
        )
        if (-not $asyncResult.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($TimeoutSeconds))) {
            throw "TCP-порт $($script:LinuxPort) не ответил за $TimeoutSeconds сек."
        }
        $client.EndConnect($asyncResult)
    }
    catch {
        $reason = $_.Exception.Message
        throw @"
Не удалось установить TCP-соединение с Linux-компьютером.

Адрес: $($script:ConnectedComputer)
Порт SSH: $($script:LinuxPort)
Причина: $reason

Проверьте подключение к корпоративной сети/VPN, правильность адреса и порта,
правила межсетевого экрана и работу sshd на Linux. Проверка в PowerShell:
Test-NetConnection $($script:ConnectedComputer) -Port $($script:LinuxPort)
"@
    }
    finally {
        if ($null -ne $asyncResult -and $null -ne $asyncResult.AsyncWaitHandle) {
            $asyncResult.AsyncWaitHandle.Close()
        }
        $client.Close()
    }
}

function Invoke-LinuxSshCommand {
    param(
        [Parameter(Mandatory)][string]$Command,
        [switch]$AllowFailure,
        [ValidateRange(5,120)][int]$TimeoutSeconds = 45
    )
    Assert-LinuxConnectionSettings
    if ($null -ne $script:ActiveSshProcess -and -not $script:ActiveSshProcess.HasExited) {
        throw 'Другая SSH-операция ещё выполняется.'
    }
    $ssh = Get-Command 'ssh.exe' -ErrorAction SilentlyContinue
    if ($null -eq $ssh) { $ssh = Get-Command 'ssh' -ErrorAction SilentlyContinue }
    if ($null -eq $ssh) {
        throw 'Не найден клиент OpenSSH (ssh.exe). Установите компонент Windows «Клиент OpenSSH».'
    }

    $arguments = @(
        '-T',
        '-o','BatchMode=yes',
        '-o','ConnectTimeout=10',
        '-o','ServerAliveInterval=15',
        '-o','ServerAliveCountMax=2',
        '-o','StrictHostKeyChecking=yes',
        '-o','ClearAllForwardings=yes',
        '-o','ForwardAgent=no',
        '-o','ForwardX11=no',
        '-p',[string]$script:LinuxPort
    )
    if ($script:LinuxKeyPath) {
        $arguments += @('-o','IdentitiesOnly=yes','-i', $script:LinuxKeyPath)
    }
    # -l отделяет имя пользователя от адреса узла. Это важно для доменных UPN
    # вида user@domain: конструкция user@domain@host неоднозначна.
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Command))
    $wrappedCommand = "printf '%s' '$encodedCommand' | base64 -d | timeout --signal=TERM ${TimeoutSeconds}s sh"
    $arguments += @('-l', $script:LinuxUser, $script:ConnectedComputer, $wrappedCommand)

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $ssh.Source
    $startInfo.Arguments = (@($arguments | ForEach-Object { ConvertTo-WindowsNativeArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    try {
        $startInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
        $startInfo.StandardErrorEncoding = [Text.Encoding]::UTF8
    } catch { }

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'Не удалось запустить клиент SSH.' }
    $script:ActiveSshProcess = $process
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds + 20)
    try {
        while (-not $process.HasExited) {
            if ([DateTime]::UtcNow -ge $deadline) {
                try { $process.Kill() } catch { }
                throw "SSH-команда превысила общий тайм-аут $($TimeoutSeconds + 20) сек."
            }
            if ($null -ne $window) {
                $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
            }
            Start-Sleep -Milliseconds 50
        }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        $text = (($stdoutTask.Result, $stderrTask.Result) -join "`n").TrimEnd()
        $output = if ($text) { @($text -split '\r?\n') } else { @() }
    }
    finally {
        $script:ActiveSshProcess = $null
        $process.Dispose()
    }
    $result = [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $message = ($output -join "`n").Trim()
        if (-not $message) { $message = "SSH завершился с кодом $exitCode." }
        throw $message
    }
    return $result
}

function ConvertFrom-SystemctlShow {
    param([string[]]$Lines)
    $items = New-Object System.Collections.Generic.List[object]
    $values = @{}
    foreach ($line in @($Lines) + '') {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($values.ContainsKey('Id') -and $values.Id) {
                $items.Add([pscustomobject]@{
                    Name = [string]$values.Id
                    Description = [string]$values.Description
                    ActiveState = [string]$values.ActiveState
                    SubState = [string]$values.SubState
                    UnitFileState = [string]$values.UnitFileState
                    MainPID = if ($values.MainPID) { [int64]$values.MainPID } else { 0 }
                    FragmentPath = [string]$values.FragmentPath
                    User = [string]$values.User
                })
            }
            $values = @{}
            continue
        }
        $separator = $line.IndexOf('=')
        if ($separator -gt 0) {
            $values[$line.Substring(0,$separator)] = $line.Substring($separator + 1)
        }
    }
    return @($items)
}

function Convert-LinuxActiveState {
    param([string]$ActiveState)
    $state = switch ($ActiveState) {
        'active'       { 'Running' }
        'inactive'     { 'Stopped' }
        'failed'       { 'Failed' }
        'activating'   { 'Starting' }
        'deactivating' { 'Stopping' }
        'reloading'    { 'Reloading' }
        'maintenance'  { 'Maintenance' }
        default        { if ($ActiveState) { $ActiveState } else { 'Unknown' } }
    }
    return $state
}

function Convert-LinuxUnitFileState {
    param([string]$UnitFileState)
    if ($UnitFileState -in @('enabled','enabled-runtime')) { return 'Auto' }
    if ($UnitFileState -in @('masked','masked-runtime')) { return 'Disabled' }
    return 'Manual'
}

function Get-LinuxServiceInventory {
    param([string[]]$Names = @())
    $properties = 'Id,Description,ActiveState,SubState,UnitFileState,MainPID,FragmentPath,User'
    if ($Names.Count -gt 0) {
        foreach ($name in $Names) {
            if ($name -notmatch '^(?!-)[a-zA-Z0-9_.@:-]+\.service$') { throw "Недопустимое имя службы: $name" }
        }
        $units = $Names -join ' '
        $command = "LC_ALL=C systemctl show $units --no-pager --property=$properties"
    }
    else {
        $command = 'LC_ALL=C; units=$(systemctl list-unit-files --type=service --no-legend --no-pager | awk ''{print $1}''); if [ -n "$units" ]; then systemctl show $units --no-pager --property={0}; fi' -f $properties
    }
    $result = Invoke-LinuxSshCommand -Command $command
    return @(ConvertFrom-SystemctlShow -Lines $result.Output)
}

function Test-LinuxConnection {
    Test-LinuxTcpEndpoint -TimeoutSeconds 5
    $requiredCommands = 'systemctl base64 timeout ps awk getconf'
    $probe = 'for c in {0}; do command -v "$c" >/dev/null 2>&1 || {{ printf "RSM_MISSING|%s" "$c"; exit 3; }}; done; printf "RSM_LINUX_OK|"; id -un; printf "|"; systemctl --version | {{ IFS= read -r line; printf "%s" "$line"; }}' -f $requiredCommands
    $result = Invoke-LinuxSshCommand -Command $probe -AllowFailure
    $text = ($result.Output -join ' ').Trim()
    if ($result.ExitCode -ne 0 -or $text -notmatch 'RSM_LINUX_OK') {
        if ($text -match 'RSM_MISSING\|([^\s]+)') {
            throw "На Linux-компьютере не найдена обязательная команда: $($matches[1])."
        }
        if ($text -match '(?i)permission denied') {
            throw "TCP-порт SSH доступен, но сервер отклонил аутентификацию. Проверьте имя пользователя, выбранный закрытый ключ, ssh-agent и наличие открытого ключа в authorized_keys. Ответ SSH: $text"
        }
        if ($text -match '(?i)host key verification failed|remote host identification has changed') {
            throw "Не пройдена проверка ключа SSH-сервера. Сверьте отпечаток с администратором Linux и исправьте запись known_hosts. Ответ SSH: $text"
        }
        if ($text) { throw "Проверка Linux-компьютера завершилась ошибкой: $text" }
        throw "Проверка Linux-компьютера завершилась с кодом $($result.ExitCode)."
    }
    return $text.Replace('RSM_LINUX_OK|','')
}

function ConvertTo-LinuxElevatedCommand {
    param([Parameter(Mandatory)][string]$BaseCommand)
    return ('if [ "$(id -u)" -eq 0 ]; then {0}; else sudo -n {0}; fi' -f $BaseCommand)
}

function Invoke-LinuxSystemctlAction {
    param(
        [Parameter(Mandatory)][string[]]$Names,
        [Parameter(Mandatory)][ValidateSet('Start','Stop','Restart')][string]$Action,
        [bool]$Unmask = $false
    )
    foreach ($name in $Names) {
        if ($name -notmatch '^(?!-)[a-zA-Z0-9_.@:-]+\.service$') { throw "Недопустимое имя службы: $name" }
    }
    $units = $Names -join ' '
    $verb = $Action.ToLowerInvariant()
    $baseCommand = "systemctl $verb $units"
    if ($Unmask -and $Action -in @('Start','Restart')) {
        $unmaskResult = Invoke-LinuxSshCommand -Command (ConvertTo-LinuxElevatedCommand "systemctl unmask $units") -AllowFailure
        if ($unmaskResult.ExitCode -ne 0) {
            $services = @(Get-LinuxServiceInventory -Names $Names)
            return [pscustomobject]@{ ExitCode=$unmaskResult.ExitCode; Output=$unmaskResult.Output; Services=$services }
        }
    }
    $commandResult = Invoke-LinuxSshCommand -Command (ConvertTo-LinuxElevatedCommand $baseCommand) -AllowFailure
    $services = @(Get-LinuxServiceInventory -Names $Names)
    return [pscustomobject]@{ ExitCode=$commandResult.ExitCode; Output=$commandResult.Output; Services=$services }
}

function Set-LinuxStartupType {
    param([Parameter(Mandatory)][string[]]$Names,[Parameter(Mandatory)][string]$StartupType)
    foreach ($name in $Names) {
        if ($name -notmatch '^(?!-)[a-zA-Z0-9_.@:-]+\.service$') { throw "Недопустимое имя службы: $name" }
    }
    $units = $Names -join ' '
    if ($StartupType -in @('Automatic','Manual')) {
        $unmaskResult = Invoke-LinuxSshCommand -Command (ConvertTo-LinuxElevatedCommand "systemctl unmask $units") -AllowFailure
        if ($unmaskResult.ExitCode -ne 0) {
            $services = @(Get-LinuxServiceInventory -Names $Names)
            return [pscustomobject]@{ ExitCode=$unmaskResult.ExitCode; Output=$unmaskResult.Output; Services=$services }
        }
    }
    $verb = switch ($StartupType) {
        'Automatic' { 'enable' }
        'Manual'    { 'disable' }
        'Disabled'  { 'mask' }
        default     { throw "Тип запуска $StartupType не поддерживается в Linux." }
    }
    $commandResult = Invoke-LinuxSshCommand -Command (ConvertTo-LinuxElevatedCommand "systemctl $verb $units") -AllowFailure
    $services = @(Get-LinuxServiceInventory -Names $Names)
    return [pscustomobject]@{ ExitCode=$commandResult.ExitCode; Output=$commandResult.Output; Services=$services }
}

function Convert-LinuxCpuTimeToSeconds {
    param([string]$Value)
    if ($Value -notmatch '^(?:(\d+)-)?(?:(\d+):)?(\d+):(\d+)$') { return 0.0 }
    return (([double]$matches[1] * 86400) + ([double]$matches[2] * 3600) +
        ([double]$matches[3] * 60) + [double]$matches[4])
}

function Get-LinuxProcessInventory {
    $command = "printf 'RSM_CPUS|'; getconf _NPROCESSORS_ONLN; LC_ALL=C ps -eo pid=,comm=,cputime=,rss=,nlwp=,lstart= --sort=pid"
    $result = Invoke-LinuxSshCommand -Command $command -TimeoutSeconds 20
    $items = New-Object System.Collections.Generic.List[object]
    $now = [DateTime]::UtcNow
    $elapsed = if ($script:LinuxProcessSampleAt) {
        [Math]::Max(0.1, ($now - $script:LinuxProcessSampleAt).TotalSeconds)
    } else { 0.0 }
    $previous = if ($script:LinuxProcessSamples) { $script:LinuxProcessSamples } else { @{} }
    $current = @{}
    $logicalProcessors = 1
    foreach ($line in $result.Output) {
        if ($line -match '^RSM_CPUS\|(\d+)$') {
            $logicalProcessors = [Math]::Max(1,[int]$matches[1])
            continue
        }
        if ($line -match '^\s*(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(.+?)\s*$') {
            $processId = [int]$matches[1]
            $name = $matches[2]
            $cpuTotal = Convert-LinuxCpuTimeToSeconds $matches[3]
            $startIdentity = $matches[6].Trim()
            $sampleKey = [string]$processId
            $cpuPercent = 0.0
            $old = $previous[$sampleKey]
            if ($old -and $old.StartIdentity -eq $startIdentity -and $elapsed -gt 0) {
                $delta = [Math]::Max(0.0, $cpuTotal - [double]$old.CpuTotalSeconds)
                $cpuPercent = [Math]::Min(100.0, ($delta / $elapsed / $logicalProcessors) * 100.0)
            }
            $current[$sampleKey] = [pscustomobject]@{ CpuTotalSeconds=$cpuTotal; StartIdentity=$startIdentity }
            $items.Add([pscustomobject]@{
                ProcessId = $processId
                Name = $name
                StartIdentity = $startIdentity
                CpuPercent = [Math]::Round($cpuPercent,1)
                MemoryMB = [Math]::Round(([double]$matches[4] / 1024),1)
                DiskMBps = 0
                ThreadCount = [int]$matches[5]
                HandleCount = 0
            })
        }
    }
    $script:LinuxProcessSamples = $current
    $script:LinuxProcessSampleAt = $now
    return @($items)
}

function Stop-LinuxProcessBatch {
    param([Parameter(Mandatory)][array]$Processes)
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($process in @($Processes | Sort-Object ProcessId -Unique)) {
        $targetPid = [int]$process.ProcessId
        $name = [string]$process.Name
        $identity = [string]$process.StartIdentity
        if ($targetPid -le 2) { continue }
        $expected = "$name $identity"
        $encodedExpected = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($expected))
        $killCommand = @"
expected=`$(printf '%s' '$encodedExpected' | base64 -d)
actual=`$(LC_ALL=C ps -p $targetPid -o comm=,lstart= | awk '{`$1=`$1; print}')
if [ -z "`$actual" ]; then echo RSM_NOT_FOUND; exit 4; fi
if [ "`$actual" != "`$expected" ]; then echo RSM_IDENTITY_CHANGED; exit 5; fi
if [ "`$(id -u)" -eq 0 ]; then kill -TERM $targetPid; else sudo -n kill -TERM $targetPid; fi || exit 6
i=0; while [ `$i -lt 10 ] && ps -p $targetPid >/dev/null 2>&1; do sleep 0.2; i=`$((i+1)); done
if ps -p $targetPid >/dev/null 2>&1; then echo RSM_STILL_RUNNING; exit 7; fi
echo RSM_KILLED
"@
        $commandResult = Invoke-LinuxSshCommand -Command $killCommand -AllowFailure -TimeoutSeconds 15
        $outputText = ($commandResult.Output -join ' ').Trim()
        $success = $commandResult.ExitCode -eq 0 -and $outputText -match 'RSM_KILLED'
        $errorText = if ($success) {
            ''
        } elseif ($outputText -match 'RSM_IDENTITY_CHANGED') {
            'PID уже принадлежит другому процессу; завершение отменено.'
        } elseif ($outputText -match 'RSM_NOT_FOUND') {
            'Процесс уже завершён.'
        } elseif ($outputText -match 'RSM_STILL_RUNNING') {
            'SIGTERM отправлен, но процесс не завершился за 2 секунды.'
        } else {
            $outputText
        }
        $results.Add([pscustomobject]@{ ProcessId=$targetPid; Name=$name; Success=$success; Warning=''; Error=$errorText })
    }
    return @($results)
}

function Get-LinuxServiceDiagnostics {
    param([Parameter(Mandatory)][string[]]$Names)
    foreach ($name in $Names) {
        if ($name -notmatch '^(?!-)[a-zA-Z0-9_.@:-]+\.service$') { throw "Недопустимое имя службы: $name" }
    }
    $units = $Names -join ' '
    $journalUnits = @($Names | ForEach-Object { "-u $_" }) -join ' '
    $command = "LC_ALL=C systemctl status $units --no-pager --full; printf '\n--- JOURNAL ---\n'; journalctl $journalUnits --since '-24 hours' -n 80 --no-pager -o short-iso"
    return Invoke-LinuxSshCommand -Command $command -AllowFailure
}
