[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $AdbArguments
)

$ErrorActionPreference = 'Stop'
$adbPath = Join-Path $PSScriptRoot 'adb\adb.exe'

if (-not (Test-Path -LiteralPath $adbPath -PathType Leaf)) {
    throw "Bundled adb.exe was not found: $adbPath"
}

function Deny([string] $Reason) {
    throw "Read-only ADB wrapper rejected the command: $Reason"
}

if (-not $AdbArguments -or $AdbArguments.Count -eq 0) {
    Deny 'no command was supplied'
}

$index = 0
while ($index -lt $AdbArguments.Count -and $AdbArguments[$index].StartsWith('-')) {
    $option = $AdbArguments[$index]
    if ($option -in @('-d', '-e')) {
        $index += 1
        continue
    }
    if ($option -in @('-s', '-t', '-H', '-P', '-L')) {
        if ($index + 1 -ge $AdbArguments.Count) {
            Deny "missing value for global option $option"
        }
        $index += 2
        continue
    }
    Deny "unsupported global option $option"
}

if ($index -ge $AdbArguments.Count) {
    Deny 'no adb command follows the global options'
}

$command = $AdbArguments[$index]
$tail = @()
if ($index + 1 -lt $AdbArguments.Count) {
    $tail = @($AdbArguments[($index + 1)..($AdbArguments.Count - 1)])
}

