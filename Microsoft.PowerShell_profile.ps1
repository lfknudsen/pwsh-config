# Set output encoding. Doesn't seem to work at all, but I am at my wits' end with getting
# PowerShell to output wide characters correctly.
$OutputEncoding = [Console]::InputEncoding = `
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Make environment use TLS, which is needed for the PowerShell package repositoory.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# =================================================================================================
# FUNCTIONS

# Exits the terminal
function QuitPS {
    Invoke-Command -ScriptBlock { exit }
}

# Silent version of mkdir
function Make-Dir {
    param(
        [Parameter(Mandatory = $true)][string]$path
    )

    New-Item -Type directory -Name $path > $Null
}

# Executes `cd ..`
function Go-Up {
    Change-Dir ..
}

# Executes `cd ~`
function Go-Home {
    Change-Dir ~
}

function Go-Back {
    Change-Dir -
}

function Go-Forward {
    Change-Dir +
}

# Retrieves the absolute path to the current location
function Print-Dir {
    $dir = Get-Location
    Write-Output $dir
}

# Creates a new file with the given name.
# If it succeeds, nothing is printed to stdout.
# Will fail if a file with the given name already exists.
function Create-Item {
    param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$path
    )
    New-Item -ItemType File $path 1> $null
}

function IsEmpty {
    param(
        [Parameter(Mandatory, ValueFromPipeline)][Object]$value
    )
    return $null -eq $value -or $value.Length -eq 0
}

function IsBlank {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline)][string]$str
    )
    return [System.String]::IsNullOrWhiteSpace($str)
}

function IsNotEmpty {
    param(
        [Parameter(Mandatory, ValueFromPipeline)][Object]$value
    )
    return !(IsEmpty $value)
}

# Override of `rm` which always asks for confirmation unless user passes argument -c.
function Remove-File {
    param (
        [Parameter(Mandatory = $false)][switch]$c = $false,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromRemainingArguments = $true)]
        [string[]]$paths
    )
    if ($c) {
        return Remove-Item $paths
    }
    Remove-Item -Confirm $paths
}

function File-Exists {
    param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$path
    )
    return [System.IO.File]::Exists($path)
}

function Directory-Exists {
    param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$path
    )
    return [System.IO.Directory]::Exists($path)
}

# Retrieves the name of the current Git branch. Output is formatted for use in the Prompt function.
# If the user is not standing in a Git repository, it returns the empty string.
function Get-Branch {
    $branch = git branch --show-current 2> $null
    if ($?) {
        return " ($([char]0xe725) $esc[3m$branch$esc[0m)"
    } else {
        return ""
    }
}

# ls with some sane defaults.
# Shows as a list with metadata (-l),
# colours directories/symlinks (--color=auto),
# make the filesizes human-readable (-h),
# hides group column (-G),
# hides owner column (-g),
# group directories together (--group-directories-first).
# Supply -time to sort by mod time, -name to sort by name, -ext to sort by extension,
# -size to sort by filesize, and add -rev to any of them to reverse the order.
# Only works on Windows, since it calls `ls.exe` (in order for function to be aliased to `ls`).
function List-DirContents {
    param (
        [Parameter(Mandatory = $false)][switch]$time  = $false,
        [Parameter(Mandatory = $false)][switch]$name  = $false,
        [Parameter(Mandatory = $false)][switch]$ext   = $false,
        [Parameter(Mandatory = $false)][switch]$size  = $false,
        [Parameter(Mandatory = $false)][switch]$rev   = $false,
        [Parameter(Mandatory = $false)][switch]$files = $false,
        [Parameter(Mandatory = $false)][switch]$dirs  = $false
    )
    $arguments = "-lhAGg", "--color=auto"
    # "--group-directories-first" <-- only available in some versions of ls... my laptop has it, my desktop does not
    if ($time -eq $true) {
        $arguments += "--sort=time"
    }
    elseif ($name -eq $true) {
        $arguments += "--sort=name"
    }
    elseif ($ext -eq $true) {
        $arguments += "--sort=extension"
    }
    elseif ($size -eq $true) {
        $arguments += "--sort=size"
    }
    if ($rev -eq $true) {
        $arguments += "--reverse"
    }
    if ($files -eq $true) {
        $arguments += "-F"
        ls.exe $arguments | grep -v "/"
        return
    }
    if ($dirs -eq $true) {
        $arguments += "-F"
        ls.exe $arguments | grep --color=never "/"
        return
    }
    ls.exe $arguments
}

function Location-Stack-Back {
    Get-Location -StackName "primary" 2> $null
    if (!$?) {
        Write-Host "Empty."
    }
}

function Location-Stack-Fwd {
    Get-Location -StackName "secondary" 2> $null
    if (!$?) {
        Write-Host "Empty."
    }
}

# =================================================================================================
# GLOBAL VARIABLES
$global:sep = [System.IO.Path]::DirectorySeparatorChar # / or \
$global:repos = "$pwd${sep}repos" # I have my repositories in a subdirectory to the default directory.

# =================================================================================================
# ALIASES

# POSIX commands which PowerShell override with PowerShell commands, but
# where I'd rather use the real thing from a binutils package or similar.
Remove-Item alias:curl      *> $null
Remove-Item alias:ls        *> $null
Remove-Item alias:cd        *> $null
Remove-Item alias:man       *> $null
Remove-Item alias:pwd       *> $null
Remove-Item alias:cat       *> $null
Remove-Item alias:rm        *> $null
Remove-Item alias:echo      *> $null

# Overridding built-in commands to use my version
Set-Alias -Name cd          -Value Change-Dir.ps1
Set-Alias -Name mkdir       -Value Make-Dir
Set-Alias -Name ls          -Value List-DirContents
Set-Alias -Name pwd         -Value Print-Dir

# Short-hands for my own programmes/scripts
Set-Alias -Name ndir        -Value New-Dir.ps1
Set-Alias -Name download    -Value gown.exe
Set-Alias -Name uuid        -Value guid.exe
Set-Alias -Name space       -Value Disk-Space.ps1
Set-Alias -Name Disk-Size   -Value Disk-Space.ps1
Set-Alias -Name path        -Value Open-Env.ps1
Set-Alias -Name mkdirs      -Value Make-Dirs.ps1
Set-Alias -Name hide        -Value Hide-File.ps1
Set-Alias -Name reveal      -Value Reveal-File.ps1
Set-Alias -Name unhide      -Value Reveal-File.ps1
Set-Alias -Name cd-         -Value Go-Back
Set-Alias -Name cd~         -Value Go-Home
Set-Alias -Name cd..        -Value Go-Up
Set-Alias -Name cd+         -Value Go-Forward
Set-Alias -Name goto-       -Value Pop-Location
Set-Alias -Name goto~       -Value Go-Home
Set-Alias -Name goto..      -Value Go-Up
Set-Alias -Name rm          -Value Remove-File
Set-Alias -Name new         -Value Create-Item

# Debugging
Set-Alias -Name -back       -Value Location-Stack-Back
Set-Alias -Name -fwd        -Value Location-Stack-Fwd

# Emulating commands from other shells
Set-Alias -Name '-z'        -Value IsEmpty
Set-Alias -Name '-n'        -Value IsNotEmpty
Set-Alias -Name '-f'        -Value File-Exists
Set-Alias -Name '-d'        -Value Directory-Exists

# Short-hands for other applications
Set-Alias -Name vpn         -Value 'Mozilla VPN.exe'
Set-Alias -Name 7zip        -Value 7z
Set-Alias -Name nana        -Value 7z
Set-Alias -Name :e          -Value nvim

# Adding another way to perform built-in command
Set-Alias -Name quit        -Value QuitPS
Set-Alias -Name :q          -Value QuitPS
Set-Alias -Name ..          -Value Go-Up
Set-Alias -Name ~           -Value Go-Home
Set-Alias -Name whereami    -Value Print-Dir
Set-Alias -Name here        -Value Print-Dir
Set-Alias -Name read        -Value Get-Content

# =================================================================================================
# PROMPT

# Default prompt is:
# function prompt {
#    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' *  ($nestedPromptLevel + 1)) "
# }
#
# Set the prompt
# Check the security identity of the user so we can prepend prompt with "ADMIN ".
$local:___Admin___ = ''
$private:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$private:Principal = new-object System.Security.principal.windowsprincipal($CurrentUser)
if ($Principal.IsInRole("Administrators")) { $___Admin___ = 'ADMIN ' }

function prompt {
    $local:esc = [char]27 # \033 aka \e
    $debugPrefix = if (Test-Path Variable:/PSDebugContext) { "$esc[32mDEBUG " } else { '' }
    $branch = ""#Get-Branch # Commented out because it's noticeably slower

    $current = $executionContext.SessionState.Path.CurrentLocation.Path
    $path = $([System.IO.Path]::GetDirectoryName($current))
    # If we're at root, $base will be root, and will be coloured accordingly.
    $base = $current

    # If not at root...
    if ($null -ne $path) {
        # If prompt string is too long, collapse the internal path parts.
        # Will always keep the first and last parts of the path, which will be prepended to
        # the current directory's name.
        # Example: "C:/.../Documents/WindowsPowerShell"
        if ($current.Length + $branch.Length -gt 50) {
            $path = $path.ToString().TrimEnd($sep)
            $parts = $path.ToString().Split($sep)
            if ($parts.Length -gt 2) {
                $path = "$($parts[0])$sep…$sep$($parts[$parts.Length - 1])$sep"
            }
        }
        
        # If we're not at root, we ensure the parent path ends in a path separator.
        if ($path[$path.Length - 1] -ne $sep) {
            $path += $sep
        }
        # If we're not at root, we separate the final directory so it can be coloured accordingly.
        $base = $($current.Substring($current.LastIndexOf($sep) + 1))
    }

    # Set window title. We set it inside this function so that it's updated whenever the working directory changes.
    $host.ui.rawui.WindowTitle = "$path$base"

    # The caret(s) at the end is/are coloured depending on mode.
    $caretColour = "$esc[36m"
    if ($___Admin___ -ne '') {
        $caretColour = "$esc[31m"
    }

    # Return value. Example: "ADMIN PS E:\repos\pwsh>" 
    "$debugPrefix$esc[31m$___Admin___$esc[36mPS$esc[0m $esc[90m$path$esc[0m$base$branch$caretColour$('>' * ($nestedPromptLevel + 1)) $esc[0m"
}

# Specify how to prevent a command from being added to history.
# Here it's any command which starts with a(t least one) space, like in Bash.
# Note that the `history` command will still show them, but they won't show up in subsequent
# shells or when pressing the up-arrow to cycle through history.
Set-PSReadLineOption -AddToHistoryHandler {
    param($command)
    return (!($command -like ' *'))
}

# Add argument completer for the dotnet CLI tool
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock
