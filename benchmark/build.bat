@echo off
cl -c -DWIN32 -I..\common -IC:\bin\libusb-win32-device-bin-0.1.12.2\include main.c
cl -Fecounter.exe *.obj ..\common\*.obj c:\bin\libusb-win32-device-bin-0.1.12.2\lib\msvc\libusb.lib
del *.obj *.pdb
