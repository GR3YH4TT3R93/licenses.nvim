#!/usr/bin/env python3

import json
import os
import subprocess
import sys


def eprint(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)


def git(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    if kwargs.get("check") == None:
        kwargs["check"] = True

    return subprocess.run(["git"] + args, **kwargs)


def parse_plugin(plugin) -> dict:
    if isinstance(plugin, str):
        plugin = {"repo": plugin}

    if "://" not in plugin["repo"]:
        plugin["repo"] = "https://github.com/" + plugin["repo"]

    plugin["name"] = ("opt/" if plugin.get("opt") else "start/") + (
        plugin.get("name") or plugin["repo"].split("/")[-1]
    )

    return plugin


def update(prefix):
    with open(prefix + "plugins.json", "r", encoding="utf-8") as f:
        plugins = list(map(parse_plugin, json.load(f)))

    prefix = prefix + "pack/vendor"
    os.makedirs(prefix, mode=0o700, exist_ok=True)

    for path in ["start", "opt"]:
        if not os.path.isdir(path):
            continue

        for name in os.listdir(path):
            name = path + "/" + name
            if not name in map(lambda p: p["name"], plugins):
                eprint("removing " + name)
                git(["rm", "-rf", name])
                git(["add", "-u", name])
                git(
                    [
                        "commit",
                        "--no-gpg-sign",
                        "-m",
                        f"Remove subtree '{name}'",
                    ]
                )

    for plugin in plugins:
        branch = plugin.get("branch")
        if not branch:
            res = git(
                ["ls-remote", "--symref", plugin["repo"]],
                capture_output=True,
                text=True,
            )
            branch = (
                res.stdout.splitlines()[0]
                .split()[1]
                .replace("refs/heads/", "", 1)
            )

        path = prefix + "/" + plugin["name"]
        if os.path.isdir(path):
            if plugin.get("update") == False:
                eprint(f"update disabled for {path}, skipping")
                continue

            action = "pull"
        else:
            action = "add"

        args = [
            "subtree",
            action,
            "--squash",
            "--prefix",
            path,
            plugin["repo"],
            branch,
            "-m",
            f"chore: update '{path}'",
        ]

        eprint("running: git " + " ".join(args))

        git(args)


def main() -> int:
    os.chdir(os.path.dirname(os.path.realpath(__file__)))

    if git(["diff-index", "--quiet", "HEAD"], check=False).returncode:
        eprint("working tree has modifications, first commit all your changes")
        return 1

    base = git(
        ["branch", "--show-current"], capture_output=True, text=True
    ).stdout.rstrip()

    update_branch = "update-plugins"

    eprint("switching branch to " + update_branch)
    git(["switch", "-C", update_branch])

    try:
        for prefix in ("minimal/", ""):
            update(prefix)
    except Exception as e:
        eprint(e)
        eprint(
            "update failed with the above exception, switching back to " + base
        )
        git(["switch", "-f", base])

        return 1

    if not os.path.exists("pack/vendor_minimal"):
        os.symlink("../minimal/pack/vendor", "pack/vendor_minimal")
        git(["add", "pack/vendor_minimal"])
        git(["commit", "--no-gpg-sign", "-m", "chore: add symlink to minimal"])

    eprint("switching back to " + base)
    git(["switch", base])

    if (
        git(["rev-parse", base], capture_output=True, text=True).stdout
        == git(
            ["rev-parse", update_branch], capture_output=True, text=True
        ).stdout
    ):
        eprint("\nAll plugins are up to date, nothing to do")
    else:
        eprint(f"\nPlugins updated, merge {update_branch} to apply changes")

    return 0


if __name__ == "__main__":
    sys.exit(main())
