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
# Last modified: Sat 04 Feb 2023 22:58:59 +0200 too

from subprocess import Popen, PIPE
from re import compile as re_compile
from datetime import datetime
from os import access, X_OK

iface_up_re = re_compile("^\d+:\s+(\S+?):.*[<,]UP[,>]")
ether_re = re_compile("^\s+link/ether\s+(\S+)")
inet_re = re_compile("^\s+inet(6?)\s+(\S+)")

ip_cmd = '/sbin/ip' if access('/sbin/ip', X_OK) else '/usr/sbin/ip'

def device_ip():
    iface, ether, text = None, None, ""
    ipv4s = []
    for line in Popen((ip_cmd, 'addr'), stdout=PIPE, text=True).stdout:
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
    text, ipv4s = device_ip()
    return text, '\n'.join(ipv4s)
    pass


def main():
    text, ipv4s = device_ip()
    #print('---\n', text, '\n---\n'.join(ipv4s), '---\n')
    print(text)
    pass


if __name__ == '__main__':
    main()
    pass  # pylint: disable=W0107
