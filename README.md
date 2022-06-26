
Device IP (sfos)
================

Show network addresses of the interfaces that are UP.

(and the time peeked -- click the title 'Device IP'
 to update)

Runs on (mobile) devices running Sailfish OS.


Code
----

`device-ip.qml` and `device-ip.py` provides the executable,
`device-ip.desktop` how it is executed and `device-ip.spec`
how it is built.

`device-ip.png` is the launcher icon -- tolerably small
binary blob to be available in code repository.


Install
-------

Easiest is to install *.rpm* from public repositories.
If not available or such is considered as a security
risk (installer did things before one had chance to
examine installed content), *.rpm* can be self-built
using the .spec file provided. I am not sure what is
the proper way, so I just use `./devdev.sh rpmbuild`
to do it.
