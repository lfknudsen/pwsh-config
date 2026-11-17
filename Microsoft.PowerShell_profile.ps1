# Set output encoding. Doesn't seem to work at all, but I am at my wits' end with getting
# PowerShell to output wide characters correctly.
$OutputEncoding = [Console]::InputEncoding = `
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Make environment use TLS, which is needed for the PowerShell package repositoory.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Undeclared variables cause an exception. Likewise with out of range indexing.
Set-StrictMode -Version 3.0


# =================================================================================================
# FUNCTIONS

function Set-Cursor {
    param(
        [Parameter(Mandatory)][Int32]$Cursor
    )

    $esc = [char]027
    Write-Host "$esc[$Cursor q"
}

function Reset-Cursor {
    $esc = [char]027
    Write-Host "$esc[1 q"
}

# Exits the terminal
function QuitPS {
    Invoke-Command -ScriptBlock { exit }
}

# Silent version of mkdir
function Make-Dir {
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromRemainingArguments = $true
            )]
        [string[]]$path
    )

    $p = [String]::Join(" ", $path)
    New-Item -Type directory -Name $p > $Null
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
        [Parameter(Mandatory, ValueFromPipeline)][string[]]$path
    )
    process {
        foreach ($p in $path) {
            New-Item -ItemType File $p 1> $null
        }
    }
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
    process {
        if ($c) {
            return Remove-Item $paths
        }
        Remove-Item -Confirm $paths
    }
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
# Uses a NerdFont character in the output.
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

function Go-C { Change-Dir 'C:\' }
function Go-D { Change-Dir 'D:\' }
function Go-E { Change-Dir 'E:\' }
function Go-Root { Change-Dir '^' }
function Go-Default { Change-Dir '=' }

# =================================================================================================
# GLOBAL VARIABLES
$global:sep = [System.IO.Path]::DirectorySeparatorChar # / or \
$global:repos = "$pwd${sep}repos" # I have my repositories in a subdirectory to the default directory.
$___initialDirectory___ = $pwd.Path

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
Set-Alias -Name cd^         -Value Go-Root
Set-Alias -Name ^           -Value Go-Root
Set-Alias -Name cd\         -Value Go-Root
Set-Alias -Name \           -Value Go-Root
Set-Alias -Name goto-       -Value Pop-Location
Set-Alias -Name goto~       -Value Go-Home
Set-Alias -Name goto..      -Value Go-Up
Set-Alias -Name rm          -Value Remove-File
Set-Alias -Name new         -Value Create-Item

Set-Alias -Name C:          -Value Go-C
Set-Alias -Name D:          -Value Go-D
Set-Alias -Name E:          -Value Go-E
Set-Alias -Name 'C:\'       -Value Go-C
Set-Alias -Name 'D:\'       -Value Go-D
Set-Alias -Name 'E:\'       -Value Go-E
Set-Alias -Name 'cd='       -Value Go-Default
Set-Alias -Name =           -Value Go-Default

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


# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Inlining the template into the profile shaves off ~10ms (25%).
$script:__COREUTILS__ = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('arch','b2sum','base32','base64','basename','basenc','cat','cksum','comm','cp','csplit','cut','date','df','dirname','du','echo','env','expr','factor','false','find','fmt','fold','grep','head','hostname','join','la','link','ln','ls','md5sum','mkdir','mktemp','mv','nl','nproc','numfmt','od','paste','pathchk','pr','printenv','printf','ptx','pwd','readlink','realpath','rm','rmdir','seq','sha1sum','sha224sum','sha256sum','sha384sum','sha512sum','shuf','sleep','sort','split','stat','sum','tac','tail','tee','test','touch','tr','true','truncate','tsort','unexpand','uniq','unlink','uptime','wc','xargs','yes'),
    [System.StringComparer]::OrdinalIgnoreCase
)

$script:__COREUTILS_FAST_SKIP__ = [regex]::new(
    '\b(?:' + ($script:__COREUTILS__ -join '|') + ')\b',
    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

# Casting the scriptblock to Func<Ast,bool> once and reusing it avoids the
# per-FindAll scriptblock-to-delegate wrapping overhead (~1.7x faster).
$script:__COREUTILS_CMD_PREDICATE__ = [System.Func[System.Management.Automation.Language.Ast, bool]] {
    param($n) $n -is [System.Management.Automation.Language.CommandAst]
}

$script:__COREUTILS_ARG_SPECIAL__ = [char[]] @("'", '"', '`', '$')

