#Zunächst einmal (als Admin) -> Set-ExecutionPolicy RemoteSigned

param(
[string]$InstallPath = "C:\Inetpub\wwwroot\0002_steilpass\dnn\",
[string]$WinAccount = "Netzwerkdienst",
[string]$WebsiteName = "0002_steilpass",
[string]$WebSiteUrl = "stream.steilpass.de",
[string]$DBName = "0002_steilpass",
[string]$DBInstance = ".\",
[string]$DBUser = "test",
[string]$DBPassword = "test",
[string]$InPutPath = "C:\Temp\Backup\")

cls
write-host "#--------------------------------------------------" -ForegroundColor Magenta
write-host "# Restore of DNN Site $DBName" -ForegroundColor Magenta
write-host "#--------------------------------------------------" -ForegroundColor Magenta

# check if 7-zip is installed
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  

$frameworkRuntime = "v4.0" # "v2.0" oder "v4.0"

$DNNZipFile = $DBName + ".dnn.zip"
$DBZipFile = $DBName + ".db.zip"
$DNNZipPath = $InPutPath + $DNNZipFile
$DBZipPath = $InPutPath + $DBZipFile
$DBBackupFile = $InputPath + $DBName + ".bak"

Import-Module WebAdministration

#remove existing IIS Site and App pool
write-host "Remove existing IIS Site and App pool" -ForegroundColor DarkYellow
$dummy = Remove-Item IIS:\Sites\$WebsiteName -Recurse -ErrorAction Ignore
$dummy = Remove-Item IIS:\AppPools\$WebsiteName -Recurse -ErrorAction Ignore

#delete anything in the destination folder
write-host "Delete old contents of target directory (if any)" -ForegroundColor DarkYellow
$dummy = new-item -force -path $InstallPath -itemtype "directory"
$dummy = get-childitem $InstallPath | remove-item -force -recurse


#unzip DNN to Targetdirectory
write-host "Unzip DNN Install File..." -ForegroundColor DarkYellow
$param = "-o$InstallPath"
sz x $DNNZipPath $param

#Set the ACL on the folder
$Right = "FullControl"
write-host "Set Access Control (ACL) on website folder $InstallPath for $WinAccount to $Right ..." -ForegroundColor DarkYellow
$Acl = Get-Acl $InstallPath
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"
$accessrule = New-Object system.security.AccessControl.FileSystemAccessRule($WinAccount, $Right, $inherit, $propagation, "Allow")
$Acl.SetAccessRule($AccessRule)
$dummy = Set-Acl -AclObject $Acl $InstallPath
Write-Host "ACL '$Right' was added to $InstallPath" -ForegroundColor DarkGreen

#Create the IIS Site
$dummy = New-Item IIS:\AppPools\$WebsiteName -Force
$dummy = Set-ItemProperty IIS:\AppPools\$WebsiteName -name ProcessModel.identityType -Value 2
$dummy = Set-ItemProperty IIS:\AppPools\$WebsiteName managedRuntimeVersion $frameworkRuntime
$dummy = New-Item IIS:\Sites\$WebsiteName -bindings @{protocol="http";bindingInformation=":80:$WebsiteUrl"} -physicalPath $InstallPath -Force
$dummy = Set-ItemProperty IIS:\Sites\$WebsiteName -name applicationPool -value $WebsiteName
write-host "Website + Applicationpool for $WebsiteName in IIS created" -ForegroundColor DarkGreen

#Update the hosts file
$hostsentry = Select-String $Env:SystemRoot\System32\drivers\etc\hosts -pattern "$WebsiteUrl" -quiet
if (-not $hostsentry)
{
    Add-Content $Env:SystemRoot\System32\drivers\etc\hosts "127.0.0.1        $WebsiteUrl"
    write-host "Added $WebsiteUrl to hosts file" -ForegroundColor DarkGreen
}

#Unzip DB.bak 
write-host "Unzip DB File..." -ForegroundColor DarkYellow
$param = "-o$InputPath"
sz x $DBZipPath $param


#============================================================
# Restore a Database using PowerShell and SQL Server SMO
# Restore to the same database, overwrite existing db
#============================================================
 
#load assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

#we will query the db name from the backup file later
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $DBInstance

#need to check if database exists, and if it does, drop it
$db = $server.Databases[$DBName]
if ($db)
{
      #we will use KillDatabase instead of Drop
      #Kill database will drop active connections before 
      #dropping the database
      write-host "Database $DBName exists, will be deleted now!" -ForegroundColor DarkYellow
      $server.KillDatabase($DBName)
}

# Open ADO.NET Connection with Windows authentification to local SQLEXPRESS.
$con = New-Object Data.SqlClient.SqlConnection;
$con.ConnectionString = "Data Source=" + $DBInstance + ";Initial Catalog=master;Integrated Security=True;Connection Timeout=240";
$con.Open();

# Create the database.
$sql = "CREATE DATABASE [$DBName];"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
$dummy = $cmd.ExecuteNonQuery();		
Write-Host "Database $DBName is created!" -ForegroundColor DarkGreen

$moveDB = $DBName
$moveDBLog = ($DBName + "_log")

Write-Host "Restoring Database $DBName ..." -ForegroundColor DarkYellow
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $DBInstance

$db = $server.Databases[$DBName]
$DBMasterPath = $db.PrimaryFilePath

$sql = "USE [master]; RESTORE DATABASE [" + $DBName + "] FROM  DISK = N'" + $DBBackupFile+ "' WITH  FILE = 1,  MOVE N'"+ $moveDB + "' TO N'" + $DBMasterPath + $DBName +".mdf',  MOVE N'" + $moveDBLog + "' TO N'"+ $DBMasterPath + $DBName+ "_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 5"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
$cmd.CommandTimeout = 0
$dummy = $cmd.ExecuteNonQuery();		
Write-Host "Database $DBName is Restored!" -ForegroundColor DarkGreen

remove-item $DBBackupFile

#Create User for database
$sql = "CREATE LOGIN [$DBUser] WITH PASSWORD=N'$DBPassword', DEFAULT_DATABASE=[$DBName], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
try 
{ 
    $dummy = $cmd.ExecuteNonQuery();
    Write-Host "Login $DBUser is created!" -ForegroundColor DarkGreen
} 
catch [System.Exception]
{
    write-host "$_" -ForegroundColor Yellow
}

# Select Database
$sql = "USE [$DBName]"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
try 
{ 
    $dummy = $cmd.ExecuteNonQuery();
} 
catch [System.Exception]
{
    write-host "$_" -ForegroundColor Yellow
}

# Create user for Login
$sql = "CREATE USER [$DBUser] FOR LOGIN [$DBUser]"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
try 
{ 
    $dummy = $cmd.ExecuteNonQuery();
    write-host "User $DBUser for Login $DBUser created" -ForegroundColor DarkGreen
} 
catch [System.Exception]
{
    write-host "$_" -ForegroundColor Yellow
}

# SQL2012: $sql = "ALTER ROLE [db_owner] ADD MEMBER [$CustomerName]"
$sql = "EXEC sp_addrolemember N'db_owner', N'$DBUser'"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
try 
{ 
    $dummy = $cmd.ExecuteNonQuery();
    Write-Host "Added User $DBUser to role 'dbowner'!" -ForegroundColor DarkGreen
} 
catch [System.Exception]
{
    write-host "$_" -ForegroundColor Yellow
}

# Close & Clear all objects.
$cmd.Dispose();
$con.Close();
$con.Dispose();

# Change web.config connection string
write-host "Change connectionstring in web.config..." -ForegroundColor DarkYellow
$webConfigPath = $InstallPath +"web.config"
$backup = $webConfigPath + ".bak"

# Get the content of the config file and cast it to XML and save a backup copy labeled .bak 
$xml = [xml](get-content $webConfigPath)
$xml.Save($backup)

# Change original connectionString
$root = $xml.get_DocumentElement();
$node = $root.SelectSingleNode("//connectionStrings/add[@name='SiteSqlServer']")
$node.connectionString = "Data Source=$DBInstance;Initial Catalog=$DBName;User ID=$DBUser;Password=$DBPassword" 

# Save it
$xml.Save($webConfigPath)
write-host "Connectionstring is changed to " + $node.connectionString + " in web.config" -ForegroundColor DarkGreen

Write-Host "Start Browser and wait until DNN Install starts ..." -ForegroundColor DarkYellow
$IE = new-object -com "InternetExplorer.Application"
$IE.Visible = $true
$IE.Navigate("http://$WebsiteUrl/")

write-host "#--------------------------------------------------" -ForegroundColor Green
Write-Host "# Restore of DNN website $WebsiteName done!" -ForegroundColor Green
write-host "#--------------------------------------------------" -ForegroundColor Green
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
