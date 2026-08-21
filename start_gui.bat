@echo off
setlocal
set "PYTHONPATH=%~dp0src"
python -m smart_organizer gui
if errorlevel 1 pause

