###############################################
# Skript um die Tön PCs jeden Abend neuzustarten, dass diese Updates installieren können
# Autor: Joris Bieg
# Datum: 15.06.2023
# Version: 8.1
###############################################

# Importieren von der CSV Liste mit den Computernamen (FQDN)
$computers = Import-Csv ".\PCs-test.csv" ";"

# Log Funktion
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -Append -FilePath $logFilePath
}

# Die Zeit wann die PCs neustarten sollen
$restartTime = Get-Date -Hour 20 -Minute 0 -Second 0

# Pfad und Dateiname der Logdatei
$logFileName = "ToenPCreboot.log"
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath $logFileName

# Endlosschleife, die auf den Neustartzeitpunkt wartet und dann die Computer neu startet
while ($true) {
    $currentTime = Get-Date

    # Überprüfe, ob es Zeit für den Neustart ist
    if ($currentTime -ge $restartTime) {
        foreach ($line in $computers) {
            $computer = $line.PCs
            # Überprüfe, ob der Computer mit einem Semikolon beginnt oder leer ist, wenn ja, überspringe
            if ([string]::IsNullOrEmpty($computer) -or $computer.StartsWith(";")) {
                continue
            }
            # Überprüfe, ob der Computer erreichbar ist bevor neustart eingeleitet wird
            if (Test-Connection -ComputerName $computer -Count 1 -Quiet -TimeToLive 10) {
                $logMessage = "INFO    - $computer reboot initiated."
                Write-Log -Message $logMessage
                # Startet den PC neu
                Restart-Computer -ComputerName $computer -Force
            } else {
                # Wenn PC offline, dann wird eine Nachricht in den Log geschrieben
                $logMessage = "WARNING - $computer is unreachable and cannot be rebooted."
                Write-Log -Message $logMessage
            }
        }

        # Warte 10 Minute nach dem Neustart
        Start-Sleep -Seconds 600

    # Status der Computer prüfen und loggen. Ob Online oder Offline
    foreach ($line in $computers) {
        $computer = $line.PCs

        # Überprüfe, ob der Computer mit einem Semikolon beginnt oder leer ist, wenn ja, überspringe
        if ([string]::IsNullOrEmpty($computer) -or $computer.StartsWith(";")) {
            continue
        }

        $isOnline = Test-Connection -ComputerName $computer -Count 1 -Quiet

        if (-not $isOnline) {
            $logMessage = "WARNING - $computer is OFFLINE at the moment (10 minutes after reboot)."
            Write-Log -Message $logMessage
        } else {
            $logMessage = "INFO    - $computer is again ONLINE (10 minutes after reboot)."
            Write-Log -Message $logMessage
        }
    }


        # Neustart abgeschlossen, setze die Zeit für den nächsten Tag (Kann auch mit Tagen und oder Wochen gesetzt werden z.B. .AddWeek(1) dann werden die neustarts nur alle Woche ausgeführt)
        $restartTime = $restartTime.AddDays(1)

        # Füge eine leere Zeile am Ende des Tages hinzu
        "" | Out-File -Append -FilePath $logFilePath

        # Warte bis zum nächsten Tag zur festgelegten Uhrzeit
        while ($currentTime -lt $restartTime) {
            # Überprüfe jede Sekunde, ob es Zeit für den nächsten Neustart ist
            Start-Sleep -Seconds 1
            $currentTime = Get-Date
        }
    }

    # Warte eine Sekunde und überprüfe dann erneut die Zeit
    Start-Sleep -Seconds 1
}
