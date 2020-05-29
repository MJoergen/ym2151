#!/usr/bin/env python3

import subprocess

def calc_rate(r, kc, ks):
    rate = 2*r + (kc >> (5-ks))
    if rate >= 63:
        rate = 63
    return rate

def configure(ar, rr, kc, ks):
    reg_28 = kc
    reg_80 = ks*0x40 + ar
    reg_e0 = 0xf0 + rr

    f = open("music.txt", "w")
    f.write("2087\n")
    f.write("28" + format(reg_28, '02x') + "\n")
    f.write("4001\n")
    f.write("6000\n")
    f.write("80" + format(reg_80, '02x') + "\n")
    f.write("a000\n")
    f.write("e0" + format(reg_e0, '02x') + "\n")
    f.write("0808\n")
    f.write("0008\n")
    f.write("0800\n")
    f.write("00ff\n")
    f.write("0000\n")
    f.close()

def get_response():
    try:
        res = subprocess.check_output("./atten.sh")
    except subprocess.CalledProcessError as err:
        print("Error:",format(err))
        print("stdout:",format(err.stdout))
        print("stderr:",format(err.stderr))
    try:
        attack_time = res.decode('utf-8').split('Attack: ')[1].split(' ')[0]
        release_time = res.decode('utf-8').split('Release: ')[1].split(' ')[0]
    except IndexError as err:
        print(res.decode('utf-8'))
    return int(attack_time), int(release_time)

tests = [(31, 15, 0x60, 0),
         (31, 15, 0x40, 0),
         (31, 15, 0x20, 0),
         (31, 15, 0x00, 0),
         (29, 14, 0x60, 0),
         (29, 14, 0x40, 0),
         (29, 14, 0x20, 0),
         (29, 14, 0x00, 0),
         (27, 13, 0x60, 0),
         (27, 13, 0x40, 0),
         (27, 13, 0x20, 0),
         (27, 13, 0x00, 0),
         (25, 12, 0x60, 0),
         (25, 12, 0x40, 0),
         (25, 12, 0x20, 0),
         (25, 12, 0x00, 0),
         (23, 11, 0x60, 0),
         (23, 11, 0x40, 0),
         (23, 11, 0x20, 0),
         (23, 11, 0x00, 0),
         (21, 10, 0x60, 0),
         (21, 10, 0x40, 0),
         (21, 10, 0x20, 0),
         (21, 10, 0x00, 0),
         (25, 11, 0x20, 1),
         (25, 11, 0x20, 2),
         (25, 11, 0x20, 3)]

print("AR | RR |  KC  |  KS  | Rate | Attack | Rate | Release")
print("---|----|------|------|------|--------|------|--------")
for ar,rr,kc,ks in tests:
    configure(ar,rr,kc,ks)
    attack_rate  = calc_rate(ar, kc, ks)
    release_rate = calc_rate(rr*2+1, kc, ks)
    attack_time, release_time = get_response()
    print("%2d | %2d | 0x%02x |  %d   | %4d | %6d | %4d | %6d"
            %(ar, rr, kc, ks, attack_rate, attack_time, release_rate, release_time))

