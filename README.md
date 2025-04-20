# Realme-GT3-neo5-CPU-limiter
A Magisk/KSU bazed module to slow down your CPU to make your screen time better. Highly customizable

# Features
## Avabilive right now
- Can limit your Snapdragon 8+ Gen 1 CPU Frequency to a set amount of freqencies you can set up
- Can change Governor of your CPU to more energy efficient Conservative or fully energy efficient Powersave
- Can disable up to 4 CPU cores to quickly turn down power consumption in cost of raw computing power
- Can store and re-enact current configuration on re-install and updates, so futureproof to possible updates

## Planned for future updates
- More flexible options for governors — choose for each cluster separately, not only for one of them. E.g. Powersave to BIG and PRIME and conservative to LITTLE to better energy efficient without huge perfomace hit, etc.
- Options to dynamicaly enable and disable cores on-the-go (in case you need computing power right now!), featuring by-hand (action button) and by-script options (they would be incompatible with each other)
- Compatibility with other devices, mybe in form of universal script. Also you can adapt module for your kernel, read README and respect license please.

# FAQ
## Limiting freqency of your CPU
Our Snapdragon 8+ Gen 1 are limited by power consumption more than it limited by freqency. That results in situation when, yes, CPU runs on 3Ghz, but it won't execute any code in like 20%+ of the cycles, simply because it reaches hardcoded energy consumption limit. So by lowering freqency by that amount (around 20-25%, this is an "light" setting here), you won't loose any perfomance in games at all, you might even gain some points in benchmarks (lower freq means less heat and power consumed per executed code, so overall CPU can do more math for you at the same 6 what TDP). You can limit your freq even more, when it would realy impact real world performance (medium and higher settings in the script), for more juice of your battery, but then you loose a computing power. It's a tradeoff, like it always was so think carefuly and test your configuration, maybe your programs would run perfectly fine on max freq cut, maybe you notice lag even on medium. You always have to choose your personal tradeoff point where you stop, remember that!

## CPU governors
Stock governor, starting form like android 13 or etc, now are Walt - fairly good governor when you wanna your system to be smooth, as it always maintain boost if needed and etc. But when you want preserve your battery this might not be a best solution, 'cause it always gives CPU far more juice than it needs. Solution for this are alternative Governors, presented in our Kernel, featuring a Conservative and Powersave. Here are list with details of behaviour on every Governor:
- Walt: Boost your CPU instantly on dynamyc amount of freq, any time when demand for CPU rise. Trend to maintain 20-30% of CPU load per core if possible
- Conservative: Looks on your CPU demand every 8000 ns (or 8ms if this number is closer to you), and increase it if CPU runs above "up threshold" to a setted step (+10% in freq), or decreases if it load lower than "down threshold" (same - for -10%). Compared to Walt, freq rises more gradualy, requiring 10 cycles (10x10%) to run fully up or down, so taking down 80ms compared to Walt instant increase. Also this thresholds can be configured, resulting in 3 possible settings in the script - light, medium and max, featuring 75/55, 80/60, 85/65 thresholds each one
- Powersave: Work exacly as a Conservative, but rise up CPU freq only if it hits 100% load and try lower it down as quickly as it is only possible.

Also remember that independently from governors there are input boost that boost CPU freq to a max every time you touch screen, and maintaining this for 100ms, so Conservative and Powersave don't realy take up theoretical 80 ms to rise (freq goes all the way down independently) if you touch screen (scroll, or etc) (note that touch considered as an first touchdown of your finger, if you then glide it on the screen this will NOT result in freq jumping, only when you press finger at the start will cause!), so realy they impact perfomance after that 100ms - would CPU try to gradualy decrease (Conservative), or try to fall down as fast as possible (Powersave)

## Disabling CPU cores
In fact, disabling a CPU core won't physicaly disable it, the CPU just won't put any load on it but core still be powered and run on some freq. Considering that freq are defined for Clusters, not individual cores, this makes disabling whole clusters more profitable compared to separate cores.
For example, you disable a 1x BIG core. Because it still UP and running, just won't compute anything, it will run on the same freq as rest of BIG cores that runs, e.g. jump up to max freq on every finger touch (even if it didn't compute anything, yes), so economy would be not so high than it can be.
Compared to this, when you shut down a full cluster, this will result in it staying in the lowest freqency possible, because there no any load on cluster, why jump up freq?
Considering all of that it is recommended to shut down PRIME core if you don't need it computing power, as it would economy more power than BIG core, even 2 BIG cores disabling


## Why you migh need this?
### Use this you want to improve your Screen On Time by a margin. Gains +10% or more with recommended Medium settings!

# Disclaimer
* I'm not responsible for bricked devices, dead SD cards, thermonuclear war, or you getting fired because the alarm app failed (like it did for me...).
* YOU are choosing to make these modifications, and if you point the finger at me for messing up your device, I will laugh at you.
* Your warranty will be void if you tamper with any part of your device / software.
