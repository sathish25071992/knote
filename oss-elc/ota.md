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

Need to separate Config as separate partition
```
|     -->A Boot---->A Root------->
|BL ->                         Persistant data
|     -->B boot---->B root------->
```

Connectivity can be main check point to see the update was success

### Security
1. Multi stage boot process, runtime changes, vendor specific security mechanism
2. Bootloader validate kernel, initramfs, dtb
3. Initramfs validates ro rootfs (dm-verity)
4. data parition - signing or encrypting via device secret (require trust anchor)
5. bootloader has to be locked-down
### SWUpdate as Update manager
Versatile tool (https://github.com/sbabic/swupdate)

### Secure bootloader
* Uses EFI Boot guard (developed by seimens)
* EFI supportes signed firmware validation (u-boot supports this?)
* U-Boot, software update available, watchdog available and secure boot is available
* Sign FIT image with kenrel, initramfs & dt
* Lock u-boot configuration (https://labs.f-secure.com/publications/u-booting-securely)
* Challenge (update state?)
* Store in external environment (Only required parameter are taken rest will be build-in environment)
* Patches by Marek Vasut

### CIP core layer yocto
https://gitlab.com/Quirin.Gu/isar-cip-core/-/commits/feat/cip-secure-boot

Pointers: talk at CIP Mini Summit 2019

### Delta update
?
