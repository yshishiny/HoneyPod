@echo off
REM HoneyPod Ansible Wrapper for Windows
REM This script allows running Ansible commands from Windows CMD/PowerShell
REM Usage: ansible [arguments]

setlocal
set PYTHON_PATH=C:\Users\YasserElshishiny\AppData\Local\Programs\Python\Python311\python.exe
%PYTHON_PATH% -m ansible %*
