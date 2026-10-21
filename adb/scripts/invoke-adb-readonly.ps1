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
    'pull' {
        if ($tail.Count -ne 2 -or $tail[0] -match '\.\.' -or
            $tail[0] -notmatch '^(/vendor/etc/sensors/config(/[A-Za-z0-9_.-]+)?|/mnt/vendor/persist/sensors/registry(/[A-Za-z0-9_./-]+)?|/data/local/tmp/sensor_aba_[A-Za-z0-9_./-]+)$') {
            Deny 'pull permits only sensor configuration backups and sensor ABA evidence, with an explicit local destination'
        }
    }
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
            'date' {
                if ($shellTail.Count -ne 1 -or $shellTail[0] -ne '-u') {
                    Deny 'date permits only UTC clock reading with -u'
                }
            }
            'lshal' {
                if ($shellTail.Count -ne 0) {
                    Deny 'lshal permits only the default HAL service listing'
                }
            }
            'sha256sum' {
                if ($shellTail.Count -eq 0) { Deny 'sha256sum requires explicit diagnostic artifact paths' }
                foreach ($path in $shellTail) {
                    if ($path -notmatch '^(/vendor/lib64/(sensors\.ssc\.so|hw/(sensors\.ssc\.so|camera\.qcom\.so|com\.qti\.chi\.override\.so)|camera/components/com\.qti\.node\.eisv[23]\.so|libssc\.so|libcamx[a-zA-Z0-9_.-]*\.so)|/vendor/bin/hw/android\.hardware\.sensors@2\.0-service\.multihal|/vendor/app/QSensorTest/QSensorTest\.apk|/product/app/Camera2/Camera2\.apk)$') {
                        Deny "sha256sum path is outside the sensor/camera artifact boundary: $path"
                    }
                }
            }
            'pm' {
                if (($shellTail -join ' ') -notmatch '^(list packages( -f)?( [A-Za-z0-9_.]+)?|path [A-Za-z0-9_.]+)$') {
                    Deny 'pm permits only package listing and APK path queries'
                }
            }
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
                    Deny 'cat requires at least one allowlisted diagnostic path'
                }
                foreach ($path in $shellTail) {
                    $isKernelDiagnostic = $path -match '^/(proc|sys)/[A-Za-z0-9_./*:-]+$'
                    $isSensorConfig = $path -match '^/vendor/etc/sensors/(config/[A-Za-z0-9_-]+\.json|sns_reg_config|hals\.conf)$'
                    $isSensorRegistry = $path -match '^/mnt/vendor/persist/sensors/registry/(sns_reg_config|sns_reg_version|registry/[A-Za-z0-9_.-]+)$'
                    $isSensorInit = $path -match '^/vendor/etc/(init/(init\.vendor\.sensors|vendor\.sensors\.qti|vendor\.sensors\.sscrpcd|android\.hardware\.sensors@2\.0-service-multihal)\.rc|sensors/sensors_config)$'
                    $isAbaEvidence = $path -match '^/data/local/tmp/sensor_aba_[A-Za-z0-9_-]+\.xml$'
                    $isSensorManifest = $path -eq '/vendor/etc/vintf/manifest/android.hardware.sensors@2.0-multihal.xml'
                    if ($path -match '\.\.' -or -not ($isKernelDiagnostic -or $isSensorConfig -or $isSensorRegistry -or $isSensorInit -or $isAbaEvidence -or $isSensorManifest)) {
                        Deny "cat path is outside the read-only diagnostic boundary: $path"
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
                } elseif ($service -eq 'sensorservice' -and $shellTail.Count -eq 1) {
                    # Read-only sensor state snapshot.
                } elseif ($service -eq 'package' -and $shellTail.Count -eq 2 -and $shellTail[1] -match '^[A-Za-z0-9_.]+$') {
                    # Read-only package metadata.
                } elseif ($service -in @('display', 'power', 'input', 'media.camera', 'sensor_privacy') -and $shellTail.Count -eq 1) {
                    # Default state dumps only; no service control arguments.
                } elseif ($service -eq 'window' -and $shellTail.Count -eq 2 -and $shellTail[1] -in @('displays', 'policy')) {
                    # Bounded window/display policy state, without settings mutations.
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
                if (($shellTail -join ' ') -notmatch '^get global captive_portal_(http_url|https_url|fallback_url|other_fallback_urls|fallback_probe_specs|use_https|mode)$' -and
                    ($shellTail -join ' ') -notmatch '^--user current get system (screen_brightness_mode|screen_brightness|screen_auto_brightness_adj|screen_off_timeout)$') {
                    Deny 'settings permits only reads of captive portal configuration and selected current-user brightness settings'
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
                if ($shellTail -contains '-c' -or $shellTail -contains '--clear' -or $shellTail -ccontains '-G' -or $shellTail -contains '--buffer-size') {
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
