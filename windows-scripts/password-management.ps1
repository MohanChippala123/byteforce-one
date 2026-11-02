Write-Host "pswd and shit"
net accounts /minpwlen:12 /maxpwage:30 /minpwage:1 /unique:5 /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30

Write-Host "fuc that guest account"
Disable-LocalUser -Name "Guest" -ErrorAction SilentlyContinue

Write-Host "making sure the psds dont expire"
$users = Get-LocalUser | Where-Object { $_.Name -notin @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount") }
foreach ($user in $users) {
    Set-LocalUser -Name $user.Name -PasswordNeverExpires $false -ErrorAction SilentlyContinue
    Write-Host "Updated settings for: $($user.Name)"
}

Write-Host "refrshing the group polocy thing"
gpupdate /force

Write-Host "its done btw"