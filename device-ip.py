#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# $ device-ip.py $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2022 Tomi Ollila
#	    All rights reserved
#
# Created: Mon 06 Jun 2022 23:28:40 EEST too
# Last modified: Mon 13 Jun 2022 21:58:33 +0300 too

from subprocess import Popen, PIPE
from re import compile as re_compile
from datetime import datetime

iface_up_re = re_compile("^\d+:\s+(\S+?):.*[<,]UP[,>]")
ether_re = re_compile("^\s+link/ether\s+(\S+)")
inet_re = re_compile("^\s+inet(6?)\s+(\S+)")

def device_ip():
    iface, ether, text = None, None, ""
    ipv4s = []
    for line in Popen(('/sbin/ip', 'addr'), stdout=PIPE, text=True).stdout:
        m = inet_re.search(line)
        if m:
            if iface is not None:
                if text != "": text = f'{text}<br/>'
                text = f'{text}<b>{iface}</b><br/>\n'
                iface = None
                pass
            if ether is not None:
                text = f'{text}<i>{ether}</i><br/>\n'
                ether = None
                pass
            if m.group(1) != '6':
                text = f'{text}<u>{m.group(2)}</u><br/>\n'
                ipv4s.append(m.group(2))
            else:
                text = f'{text}{m.group(2)}<br/>\n'
                pass
            continue
        m = iface_up_re.search(line)
        if m:
            iface = m.group(1)
            ether = None
            continue
        m = ether_re.search(line)
        if m: ether = m.group(1)
        pass
    now = datetime.now()
    text = f'{text}<br/>Device IP @ {now.strftime("%H:%M:%S")}\n'
    return text, ipv4s


def device_ip_call():
    import pyotherside
    text, ipv4s = device_ip()
    pyotherside.send('update', text, '\n'.join(ipv4s))
    pass


def main():
    text, ipv4s = device_ip()
    #print(text, '\n'.join(ipv4s))
    print(text)
    pass


if __name__ == '__main__':
    main()
    pass  # pylint: disable=W0107
