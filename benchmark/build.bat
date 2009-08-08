@echo off
cl -c -DWIN32 -I..\..\usbutil -IC:\bin\libusb-win32-device-bin-0.1.12.2\include main.c
cl -Febenchmark.exe *.obj ..\..\usbutil\usbutil.lib c:\bin\libusb-win32-device-bin-0.1.12.2\lib\msvc\libusb.lib
del *.obj *.pdb
