
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host " checking windows users n stuff"
Write-Host ""

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] run as administrator if u want all the info"
}

if (-not (Get-Command Get-LocalUser -ErrorAction SilentlyContinue)) {
    Write-Host "[!] cant find the local user commands"
    exit 1
}

Write-Host "[+] getting all the users"
$users = Get-LocalUser

foreach ($user in $users) {
    Write-Host ""
    Write-Host "user: $($user.Name)"
    Write-Host "  enabled: $($user.Enabled)"
    Write-Host "  password required: $($user.PasswordRequired)"
    Write-Host "  password last set: $($user.PasswordLastSet)"
    Write-Host "  password never expires: $($user.PasswordNeverExpires)"

    if (-not $user.Enabled) {
        Write-Host "  [!] this account is disabled"
    }

    if (-not $user.PasswordRequired) {
        Write-Host "  [!] this account doesnt require a password"
    }

    if ($user.PasswordNeverExpires) {
        Write-Host "  [!] this password never expires"
    }
}

Write-Host ""
Write-Host "who has admin cuz they basically control the pc btw"

$adminGroup = Get-LocalGroup -SID "S-1-5-32-544"

if ($adminGroup) {
    Get-LocalGroupMember -Group $adminGroup.Name |
        Select-Object Name, ObjectClass, PrincipalSource |
        Format-Table -AutoSize
} else {
    Write-Host "[!] cant check the admins group"
}

Write-Host ""
Write-Host "checking for duplicate users"

$duplicates = $users |
    Group-Object Name |
    Where-Object { $_.Count -gt 1 }

if ($duplicates) {
    foreach ($duplicate in $duplicates) {
        Write-Host "[!] duplicate username: $($duplicate.Name)"
    }
} else {
    Write-Host "[+] no duplicate usernames found"
}

Write-Host ""
Write-Host "checking for old passwords"

$cutoff = (Get-Date).AddDays(-90)

foreach ($user in $users) {
    if ($user.Enabled -and $user.PasswordLastSet -and
        $user.PasswordLastSet -lt $cutoff) {
        Write-Host "[!] $($user.Name) has an old password"
    }
}

Write-Host ""
Write-Host "[+] thats all the users checked"
Write-Host "[+] if u couldnt tell this script is done"
