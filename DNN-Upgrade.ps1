param(
[string]$InstallPath = "c:\inetpub\wwwroot\mywebsite\dnn\",
[string]$WebsiteUrl = "www.mywebsite.com",
[string]$UpgradePackage = "D:\Install\DotNetNuke\DNN_Platform_07.03.04_Upgrade.zip")

## Erlaubt die Ausführung von Skripten: Set-ExecutionPolicy RemoteSigned  
## Hier steht welches Powershell gestartet wird wenn ein Doppelklick auf eine .PS1 Datei gemacht wird:
## HKEY_CLASSES_ROOT\Microsoft.PowerShellConsole.1\Shell\Open\Command

# check if 7-zip is installed
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  

$frameworkRuntime = "v4.0" # "v2.0" oder "v4.0"
$dnnMainversion = "8"

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
write-host "# Upgrade of DNN Site $Installpath" -ForegroundColor Magenta
write-host "#--------------------------------------------------" -ForegroundColor Magenta


#write "app-offline" file
write-host "Create 'App-Offline'-File..." -ForegroundColor DarkYellow
"<html><body><h1>Wartungsarbeiten!</h1><p>Zur Zeit warten wir die Webseite. Bitte versuchen Sie es in einigen Minuten noch einmal!</p></body></html>" | Out-File $Installpath\app_offline.htm -encoding Unicode

#unzip DNN to Targetdirectory
write-host "Unzip DNN Upgrade File..." -ForegroundColor DarkYellow
$param = "-o$InstallPath"
sz x -aoa $UpgradePackage $param

# delete "app-offline" file
write-host "Delete 'App-Offline'-File..." -ForegroundColor DarkYellow
Remove-Item $Installpath/app_offline.htm

#Now open IE and navigate to the site
Write-Host "Start Browser and invoke upgrade ..." -ForegroundColor DarkYellow
$IE = new-object -com "InternetExplorer.Application"
$IE.Visible = $true
$IE.Navigate("http://$WebsiteUrl/install/install.aspx?mode=upgrade")
$doc = WaitUntilReady

Write-Host "Open website..." -ForegroundColor DarkYellow
$IE.Navigate("http://$WebsiteUrl")
$doc = WaitUntilReady


write-host "#--------------------------------------------------" -ForegroundColor Green
Write-Host "# Upgrade of DNN website $WebsiteName ready!" -ForegroundColor Green
write-host "#--------------------------------------------------" -ForegroundColor Green
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

