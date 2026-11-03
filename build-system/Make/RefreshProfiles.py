#!/usr/bin/env python3
"""Re-sign fake provisioning profiles with a future expiration date.

The checked-in profiles are CMS-signed with SelfSigned.p12 and expire on
2026-10-30.  rules_apple rejects expired profiles, so before building we
decode each profile, push its ExpirationDate into the future and re-sign it
with the same fake certificate.
"""
import argparse
import glob
import os
import re
import subprocess
import sys


def run(cmd):
    return subprocess.run(cmd, check=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profiles-dir', required=True)
    parser.add_argument('--cert-p12', required=True)
    parser.add_argument('--password', default='')
    args = parser.parse_args()

    cert_pem = '/tmp/fake_cert.pem'
    with open(cert_pem, 'wb') as f:
        run(['openssl', 'pkcs12', '-in', args.cert_p12,
             '-out', cert_pem, '-nodes', '-passin', 'pass:' + args.password])

    new_expiry = '2030-12-31T23:59:59Z'
    old_expiry = '2026-10-30T17:06:30Z'

    for profile_path in sorted(glob.glob(os.path.join(args.profiles_dir, '*.mobileprovision'))):
        plist_path = '/tmp/profile.plist'
        # decode CMS -> plist (no signature verification)
        run(['openssl', 'smime', '-inform', 'der', '-verify', '-noverify',
             '-in', profile_path, '-out', plist_path])
        with open(plist_path, 'r', encoding='utf-8') as f:
            text = f.read()
        text = text.replace(old_expiry, new_expiry)
        with open(plist_path, 'w', encoding='utf-8') as f:
            f.write(text)
        # re-sign
        run(['openssl', 'smime', '-sign', '-in', plist_path, '-out', profile_path,
             '-signer', cert_pem, '-inkey', cert_pem,
             '-outform', 'DER', '-nodetach'])
        # verify
        run(['openssl', 'smime', '-inform', 'der', '-verify', '-noverify',
             '-in', profile_path, '-out', '/dev/null'])
        print('Refreshed:', os.path.basename(profile_path))

    print('All profiles refreshed.')


if __name__ == '__main__':
    main()
