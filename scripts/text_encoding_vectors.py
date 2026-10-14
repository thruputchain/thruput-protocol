#!/usr/bin/env python3
"""Independent public text-encoding vectors; never use for wallet secrets."""

import argparse
import base64
import binascii
import json
from pathlib import Path

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
DESTINATION = Path(__file__).resolve().parents[1] / "fixtures/text-encoding.json"


def base58(data):
    number = int.from_bytes(data, "big")
    digits = []
    while number:
        number, remainder = divmod(number, 58)
        digits.append(ALPHABET[remainder])
    zeros = len(data) - len(data.lstrip(b"\0"))
    return "1" * zeros + "".join(reversed(digits))


def strkey(data, version):
    payload = bytes([version]) + data
    checksum = binascii.crc_hqx(payload, 0).to_bytes(2, "little")
    return base64.b32encode(payload + checksum).decode("ascii").rstrip("=")


def vectors():
    # Published Bitcoin base58 and Stellar SEP-23 examples anchor the oracle.
    assert base58(b"Hello World") == "JxF12TrwUP45BMd"
    stellar = bytes.fromhex(
        "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
    )
    assert strkey(stellar, 6 << 3) == (
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    )
    assert strkey(stellar, 2 << 3) == (
        "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"
    )
    cases = [
        ("empty", b""),
        ("zero", bytes(1)),
        ("leading-zeros", bytes([0, 0, 1, 255])),
        ("hello-world", b"Hello World"),
        ("zero-32", bytes(32)),
        ("native-token", bytes(31) + b"\1"),
        ("incrementing-32", bytes(range(32))),
        ("maximum-32", bytes([255]) * 32),
        ("stellar-sep23", stellar),
        ("signature-64", bytes(range(64))),
        ("opaque-256", bytes(range(256))),
    ]
    valid = []
    for name, data in cases:
        item = {"name": name, "bytes": list(data), "base58": base58(data)}
        if len(data) == 32:
            item["strkey"] = {
                "publicKey": strkey(data, 6 << 3),
                "contract": strkey(data, 2 << 3),
                "seed": strkey(data, 18 << 3),
            }
        valid.append(item)
    return {
        "schemaVersion": 1,
        "valid": valid,
        "invalidBase58": ["0", "O", "I", "l", " 1", "1 ", "1\n", "1\t", "=", "é", "１", "0x01"],
        "invalidStrkey": [
            "GAAAAAAAACGC6",
            "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA",
            "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I",
            "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHG",
            "gaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaawhf",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="regenerate public vectors")
    args = parser.parse_args()
    expected = vectors()
    if args.write:
        DESTINATION.parent.mkdir(parents=True, exist_ok=True)
        DESTINATION.write_text(json.dumps(expected, indent=2) + "\n")
    else:
        assert json.loads(DESTINATION.read_text()) == expected, "encoding vectors differ"
        print("Text encoding vectors match the independent oracle and published examples.")


if __name__ == "__main__":
    main()