# Wrap arguments into quotes. By being a function we can properly handle $variables.
# As per MSVCRT, any `\` before `"` must be doubled to escape them.
function global:__coreutils_q {
    param($s)
    '"' + (([string]$s) -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

# PowerShell tokenizes `*"a"*` as [BareWord] instead of the expected [DoubleQuoted, BareWord, DoubleQuoted].
# To work around that we use... regex. Group 1 = 'single', 2 = "double", 3 = `escape, 4 = bare run.
$script:__COREUTILS_ARG_RX__ = [regex]::new(
    "'((?:[^']|'')*)'|""((?:[^""``]|""""|``.)*)""|``(.)|([^'""``]+)",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:__COREUTILS_ARG_EVAL__ = [System.Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($m.Groups[1].Success) {
        # Single-quoted: literal. PS '' -> ', then MSVCRT-quote.
        $body = $m.Groups[1].Value.Replace("''", "'")
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[2].Success) {
        # Double-quoted: collapse PS quote-escapes to raw " / ', let ExpandString
        # resolve `n / `t / $var, then MSVCRT-quote.
        $body = $m.Groups[2].Value.
        Replace('`"', '"').
        Replace("``'", "'").
        Replace('""', '"')
        $body = $ExecutionContext.InvokeCommand.ExpandString($body)
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[3].Success) {
        # Backtick-escaped char outside a string: " -> \"; everything else
        # becomes a one-char quoted region so glob metas stay literal.
        $c = $m.Groups[3].Value
        if ($c -eq '"') {
            return '\"'
        }
        return '"' + $c + '"'
    }
    # Bare run: passed through unquoted so coreutils can glob it; expand $vars.
    return $ExecutionContext.InvokeCommand.ExpandString($m.Groups[4].Value)
}

# 0: not tested, 1: coreutils not installed, 2: coreutils installed.
$script:__COREUTILS_CMD_DIR_TEST__ = 0

# PSConsoleHostReadLine override that rewrites coreutils command names to their
# .cmd equivalents after PSReadLine returns (history keeps the original).
#
# Why .cmd over .exe: PSNativeCommandArgumentPassing = 'Windows' results in a behavior
# where passing bare quotes to CreateProcess() is impossible. This prevents us from
# passing "*" as "*" to coreutils and instead will be given as a bare *.
# This causes it to treat it as a glob pattern. "*.cmd" files however are automatically
# treated as PSNativeCommandArgumentPassing = 'Legacy', which preserves quotes.
# It is the only possible workaround and the only way coreutils can work at all.
function PSConsoleHostReadLine {
    [System.Diagnostics.DebuggerHidden()]
    param()

    $lastRunStatus = $?
    Microsoft.PowerShell.Core\Set-StrictMode -Off
    $line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)

    # If the line contains no coreutils name, we don't need to parse the AST at all.
    if (-not $script:__COREUTILS_FAST_SKIP__.IsMatch($line)) {
        return $line
    }

    # Roamed/synced profiles can load this snippet on machines where coreutils is not installed.
    # Test for the existence of the command directory once and remember the result.
    if ($script:__COREUTILS_CMD_DIR_TEST__ -eq 0) {
        $script:__COREUTILS_CMD_DIR_TEST__ = 1
        if (Test-Path -LiteralPath 'C:\Program Files\coreutils\cmd\' -PathType Container -ErrorAction Ignore) {
            $script:__COREUTILS_CMD_DIR_TEST__ = 2
        }
    }
    if ($script:__COREUTILS_CMD_DIR_TEST__ -ne 2) {
        return $line
    }

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$null)
    $commands = $ast.FindAll($script:__COREUTILS_CMD_PREDICATE__, $true)

    # Process right-to-left so earlier offsets stay valid after each splice.
    # In-place reverse beats Sort-Object for the typical 1-command line.
    if ($commands.Count -gt 1) {
        $commands = [System.Collections.Generic.List[object]]::new($commands)
        $commands.Reverse()
    }

    foreach ($cmd in $commands) {
        $name = $cmd.GetCommandName()
        if (!$name) {
            continue
        }

        $baseName = $name
        if ($name.EndsWith('.exe') -or $name.EndsWith('.cmd')) {
            $baseName = $name.Substring(0, $name.Length - 4)
        }
        if (!$script:__COREUTILS__.Contains($baseName)) {
            continue
        }

        # ls/la get colour + listing flags injected; la also rewrites to ls.
        $cmdElement = $cmd.CommandElements[0]
        $start = $cmdElement.Extent.StartOffset
        $end = $cmdElement.Extent.EndOffset
        $replacement = "& 'C:\Program Files\coreutils\cmd\"

        switch ($baseName) {
            'la' { $replacement += "ls.cmd' --color=auto -AFhl" }
            'ls' { $replacement += "ls.cmd' --color=auto" }
            default { $replacement += "$baseName.cmd'" }
        }

        # Walk command elements, merging adjacent ones whose extents touch
        # (e.g. `'a'*` parses as [SingleQuoted, BareWord] but is one shell word).
        # The inverse case `*'a'*` parses as a single BareWord whose text
        # contains the embedded quotes, which is why AST-only analysis
        # isn't enough and we still need to re-tokenize the source span.
        $argsStart = $end
        $argsEnd = $cmd.Extent.EndOffset
        $rewrittenArgs = ''
        $elements = $cmd.CommandElements
        $count = $elements.Count
        $i = 1
        while ($i -lt $count) {
            $first = $elements[$i]
            $wordStart = $first.Extent.StartOffset
            $wordEnd = $first.Extent.EndOffset
            $merged = $false
            while ($i + 1 -lt $count -and $elements[$i + 1].Extent.StartOffset -eq $wordEnd) {
                $i++
                $wordEnd = $elements[$i].Extent.EndOffset
                $merged = $true
            }
            $source = $line.Substring($wordStart, $wordEnd - $wordStart)
            $rewrittenArgs += $line.Substring($argsStart, $wordStart - $argsStart)
            $argsStart = $wordEnd
            # IndexOfAny beats running the regex per arg.
            if ($source.IndexOfAny($script:__COREUTILS_ARG_SPECIAL__) -lt 0) {
                $rewrittenArgs += $source
                $i++
                continue
            }
            # A single un-merged PS expression that needs $var resolution
            # (bare $var, "...$var...", $x.Member, $($expr), etc.).
            # Defer evaluation to runtime so the value reaches coreutils as a literal arg.
            # This matches POSIX behaviour where variable expansions don't result in globbing.
            if (-not $merged -and
                ($first -is [System.Management.Automation.Language.VariableExpressionAst] -or
                $first -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
                $first -is [System.Management.Automation.Language.MemberExpressionAst])) {
                $rewrittenArgs += '(__coreutils_q ' + $source + ')'
                $i++
                continue
            }
            # Slow path: re-tokenise and re-emit as MSVCRT-style quoting,
            # then wrap in PS single quotes so PS hands the body verbatim.
            $windowsQuoted = $script:__COREUTILS_ARG_RX__.Replace($source, $script:__COREUTILS_ARG_EVAL__)
            $rewrittenArgs += "'" + $windowsQuoted.Replace("'", "''") + "'"
            $i++
        }
        $rewrittenArgs += $line.Substring($argsStart, $argsEnd - $argsStart)

        $line = $line.Substring(0, $start) + $replacement + $rewrittenArgs + $line.Substring($argsEnd)
    }

    return $line
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a
