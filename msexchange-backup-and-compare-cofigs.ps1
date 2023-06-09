# Everyday backup and compare Exchange config

# Servers list
$server = gc 'D:\ExchangeServer.txt' # or other way
# Backup folder
$backupFolder = 'D:\BackupConfig'

# Exchange folder
$exchFolder = 'c$\Program Files\Microsoft\Exchange Server\V15'

$curDate = Get-Date -format "dd-MM-yyyy"
$yesterdayDate = (Get-Date).AddDays(-1).ToString("dd-MM-yyyy")


[string]$bkp_server_path = "$backupFolder\$curDate"
[string]$bkp_server_path_yesterday = "$backupFolder\$yesterdayDate"
[string]$bkp_file_path = ""
[string]$bkp_srv_path = ""

if (Test-Path $bkp_server_path) { Write-Host "Backup path: $bkp_server_path" -ForegroundColor Green } else { 
    Write-Host "Create path $bkp_server_path" -ForegroundColor Yellow
    New-Item $bkp_server_path -ItemType "directory" 
    }

foreach ($srv in $server) {

    $bkp_srv_path = "$bkp_server_path\$srv\"
    
    $config = Get-ChildItem "\\$srv\$exchFolder" -Recurse -Filter "*.config" | select FullName, Directory
    foreach ($conf in $config) {
        
        [string]$file_path = $conf.FullName
        [string]$file_dir = $conf.Directory
        [string]$bkp_file_path = $bkp_srv_path + $file_dir.TrimStart("\\$srv\c$\") + "\"

        if (Test-Path $bkp_file_path) { } else { 
            Write-Host "Create path $bkp_file_path" -ForegroundColor Yellow 
            New-Item $bkp_file_path -ItemType "directory" }

        Copy-Item $file_path -Destination $bkp_file_path -Force -Recurse

    }
    
    # Logging change in log file
    Get-ChildItem "\\$srv\$exchFolder" -Recurse | select FullName, CreationTime, LastWriteTime | Export-Csv "$bkp_srv_path\$curDate.csv" -Encoding UTF8

    # Compare with logs from yesterday
    if (Test-Path "$bkp_server_path_yesterday\$srv\$yesterdayDate.csv") {
        $obj1 = import-csv "$bkp_server_path_yesterday\$srv\$yesterdayDate.csv"
        $obj2 = import-csv "$bkp_srv_path\$curDate.csv"
        Write-Host "Compare  $bkp_server_path_yesterday\$srv\$yesterdayDate.csv and $bkp_srv_path\$curDate.csv..." -ForegroundColor Yellow
        Compare $obj1 $obj2 -Property FullName, CreationTime, LastWriteTime | Export-Csv "$bkp_srv_path\compare_$curDate.csv"
    }

}