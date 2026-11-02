@echo off
echo this is password managemnt but the bat file instead of a ps1 file
net accounts /minpwlen:12 /maxpwage:30 /minpwage:1 /unique:5 /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30

echo making guest acc gone
net user Guest /active:no

echo policy update
gpupdate /force

echo done cro
pause