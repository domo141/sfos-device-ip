
Device IP (sfos)
================

Show network addresses of the interfaces that are UP.

(and the time queried -- tap the title 'Device IP' to update)

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

It is easiest to install the *.rpm* from public repositories.
If it is not available or such is considered a security
risk (installer did things before one had chance to examine
installed content), the *.rpm* can be self-built easily:

    $ ./mk rpm

Build needs perl(1) and md5, sha1 and sha256 perl Digest::
modules.
