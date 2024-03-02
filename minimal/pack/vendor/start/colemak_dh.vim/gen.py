# SPDX-FileCopyrightText: 2023-2024 Ash <contact@ash.fail>
# SPDX-License-Identifier: MIT

# MIT License

#  Copyright (c) 2023-2024 Ash contact@ash.fail

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from collections.abc import Iterable
from os import chdir
from pathlib import Path
from sys import argv

COLEMAK = {
    "p": ";",
    "t": "b",
    "x": "c",
    "c": "d",
    "k": "e",
    "e": "f",
    "m": "h",
    "l": "i",
    "y": "j",
    "n": "k",
    "u": "l",
    "h": "m",
    "j": "n",
    ";": "o",
    "r": "p",
    "s": "r",
    "d": "s",
    "f": "t",
    "i": "u",
    "z": "x",
    "o": "y",
    "b": "z",
}

MODES = {
    "": [
        lambda lhs, rhs: (lhs.upper(), rhs.upper()),
        "{}",
        "<C-{}>",
        "<C-W>{}",
        lambda lhs, rhs: ("<C-W>" + lhs.upper(), "<C-W>" + rhs.upper()),
        "<C-W><C-{}>",
        "[{}",
        "]{}",
        lambda lhs, rhs: ("g" + lhs.upper(), "g" + rhs.upper()),
        "g{}",
        lambda lhs, rhs: ("x" + lhs.upper(), "z" + rhs.upper()),
        lambda lhs, rhs: ("x" + lhs, "z" + rhs),
        ("<C-W>g{}", ["f", "F", "t", "T"]),
        ("<C-\\><C-{}>", ["n"]),
        ("[<C-{}>", ["D", "I"]),
        ("]<C-{}>", ["D", "I"]),
        ("[{}", ["D", "I", "P"]),
        ("]{}", ["D", "I", "P"]),
        ("g<C-{}>", ["h"]),
        # TODO: zuw, zug, zuW, zuG not tested
    ],
    "i": [
        ("<C-G>{}", ["j", "k", "u"]),
        ("<C-G><C-{}>", ["j", "k", "u"]),
        lambda lhs, rhs: (
            "<C-C><C-" + lhs + ">",
            "<C-X><C-" + rhs + ">",
        ),
        lambda lhs, rhs: (
            "<C-P><C-" + lhs + ">",
            "<C-R><C-" + rhs + ">",
        ),
        "<C-{}>",
        ("<C-\\><C-{}>", ["n"]),
    ],
    "c": [
        (
            "<C-{}>",
            [v for v in COLEMAK if v not in ("l", "i")],
        ),
        ("<C-\\><C-{}>", ["n"]),
    ],
    "v": [
        ("a{}", ["B", "b", "p", "s", "t"]),
        lambda lhs, rhs: ("u" + lhs, "i" + rhs),
    ],
    "o": [
        ("a{}", ["B", "b", "p", "s", "t"]),
        lambda lhs, rhs: ("u" + lhs, "i" + rhs),
    ],
    "t": [("<C-\\><C-{}>", ["n", "o"])],
}


def to_colemak(char: str) -> str:
    if char.isupper():
        return COLEMAK[char.lower()].upper()
    return COLEMAK[char]


REMAPPED: dict[str, list[str]] = {}


def make_map(mode: str, lhs: str, rhs: str) -> str:
    if mode not in REMAPPED:
        REMAPPED[mode] = []

    s = f"    {mode}noremap {lhs} {rhs}\n"
    if rhs not in REMAPPED[mode]:
        s += f"    {mode}noremap {rhs} <Nop>\n"

    REMAPPED[mode].append(lhs)

    return s


def gen_mappings(mode: str, mapping, chars: Iterable[str]) -> Iterable[str]:
    if isinstance(mapping, str):
        for k in chars:
            yield make_map(
                mode, mapping.format(to_colemak(k)), mapping.format(k)
            )
    else:
        for k in chars:
            lhs, rhs = mapping(to_colemak(k), k)
            yield make_map(mode, lhs, rhs)


def main():
    outfile = Path("./autoload/colemak_dh.vim")
    outfile.parent.mkdir(exist_ok=True)

    contents = "function colemak_dh#setup()\n"

    for mode in MODES:
        for mapping in MODES[mode]:
            if isinstance(mapping, tuple):
                chars = mapping[1]
                mapping = mapping[0]
            else:
                chars = list(COLEMAK.keys())
            chars.sort()
            contents += "".join(gen_mappings(mode, mapping, chars))

    for char in ("'", '"', "(", ")", "<", ">", "[", "]", "`", "{", "}"):
        contents += make_map("v", "u" + char, "i" + char)
        contents += make_map("v", "u" + char, "i" + char)

    contents += """    inoremap <C-i> <C-i>
    inoremap <C-m> <C-m>
    cnoremap <C-m> <C-m>
    nnoremap XX ZZ
    vnoremap <nowait> i l
    nnoremap <nowait> z b
    vnoremap <nowait> z b
    noremap <nowait> z b
    noremap O :
    noremap : P
endfunction
"""

    outfile.write_text(contents, encoding="utf-8")


if __name__ == "__main__":
    chdir(Path(argv[0]).parent)
    main()
