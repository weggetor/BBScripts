## Project Description

![BBScripts](Documentation/BBScripts.png "BBScripts") The _bitboxx bbscripts_ Powershell scripts support the daily maintenance tasks with DNN installation ! Installation of a new website, Backup and Restore or upgrading a website is only calling one script now!

* * *

## Whats new ?

_Version 01.00.02 (05.05.2015):_

*   Updated build script

_Version 01.00.00 (17.12.2014):_

*   Initial release

* * *

## Description

Copy the scripts to a folder of your choice (e.g. C:\Scripts).

To call a script you change to this folder at the DOS-Prompt and invoke the script with its parameters (the “.\” before the script name is important!):

```dos
CD C:\Scripts
powershell .\DNN-xyz.ps1 -parameter1 value1 -parameter2 value2 …
```

Please be aware of the following points

*   All paths must end with “\”.
*   All scripts need an installed version of 7-zip (see [http://www.7-zip.org/](http://www.7-zip.org/ "http://www.7-zip.org/"))
*   Parameters not set use their default values.
*   Be careful ! Try the scripts first in a safe environment before using in production. There are a lot of different machines and software releases outside in the wild and I tested only on my environments. In no case I am responsible for any damages the scripts will produce!
*   Enhancements, tips and pull requests are welcome !

### DNN-Install

Installs a DNN website. Copies all needed files to the folder of your choice, registers the website in IIS, creates the database and adds a line in hosts file for invocation of the website locally. Starts browser afterwards and fills in the values in the installation form.

Parameters:

<table border="1" cellspacing="0" cellpadding="2">
<tbody>
<tr>
<td  valign="top">InstallPath</td>
<td  valign="top">Target Installation Folder (must have “\” at the end)</td>
</tr>
<tr>
<td  valign="top">WinAccount</td>
<td  valign="top">Name of windows account to set folder security (e.g. “Network Service”)</td>
</tr>
<tr>
<td  valign="top">WebsiteName</td>
<td valign="top">Name of the website in IIS (e.g. “mywebsite”)</td>
</tr>
<tr>
<td  valign="top">WebsiteUrl</td>
<td  valign="top">Url of website (eg. “www.mywebsite.com”)</td>
</tr>
<tr>
<td  valign="top">DBName</td>
<td  valign="top">Name of created database (e.g. “mywebsiteDB”)</td>
</tr>
<tr>
<td  valign="top">DBInstance</td>
<td  valign="top">Name of SQL Instance (e.g. “.\SQLEXPRESS”)</td>
</tr>
<tr>
<td  valign="top">DBUser</td>
<td  valign="top">Name of db user with access to database (e.g. “testuser”)</td>
</tr>
<tr>
<td  valign="top">DBPassword</td>
<td  valign="top">Password of db user (e.g. “testpassword”)</td>
</tr>
<tr>
<td  valign="top">DBQualifier</td>
<td  valign="top">Prefix for DNN tables (leave empty if no prefix) (e.g. “dnn”)</td>
</tr>
<tr>
<td  valign="top">HostUser</td>
<td  valign="top">Name of DNN superuser (e.g. “host”)</td>
</tr>
<tr>
<td  valign="top">HostPassword</td>
<td  valign="top">Password of superuser (e.g. “dnnhost”)</td>
</tr>
<tr>
<td  valign="top">HostEmail</td>
<td valign="top">Email address of superuser (e.g. [“host@change.me](mailto:“host@change.me)”)</td>
</tr>
<tr>
<td  valign="top">InstallPackage</td>
<td  valign="top">Path to DNN Install zip (e.g."D:\Install\DotNetNuke\DNN_Platform_07.03.04_Install.zip")</td>
</tr>
</tbody>
</table>

Sample:

```dos
powershell .\DNN-Install.ps1 -Installpath C:\Inetpub\wwwroot\bitboxx\dnn -WinAccount “Network Service” -WebsiteName bitboxx -WebsiteUrl www.bitboxx.net -DBName bitboxx -DBInstance .\SQLEXPRESS $DBUser bitboxx $DBPassword donottell $Hostuser host $HostPassword dnnhost -HostEmail host@bitboxx.net -InstallPackage D:\Install\DotNetNuke\DNN_Platform_07.03.04_Install.zip
```

### DNN-Upgrade

Upgrades an existing DNN installation. Creates “app-offline” file, unzips the DNN upgrade package to the desination folder, deletes “app-offline” file and invokes the update installation by calling “http://www.mywebsite.com/install/install.aspx?mode=upgrade”

Parameters:

<table border="1" cellspacing="0" cellpadding="2">
<tbody>
<tr>
<td valign="top">InstallPath</td>
<td valign="top">Target Installation Folder (must have “\” at the end)</td>
</tr>
<tr>
<td valign="top">WebsiteUrl</td>
<td valign="top">Url of website (eg. “www.mywebsite.com”)</td>
</tr>
<tr>
<td valign="top">UpgradePackage</td>
<td valign="top">Path to DNN Upgradezip (e.g."D:\Install\DotNetNuke\DNN_Platform_07.03.04_Upgrade.zip")</td>
</tr>
</tbody>
</table>

Sample:

```dos
powershell .\DNN-Upgrade.ps1 -Installpath C:\Inetpub\wwwroot\bitboxx\dnn -WebsiteUrl www.bitboxx.net -UpgradePackage D:\Install\DotNetNuke\DNN_Platform_07.03.04_Upgrade.zip
```

### DNN-Backup

Creates a Backup of a DNN installation depending on parameters backs up database / website / logs. Creates different zip files for every type of backup in OutputPath (e.g. “mywebsite_dnn.zip”,”mywebsite_db.zip” and / or “mywebsite_log.zip”)

Parameters:

<table border="1" cellspacing="0" cellpadding="2">
<tbody>
<tr>
<td valign="top">DBName</td>
<td valign="top">Name of database (and name of backup)</td>
</tr>
<tr>
<td valign="top">InstallPath</td>
<td valign="top">Path of DNN installation to backup</td>
</tr>
<tr>
<td valign="top">LogPath</td>
<td valign="top">Path of log files to backup</td>
</tr>
<tr>
<td valign="top">OutputPath</td>
<td valign="top">Path where backup files are created</td>
</tr>
<tr>
<td valign="top">DBInstance</td>
<td valign="top">Name of SQL Instance (e.g. “.\SQLEXPRESS”)</td>
</tr>
<tr>
<td valign="top">ExcludeWildcard</td>
<td valign="top">pattern of filestype to exclude (e.g “*.mp4”)</td>
</tr>
<tr>
<td valign="top">IncludeLogs</td>
<td valign="top">if present log backup is created</td>
</tr>
<tr>
<td valign="top">IncludeDNN</td>
<td valign="top">if present DNN backup is created</td>
</tr>
<tr>
<td valign="top">IncludeDB</td>
<td valign="top">if present DB backup is created</td>
</tr>
</tbody>
</table>

Sample:

```dos
powershell .\DNN-Bckup.ps1 -DBName bitboxx -Installpath C:\Inetpub\wwwroot\bitboxx\dnn -LogPath C:\Inetpub\wwwroot\bitboxx\logs -OutputPath C:\Backup\ -DBInstance .\SQLEXPRESS –IncludeLogs –IncludeDNN –IncludeDB
```

### DNN-Restore

Restores a DNN website from a backup previously created with DNN backup. Restores DNN files and database.

Parameters:

<table border="1" cellspacing="0" cellpadding="2">
<tbody>
<tr>
<td valign="top">InstallPath</td>
<td valign="top">Target Installation Folder (must have “\” at the end)</td>
</tr>
<tr>
<td valign="top">WinAccount</td>
<td valign="top">Name of windows account to set folder security (e.g. “Network Service”)</td>
</tr>
<tr>
<td valign="top">WebsiteName</td>
<td valign="top">Name of the website in IIS (e.g. “mywebsite”)</td>
</tr>
<tr>
<td valign="top">WebsiteUrl</td>
<td valign="top">Url of website (eg. “www.mywebsite.com”)</td>
</tr>
<tr>
<td valign="top">DBName</td>
<td valign="top">Name of created database (e.g. “mywebsiteDB”)</td>
</tr>
<tr>
<td valign="top">DBInstance</td>
<td valign="top">Name of SQL Instance (e.g. “.\SQLEXPRESS”)</td>
</tr>
<tr>
<td valign="top">DBUser</td>
<td valign="top">Name of db user with access to database (e.g. “testuser”)</td>
</tr>
<tr>
<td valign="top">DBPassword</td>
<td valign="top">Password of db user (e.g. “testpassword”)</td>
</tr>
<tr>
<td valign="top">InputPath</td>
<td valign="top">Path to Backup files(e.g. "D:\Backup")</td>
</tr>
</tbody>
</table>

Sample:

```dos
powershell .\DNN-Restore.ps1 -Installpath C:\Inetpub\wwwroot\bitboxx\dnn -WinAccount “Network Service” -WebsiteName bitboxx -WebsiteUrl www.bitboxx.net -DBName bitboxx -DBInstance .\SQLEXPRESS $DBUser bitboxx $DBPassword donottell –InputPath C:\Backup\
```