switch ($command) {
    'devices' {
        if ($tail.Count -gt 1 -or ($tail.Count -eq 1 -and $tail[0] -ne '-l')) {
            Deny 'devices permits only the optional -l flag'
        }
    }
    { $_ -in @('get-state', 'get-serialno', 'get-devpath', 'version') } {
        if ($tail.Count -ne 0) {
            Deny "$command does not accept arguments in read-only mode"
        }
    }
    'shell' {
        if ($tail.Count -eq 0) {
            Deny 'interactive shell is not permitted'
        }
        foreach ($argument in $tail) {
            if ($argument -match '[;&|><`$()]' -or $argument -match "[`r`n]") {
                Deny "shell metacharacter detected in argument: $argument"
            }
        }

        $shellCommand = $tail[0]
        $shellTail = @()
        if ($tail.Count -gt 1) {
            $shellTail = @($tail[1..($tail.Count - 1)])
        }

        switch ($shellCommand) {
            'getprop' {
                if ($shellTail.Count -gt 1 -or ($shellTail.Count -eq 1 -and $shellTail[0] -notmatch '^[A-Za-z0-9._-]+$')) {
                    Deny 'getprop permits zero arguments or one property name'
                }
            }
            { $_ -in @('uname', 'id', 'uptime', 'ps', 'pidof', 'pgrep', 'df', 'top', 'iostat', 'ls') } {
                foreach ($argument in $shellTail) {
                    if ($argument -notmatch '^[A-Za-z0-9_./,:+%=-]+$') {
                        Deny "unsupported argument for ${shellCommand}: $argument"
                    }
                }
            }
            'cat' {
                if ($shellTail.Count -eq 0) {
                    Deny 'cat requires at least one /proc or /sys path'
                }
                foreach ($path in $shellTail) {
                    if ($path -match '\.\.' -or $path -notmatch '^/(proc|sys)/[A-Za-z0-9_./*:-]+$') {
                        Deny "cat path is outside the read-only /proc and /sys boundary: $path"
                    }
                }
            }
            'dumpsys' {
                if ($shellTail.Count -eq 0) {
                    Deny 'dumpsys requires an allowlisted service'
                }
                $service = $shellTail[0]
                if ($service -in @('usb', 'ethernet', 'network_stack', 'connectivity')) {
                    if ($shellTail.Count -ne 1) {
                        Deny "dumpsys $service permits no service arguments"
                    }
                } elseif ($service -notin @('cpuinfo', 'meminfo', 'gfxinfo', 'thermalservice', 'diskstats')) {
                    Deny "dumpsys service is not allowlisted: $service"
                }
                foreach ($argument in @($shellTail | Select-Object -Skip 1)) {
                    if ($argument -notmatch '^[A-Za-z0-9_.:-]+$') {
                        Deny "unsupported dumpsys argument: $argument"
                    }
                }
            }
            'ip' {
                $query = $shellTail -join ' '
                if ($query -notmatch '^(-s )?link show dev eth[0-9]+$' -and
                    $query -notmatch '^addr show dev eth[0-9]+$' -and
                    $query -notmatch '^(-4 |-6 )?route show( table all)?$' -and
                    $query -notmatch '^neigh show dev eth[0-9]+$') {
                    Deny 'ip permits only bounded link/address/route/neighbour show queries'
                }
            }
            'ethtool' {
                if (-not (($shellTail.Count -eq 2 -and $shellTail[0] -eq '--show-eee' -and $shellTail[1] -match '^eth[0-9]+$') -or
                    ($shellTail.Count -eq 3 -and $shellTail[0] -eq '--get-tunable' -and $shellTail[1] -match '^eth[0-9]+$' -and $shellTail[2] -eq 'rx-copybreak') -or
                    ($shellTail.Count -eq 1 -and $shellTail[0] -match '^eth[0-9]+$') -or
                    ($shellTail.Count -eq 2 -and $shellTail[0] -cin @('-i', '-k', '-S') -and $shellTail[1] -match '^eth[0-9]+$'))) {
                    Deny 'ethtool permits only link, driver (-i), features (-k), statistics (-S) queries'
                }
            }
            'cmd' {
                if (($shellTail -join ' ') -notin @('ethernet help', 'network_stack help')) {
                    Deny 'cmd permits only ethernet/network_stack help'
                }
            }
            'settings' {
                if (($shellTail -join ' ') -notmatch '^get global captive_portal_(http_url|https_url|fallback_url|other_fallback_urls|fallback_probe_specs|use_https|mode)$') {
                    Deny 'settings permits only reads of captive portal probe configuration'
                }
            }
            'timeout' {
                $query = $shellTail -join ' '
                if ($query -notmatch '^(30|45|60) /system/bin/tcpdump -p -n -i eth[0-9]+ -s 0 -c (30|50|100) -vvv udp port 67 or udp port 68$') {
                    Deny 'timeout permits only bounded non-promiscuous DHCP packet observation'
                }
            }
            'ping' {
                if (($shellTail -join ' ') -notmatch '^-I eth[0-9]+ -c 3 -W 2 [A-Za-z0-9.-]+$') {
                    Deny 'ping permits only three bounded probes bound to an Ethernet interface'
                }
            }
            'curl' {
                $query = $shellTail -join ' '
                if ($query -notmatch '^--interface eth[0-9]+ --connect-timeout 5 --max-time 15 --silent --show-error --output /dev/null --write-out HTTP:%\{http_code\} https://(www\.baidu\.com/(generate_204)?|connectivitycheck\.baidu\.com/generate_204|connectivitycheck\.gstatic\.com/generate_204|www\.google\.com/generate_204)$') {
                    Deny 'curl permits only bounded HTTPS reachability GETs with default certificate verification'
                }
            }
            'logcat' {
                if ($shellTail -contains '-c' -or $shellTail -contains '--clear' -or $shellTail -contains '-G' -or $shellTail -contains '--buffer-size') {
                    Deny 'logcat mutation option is not permitted'
                }
                foreach ($argument in $shellTail) {
                    if ($argument -notmatch '^[A-Za-z0-9_./,:+%*=-]+$') {
                        Deny "unsupported logcat argument: $argument"
                    }
                }
            }
            'perfetto' {
                if ($shellTail.Count -ne 1 -or $shellTail[0] -notin @('--help', '--version', '--query-raw')) {
                    Deny 'perfetto permits only --help, --version, or --query-raw in read-only mode'
                }
            }
            'simpleperf' {
                if ($shellTail.Count -eq 0 -or $shellTail[0] -ne 'list') {
                    Deny 'simpleperf permits only the list command in read-only mode'
                }
                foreach ($argument in @($shellTail | Select-Object -Skip 1)) {
                    if ($argument -notmatch '^[A-Za-z0-9_.=-]+$') {
                        Deny "unsupported simpleperf list argument: $argument"
                    }
                }
            }
            'command' {
                if ($shellTail.Count -ne 2 -or $shellTail[0] -ne '-v' -or $shellTail[1] -notmatch '^[A-Za-z0-9_.-]+$') {
                    Deny 'command permits only: command -v <name>'
                }
            }
            default {
                Deny "shell command is not allowlisted: $shellCommand"
            }
        }
    }
    default {
        Deny "adb command is not allowlisted: $command"
    }
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $adbPath @AdbArguments
$adbExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
exit $adbExitCode
