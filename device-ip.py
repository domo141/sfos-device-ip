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
# Last modified: Thu 11 Sep 2025 21:02:41 +0300 too

from subprocess import Popen, PIPE
from re import compile as re_compile
from datetime import datetime
from os import access, X_OK

iface_up_re = re_compile(r"^\d+:\s+(\S+?):.*[<,]UP[,>]")
ether_re = re_compile(r"^\s+link/ether\s+(\S+)")
inet_re = re_compile(r"^\s+inet(6?)\s+(\S+)")

route_re = re_compile(r"^default\s+via\s+(\S+).*?\sdev\s+(\S+)")

ip_cmd = '/sbin/ip' if access('/sbin/ip', X_OK) else '/usr/sbin/ip'

def device_ip():
    iface, ether, text = None, None, []
    ipv4s = []
    for line in Popen((ip_cmd, 'addr'), stdout=PIPE, text=True).stdout:
        m = inet_re.search(line)
        if m:
            if iface is not None:
                if text: text.append('<br/>')
                text.append(f'<b>{iface}</b><br/>')
                iface = None
                pass
            if ether is not None:
                text.append(f'<i>{ether}</i><br/>')
                ether = None
                pass
            if m.group(1) != '6':
                text.append(f'<u>{m.group(2)}</u><br/>')
                ipv4s.append(m.group(2))
            else:
                text.append(f'{m.group(2)}<br/>')
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

    text.append(f"<br/><br/>\n<b>default routes:</b><br/>'''''''''''''''<br/>")
    for line in Popen((ip_cmd, 'route', 'show', 'table', 'all'),
                      stdout=PIPE, text=True).stdout:
        m = route_re.search(line)
        if m:
            text.append(f'{m.group(2)}: {m.group(1)}<br/>')
            pass
        pass

    now = datetime.now()
    text.append(f'<br/>Device IP @ {now.strftime("%H:%M:%S")}')

    text = "\n".join(text)
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
