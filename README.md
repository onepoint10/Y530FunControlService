# Y530FunControlService
Service to reduce noise from the cooling system on a Lenovo Legion laptop by controlling сooler speed blocking. This service automates disabling and enabling auto-mode of the cooling system.
Work only on Windows as service and on the Lenoveo Legion Y530/Y7000P 2018 laptop. Performance on other laptops and desktops has not been tested.

WARNING! There is some foolproof, but still you do everything at your own peril and risk!

# INSTALLATION GUIDE
1. Download [NoteBookFanControl](https://github.com/hirschmann/nbfc/releases/tag/1.6.3)
2. Install normally to C:\Program Files (x86)\NoteBook FanControl
3. Сreate a new text file in the C:\Program Files (x86)\NoteBook FanControl folder, with this contents:
```
cd C:\Program Files (x86)\NoteBook FanControl
ec-probe.exe write 171 0x09
exit
```
and save with the extension changed to "Fan_stop.bat".

4. Create a second text document in the same folder, with this contents:

```
cd C:\Program Files (x86)\NoteBook FanControl
ec-probe.exe write 171 0x00
exit
```
and save with the extension changed to "Fan_auto.bat".

5. Download the release archive from [releases](https://github.com/onepoint10/Y530FunControlService/releases) and unpack it to "C:\Program Files (x86)\NoteBook FanControl\". There should appear a "service" folder with files inside.

6. Install the [CoreTemp](https://4pda.to/pages/go/?u=https%3A%2F%2Fwww.alcpu.com%2FCoreTemp%2FCore-Temp-setup.exe&e=92142374) program, also shaky, in C:\Program Files\Core Temp. From it we will take the temperature.

ATTENTION, THE DATA PATH AND NAMES (everything in paragraphs 2,3,4) MUST MATCH WITH THE SPECIFIED!

7. In the "service" package, right-click on install.bat and run with administrator rights. You should see a window saying that everything was successfully installed.
There is now a "FanControlService" service in Windows Services. That will do magic.

# Settings description 
There are settings in the setting.ini file:
```
[Main]

WriteLog=1 - write a log (if "0", then do not write)
StartState=1 - state when the service is started, if set to "1" - it will start in the "auto" mode, that is, it will transfer the CO to the normal mode of operation, with a periodic call, if "0" - immediately sets the mode to "stopped" - fixes the current value cooler rotation speed)

[Special]

heattemp=70 - temperature at which the laptop switches to "auto" mode, condition ">".
coldtemp=45 - temperature at which the laptop switches to colded mode, condition "<" (turn on the timer to delay the activation of the "stopped" mode).
deltatemp=0 - delta to check the condition that they have definitely cooled down (that is, if the current temperature is <= coldtemp + deltatemp during delaytime, then turn on the "stopped" mode, if the temperature has gone beyond these limits, then the laptop has not cooled down yet and set it again auto state).
delaytime=6000 - timer time to check if the cooldown is accurate, in ms.
countmax=250 - protection against early activation of the stopped mode - if the current revolutions were fixed, but they were not equal to zero. this is a counter of timer cycles, after overflowing of which, it forcibly switches to the auto state.
StartSleepTime=2000 - pause at service start, in ms. this is so that CoreTemp.exe will definitely have time to start.
core=1 - the number of the core by which we check the whole thing.
timerinterval=700 - TTimer period in ms.
```

Everything is done on a regular TTimer, the period is set to 700ms (timerinterval setting) -  it seems to me that the period is optimal, but if necessary, you can change that in the settings. In the CoreTemp settings, you can set the temperature value update rate to 500ms (1s by default). 

After installing and rebooting the computer, the service automatically starts working (if it finds all the necessary exe and bat, if it does not find it, it will log in and will not work). You can follow the progress of the work in the log - each change of state is recorded there, as well as errors if something is not found.

**ATTENTION! The content of .bat files is not checked automatically, so it is better to check their work manually first.**

CoreTemp does not need to be started, it will start automatically, also as this service.

Enjoy using.

# A VERY IMPORTANT ADDITION! 

**If you use the utility and you have two systems on your laptop (win + hackintosh / linux), you need to disable hibernation, because. when the hibernation mode is enabled, the service does not see the shutdown event and can leave the laptop in the mode of the disabled cooling system. You will boot into another system with no cooling at all!**

To disable hibernation, at the command prompt, type 
```
powercfg -h off 
```
and press Enter.

# P.S. 
Additions and improvements are welcome.
