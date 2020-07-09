Source: https://ossna2020.sched.com/event/c3Wx/secure-boot-and-over-the-air-updates-thats-simple-no-jan-kiszka-siemens-ag?iframe=no&w=100%&sidebar=yes&bg=no

Requirement
===========
unaddended update\
update should be Robust (atomic, roll-back capable)\

CIP (Multiple working group) contains software update WG

Dual copy update
----------------
Pros: simple and robust\
Cons: Transfer size, Storage\

Need to separate Config as separate partition\
|     -->A Boot---->A Root------->\
BL ->                         Persistant data\
|     -->B boot---->B root------->

Connectivity can be main check point to see the update was success

### Security
Multi stage boot process, runtime changes, vendor specific securiy mechanism
Bootloader validate kernel, initramfs, dtb
Initramfs validates ro rootfs (dm-verity)
data parition - signing or encrypting via device secret (require trust anchor)
bootloader has to be locked-down
### SWUpdate as Uodate manager

