#!/usr/bin/env python3

import json
from os import chdir
from pathlib import Path
from sys import argv
from urllib.request import urlopen


def main():
    with urlopen("https://spdx.org/licenses/licenses.json") as f:
        Path("licenses/index.txt").write_text(
            "\n".join(
                [v["licenseId"] for v in json.loads(f.read())["licenses"]]
            ),
            "utf-8",
        )

    # some licenses to include by default
    for v in (
        "AGPL-3.0-only",
        "AGPL-3.0-or-later",
        "Apache-2.0",
        "BSD-2-Clause",
        "BSD-3-Clause",
        "CC0-1.0",
        "GPL-3.0-only",
        "GPL-3.0-or-later",
        "LGPL-3.0-only",
        "LGPL-3.0-or-later",
        "MIT",
        "MPL-2.0",
        "Unlicense",
    ):
        with urlopen(f"https://spdx.org/licenses/{v}.json") as f:
            details = json.loads(f.read())

            Path(f"licenses/text/{v}.txt").write_text(
                details.get(
                    "standardLicenseTemplate", details["licenseText"]
                ).strip(),
                "utf-8",
            )

            header = details.get(
                "standardLicenseHeaderTemplate",
                details.get("standardLicenseHeader", ""),
            )
            if header:
                Path(f"licenses/header/{v}.txt").write_text(
                    header.strip(), "utf-8"
                )


if __name__ == "__main__":
    chdir(Path(argv[0]).parent)
    main()
