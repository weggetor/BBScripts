param(
[string]$InstallPath = "C:\Temp\Med4App\DNN\",
[string]$WinAccount = "Netzwerkdienst",
[string]$WebsiteName = "Med4app",
[string]$WebsiteUrl = "med4app.local",
[string]$DBName = "Med4App",
[string]$DBInstance = ".\",
[string]$DBUser = "Med4App",
[string]$DBPassword = "test",
[string]$DBQualifier = "",
[string]$HostUser = "horst",
[string]$HostPassword = "dnnhorst",
[string]$HostEmail = "host@change.me",
[string]$InstallPackage = "z:\Master_D\Tools & Treiber\_Dotnetnuke\core7\DNN_Platform_07.03.04_Install.zip")

## Erlaubt die Ausführung von Skripten: Set-ExecutionPolicy RemoteSigned  
## Hier steht welches Powershell gestartet wird wenn ein Doppelklick auf eine .PS1 Datei gemacht wird:
## HKEY_CLASSES_ROOT\Microsoft.PowerShellConsole.1\Shell\Open\Command

# check if 7-zip is installed
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  

$frameworkRuntime = "v4.0" # "v2.0" oder "v4.0"
$dnnMainversion = "7"

Function WaitUntilReady
{
  $wait = $true
  $numWaits = 0
  while ($wait -and $numWaits -lt 300) 
  {
    $numWaits++
    [System.Threading.Thread]::Sleep(1000)
    $doc = $ie.Document
    if ($doc -ne $null) 
    {
      if ($doc.ReadyState -eq "complete")
      {
        $wait = $false
      }
    }
    else 
    {
      if ($numwaits -eq 1)
      {
        write-host "Waiting for app to respond ." -nonewline
      }
      else
      {
        write-host " ." -nonewline
      }
    }
  }
  if ($numWaits -eq 100) 
  {
    throw "Application did not respond after 100 seconds"
  }
  else 
  {
    write-host "Application has responded"
    return $doc
  }
}
cls
write-host "#--------------------------------------------------" -ForegroundColor Magenta
write-host "# Installation of DNN Site $WebsiteName" -ForegroundColor Magenta
write-host "#--------------------------------------------------" -ForegroundColor Magenta

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
sz x $InstallPackage $param

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

######################### Create Database #################################

# Open ADO.NET Connection with Windows authentification to local SQLEXPRESS.
$con = New-Object Data.SqlClient.SqlConnection;
$con.ConnectionString = "Data Source=" + $DBInstance + ";Initial Catalog=master;Integrated Security=True;";
$con.Open();

# Select-Statement for AD group logins
$sql = "SELECT name
        FROM sys.databases
        WHERE name = '$DBName';";

# New command and reader.
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
$rd = $cmd.ExecuteReader();
if ($rd.Read())
{	
	Write-Host "Database $DBName already exists" -ForegroundColor Yellow
}

$dummy = $rd.Close();
$dummy = $rd.Dispose();

# Create the database.
$sql = "CREATE DATABASE [$DBName];"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
try 
{ 
    $dummy = $cmd.ExecuteNonQuery();
    Write-Host "Database $DBName is created!" -ForegroundColor DarkGreen
} 
catch [System.Exception]
{
    write-host "$_" -ForegroundColor Yellow
}


#Create User for database
$sql = "CREATE LOGIN [$DBUser] WITH PASSWORD=N'$DBPassword', DEFAULT_DATABASE=[$DBName], DEFAULT_LANGUAGE=[Deutsch], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
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

$dummy = invoke-command -scriptblock {iisreset}

#Now open IE and navigate to the site

Write-Host "Start Browser and wait until DNN Install starts ..." -ForegroundColor DarkYellow
$IE = new-object -com "InternetExplorer.Application"
$IE.Visible = $true
$IE.Navigate("http://$WebsiteUrl/")
$doc = WaitUntilReady

if ($dnnMainversion -eq "7")
{
    Write-Host "Fill in form fields..."  -ForegroundColor DarkYellow

    # Datenbank-Seite konfigurieren
    $element = $doc.getElementByID("txtUsername")
    $element.Value = $HostUser;
    $element = $doc.getElementByID("txtPassword")
    $element.Value = $HostPassword;
    $element = $doc.getElementByID("txtConfirmPassword")
    $element.Value = $HostPassword;
    # Since 7.2.3
    $element = $doc.getElementByID("txtEmail")
    try {$element.Value = $HostEmail} catch {};
    
    $element = $doc.getElementByID("txtWebsiteName")
    $element.Value = $WebsiteName;
    $element = $doc.getElementByID("templateList_Input")
    $element.Value = "Blank Website" ;
    $element = $doc.getElementByID("databaseType_1")
    $element.Click()
    [System.Threading.Thread]::Sleep(500)
    $element = $doc.getElementByID("txtDatabaseServerName")
    $element.Value = $DBInstance;
    $element = $doc.getElementByID("txtDatabaseName")
    $element.Value = $DBName;
    $element = $doc.getElementByID("txtDatabaseObjectQualifier")
    $element.Value = $DBQualifier;
    $element = $doc.getElementByID("databaseSecurityType_1")
    $element.Click()
    [System.Threading.Thread]::Sleep(500)
    $element = $doc.getElementByID("txtDatabaseUsername")
    $element.Value = $DBUser;
    $element = $doc.getElementByID("txtDatabasePassword")
    $element.Value = $DBPassword;
}
elseif ($dnnMainversion -eq "6")
{
    # Individuelle Installation wählen
    $individual = $doc.getElementByID("wizInstall_installTypeRadioButton_1")
    $individual.checked = $true
    $nextBtn = $doc.getElementByID("wizInstall_StartNavigationTemplateContainerID_StartNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady

    # Berechtigungsüberprüfungs-Seite
    $nextBtn = $doc.getElementByID("wizInstall_StepNavigationTemplateContainerID_StepNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady

    # Datenbank-Seite konfigurieren
    $element = $doc.getElementByID("wizInstall_rblDatabases_1")
    $element.Click()
    [System.Threading.Thread]::Sleep(2000)
    $element = $doc.getElementByID("wizInstall_txtServer")
    $element.Value = $SqlInstance
    $element = $doc.getElementByID("wizInstall_txtDatabase")
    $element.Value = $dbname
    $element = $doc.getElementByID("wizInstall_chkIntegrated")
    $element.Checked = $true
    $element.Click()
    [System.Threading.Thread]::Sleep(2000)
    $element = $doc.getElementByID("wizInstall_txtUserId")
    $element.Value = $CustomerName
    $element = $doc.getElementByID("wizInstall_txtPassword")
    $element.Value = $CustomerPassword
    $element = $doc.getElementByID("wizInstall_txtqualifier")
    $element.Value = $dbprefix

    $nextBtn = $doc.getElementByID("wizInstall_StepNavigationTemplateContainerID_StepNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady

    $nextBtn = $doc.getElementByID("wizInstall_StepNavigationTemplateContainerID_StepNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady

    $nextBtn = $doc.getElementByID("wizInstall_StepNavigationTemplateContainerID_StepNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady

    $nextBtn = $doc.getElementByID("wizInstall_StepNavigationTemplateContainerID_StepNextButton")
    $nextBtn.Click()
    $doc = WaitUntilReady
}

write-host "#--------------------------------------------------" -ForegroundColor Green
Write-Host "# Preparation of DNN website $WebsiteName ready!" -ForegroundColor Green
Write-Host "# Please check entries and proceed with installation in browser!" -ForegroundColor Green
write-host "#--------------------------------------------------" -ForegroundColor Green
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

