# PWSH-Config - My PowerShell configuration

Contains my PowerShell $profile. Feel free to be inspired by or copy parts of it.\
I've written comments for my own sake, but hopefully they're helpful to any other readers, too.\
It may include aliases to executables that are not (yet) public on any of my Git accounts. Consider that a little teaser :)

See [this repository](https://gitlab.com/lfknudsen/pwsh) for the PowerShell scripts that I use.


Changes include:
- Changing the prompt:
  - The path is automatically collapsed if very long: `<root>/.../<parent>/<current>`
  - The path is greyed out; only the current directory's name is in white.
  - The "PS" at the start is coloured, as is the `>`
  - If in admin mode, `ADMIN` is displayed first in red, and the `>` changes to
    red, too.
- Removing aliases:
  - PowerShell creates aliases with the name of POSIX commands, binding them to
    PowerShell commands.
    This is awful, because they never have the same signature (e.g. `curl` is
    aliased to `Invoke-WebRequest`), and sometimes they don't even
    do the same thing (e.g. `cat` is aliased to `Read-Content`).
  - I use a binutils/coreutils package which implements most of those standard
    POSIX utilities.
  - I also implement some myself, such as `cd`.
- Adding aliases:
  - My library of cmdlets mostly use names that fit the PowerShell naming scheme
    (even if I don't always bother to use approved verbs). So I alias something
    short to these cmdlets.
  - Providing short-hand ways of doing things, like `..` instead of `cd ..`.
- Adding Bash commands:
  - `-z`, `-n`, `-f`, `-d` are all commands in Bash that don't exist in PowerShell. Now they do!
- Alternative ways to exit:
  - `quit`, `:q`
- Now omits commands from history if a space is put first. It will still show up if you execute `history`,
  but not if you press the up-arrow key, nor in subsequently-created shells.
- Set output encoding to UTF-8.