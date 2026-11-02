# Functions being referenced later
function QuitPS {
    Invoke-Command -ScriptBlock {exit}
}

# POSIX commands which PowerShell override with PowerShell commands, but
# where I'd rather use the real thing from a binutils package or similar
Remove-Item alias:curl
Remove-Item alias:ls
Remove-Item alias:cd
Remove-Item alias:man

# Overridding built-in commands to use my version
Set-Alias -Name cd -Value Change-Dir.ps1

# Short-hands for my own programmes/scripts
Set-Alias -Name ndir -Value New-Dir.ps1
Set-Alias -Name download -Value gown.exe
Set-Alias -Name uuid -Value guid.exe
Set-Alias -Name space -Value Disk-Space.ps1
Set-Alias -Name Disk-Size -Value Disk-Space.ps1
Set-Alias -Name path -Value Open-Env.ps1
Set-Alias -Name mkdirs -Value Make-Dirs.ps1

# Short-hands for other applications
Set-Alias -Name vpn -Value 'Mozilla VPN.exe'
Set-Alias -Name 7zip -Value 7z
Set-Alias -Name nana -Value 7z

# Adding another way to perform built-in command
Set-Alias -Name quit -Value QuitPS
Set-Alias -Name :q -Value QuitPS

# Default prompt is:
# function prompt {
#    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' *  ($nestedPromptLevel + 1)) "
# }
#
# Set the prompt
$Global:Admin=''
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = new-object System.Security.principal.windowsprincipal($CurrentUser)
if ($principal.IsInRole("Administrators")) { $Admin='ADMIN ' }
function prompt {
    $Admin + "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}

# Window title
$host.ui.rawui.WindowTitle = "PS $pwd"