#Zunächst einmal (als Admin) -> Set-ExecutionPolicy RemoteSigned

param(
[string]$DBName = "mywebsite",
[string]$DNNInstallPath = "c:\inetpub\wwwroot\mywebsite\dnn\",
[string]$LogPath = "c:\inetpub\wwwroot\mywebsite\dnn\logs\",
[string]$OutPutPath = "D:\Backup\",
[string]$DBInstance = ".\SQLEXPRESS",
[string]$ExcludeWildcard = "",
[switch]$IncludeLogs = $false,
[switch]$IncludeDNN = $false,
[switch]$IncludeDB = $false)

$DNNZipFile = $DBName + ".dnn.zip"
$DNNZipName = $OutPutPath + $DNNZipFile
$DNNZipPath = $DNNInstallPath + "\*"

$LogZipFile = $DBName + ".log.zip"
$LogZipName = $OutPutPath + $LogZipFile

$DBZipFile = $DBName + ".db.zip"
$DBZipName = $OutPutPath + $DBZipFile

$Result = ""
$Excludes = ""
$ExcludesText = ""
if ($ExcludeWildcard -cne "") 
{
    $Excludes = "-xr!$ExcludeWildcard"
    $ExcludesText = " (Excluding '$ExcludeWildcard')"
}


cls
write-host "#--------------------------------------------------" -ForegroundColor Magenta
write-host "# Backup of DNN Site $DBName" -ForegroundColor Magenta
write-host "#--------------------------------------------------" -ForegroundColor Magenta

if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  

if ($IncludeDNN -eq $true)
{
    write-host "Zip DNN $ExcludesText..." -ForegroundColor DarkYellow
    # Delete old file if any
    try {Remove-Item $DNNZipName -ErrorAction Stop} catch {}
    # zip DNN to Targetdirectory
    sz a -mx=9 $DNNZipName $DNNZipPath $Excludes
    write-host "Zipping of DNN done!" -ForegroundColor DarkGreen
    $Result = $DNNZipFile
}

# zip logfiles
if ($IncludeLogs -eq $true)
{
    write-host "Zip Log ..." -ForegroundColor DarkYellow
    # Delete old file if any
    try {Remove-Item $LogZipName -ErrorAction Stop} catch {}
    sz a -mx=9 $LogZipName $LogPath\* 
    write-host "Zipping of DNN done!" -ForegroundColor DarkGreen
    $Result = ($Result + " " + $LogZipFile).Trim()
}

if ($IncludeDB -eq $true)
{
    write-host "Backup DB ..." -ForegroundColor DarkYellow
    try
    {
        # Backup DB
        #[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
        #$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $DBInstance
        #$s.ConnectionContext.LoginSecure = $True
        # $s.ConnectionContext.ConnectTimeout = 65535

        #$DBBakFile = $OutPutPath + $DBName + ".bak"
        #[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null
        #$dbBackup = new-object ("Microsoft.SqlServer.Management.Smo.Backup")
        #$dbBackup.Database = $DBName
        #$dbBackup.Devices.AddDevice($DBBakFile, "File") 
        #$dbBackup.Action = "Database"
        #$dbBackup.SqlBackup($s)


        # Open ADO.NET Connection with Windows authentification to Database.
        $DBBakFile = $OutPutPath + $DBName + ".bak"
        $con = New-Object Data.SqlClient.SqlConnection;
        $con.ConnectionString = "Data Source=" + $DBInstance + ";Initial Catalog=master;Integrated Security=True;";
        $con.Open();
        # Backup the database.
        $sql = "BACKUP DATABASE [$DBName] TO  DISK = N'$DBBakFile' WITH NOFORMAT, INIT,  NAME = N'$DBName-Full', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;"
        $cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
        $dummy = $cmd.ExecuteNonQuery();
        # Close & Clear all objects.
        $cmd.Dispose();
        $con.Close();
        $con.Dispose();

        write-host "Database Backup of $DBName successfull" -ForegroundColor DarkGreen

        # Zip DB
        write-host "Zip DB ..."  -ForegroundColor DarkYellow
        # Delete old file if any
        try {Remove-Item $DBZipName -ErrorAction Stop} catch {}
        sz a -mx=9 $DBZipName $DBBakFile
        write-host "Zipping of DB done!" -ForegroundColor DarkGreen

        write-host "Cleaning up ..." -ForegroundColor DarkYellow
        $dummy=Remove-Item $DBBakFile

        $Result = ($Result + " " + $DBZipFile).Trim()
    }
    catch [System.Exception]
    {
        write-host "$_" -ForegroundColor Red
    }
}

if ($Result -cne "")
{
    write-host "#--------------------------------------------------" -ForegroundColor Green
    write-host "# Ready ! See files $Result in $OutPutPath" -ForegroundColor Green
    write-host "#--------------------------------------------------" -ForegroundColor Green
}
else
{
    write-host "#--------------------------------------------------" -ForegroundColor Yellow
    write-host "# No files created" -ForegroundColor Yellow
    write-host "#--------------------------------------------------" -ForegroundColor Yellow
   
}
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
