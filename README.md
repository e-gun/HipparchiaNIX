You probably need to start here. 

These files should allow you to install an environment with all of the tools to support 
HipparchiaBuilder and HipparchiaServer.

At the moment there are two options: 

[a] Install onto FreeBSD

[b] Install into macOS

Windows installations are theoretically possible. You just have to manually do what is
outlined in the specific cases: install python, install postgresql, acquire the support
files, configure 'config.ini' and 'config.py' so that they can find everything. 

Linux installations will look a lot like FreeBSD installations.


The FreeBSD files will build a firewalled server dedicated to Hipparchia. A certain amount of 
prior knowledge is presupposed.

The macOS version is simpler. It comes in two versions: 

[1] a walkthrough that guides you through the commands to send the terminal. 
[2] a somewhat more **dangerous** automated installation that may or may not do it all for you

If #2 does not work, you will have to try to walk through #1 but with the disadvantage
that a bunch of things will already be half-installed. 

If you feel lucky, open Terminal.app and paste the following into it:

```
curl https://raw.githubusercontent.com/e-gun/HipparchiaBSD/master/automated_macOS_install.sh | /bin/bash
```