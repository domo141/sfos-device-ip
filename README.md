
Device IP (sfos)
================

Show network addresses (and default routes) of the interfaces
that are UP.

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

Easiest is to install *.rpm* from public repositories.
If not available or such is considered as a security
risk (installer did things before one had chance to
examine installed content), *.rpm* can be self-built
easily:

    $ ./mk rpms

Build needs perl(1) and md5, sha1 and sha256 perl Digest::
modules.
