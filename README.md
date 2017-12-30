# Plugin to control Dooya DC tubular motors

Plugin for [pimatic](https://pimatic.org/) to support DC tubular motors used in motorized roller blinds made by Chinese company [Dooya](http://www.dooya.com). Requires 433,92 MHz transmitter connected to raspberry pi.

The plugin emulates 433 MHz remote control including "up", "down" and "stop" buttons, so you will need actual values from a remote to replicate. You can't teach a receiver an additional remote because it can only hold one at a time.

## Installation
```
npm install pimatic-dooya
```

Important: if you do not run pimatic as root your user must be a member of the `gpio` group, and you may need to configure udev with the following rule (assuming Raspberry Pi 3):

```console
$ cat >/etc/udev/rules.d/20-gpiomem.rules <<EOF
SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
EOF
```

*This plugin uses _physical_ pin numbering so by default _pin 22_ is used which is GPIO25 pin for raspberry pi 3.*

## Codes
Codes for commands are coded with four pulses which is different from most 433 MHz chipsets. Consider the following image as a reference.

![pulse codes](http://tinkerman.cat/wp-content/uploads/2013/03/4tribits-300x115.jpg)

First goes remote id 32bit sequence which is hardcoded within the chipset then the actual command. Also note that a rotary command (in either direction) takes two different sequential commands to execute.