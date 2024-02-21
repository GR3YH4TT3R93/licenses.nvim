#!/usr/bin/env python3

import json
import os
import subprocess
import sys


def git(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    if kwargs.get("check") is None:
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


def update(prefix, no_pull: bool):
    with open(prefix + "plugins.json", "r", encoding="utf-8") as f:
        plugins = list(map(parse_plugin, json.load(f)))

    prefix = prefix + "pack/vendor"
    os.makedirs(prefix, mode=0o700, exist_ok=True)

    for subpath in ["start", "opt"]:
        path = prefix + "/" + subpath
        if not os.path.isdir(path):
            continue

        for name in os.listdir(path):
            name = subpath + "/" + name

            if not name in map(lambda p: p["name"], plugins):
                name = prefix + "/" + name
                print("removing " + name, file=sys.stderr)
                git(["rm", "-rf", name])
                git(
                    [
                        "commit",
                        "-m",
                        f"Remove subtree '{name}'",
                    ]
                )

    for plugin in plugins:
        path = prefix + "/" + plugin["name"]

        if os.path.isdir(path):
            if no_pull:
                continue

            if plugin.get("update") == False:
                print(f"update disabled for {path}, skipping", file=sys.stderr)
                continue

            action = "pull"
        else:
            action = "add"

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

        print("running: git " + " ".join(args), file=sys.stderr)

        git(args)


def main() -> int:
    os.chdir(os.path.dirname(os.path.realpath(__file__)))

    no_pull = False

    try:
        no_pull = sys.argv[1] == "--no-pull"
    except IndexError:
        pass

    if git(["diff-index", "--quiet", "HEAD"], check=False).returncode:
        print(
            "working tree has modifications, first commit all your changes",
            file=sys.stderr,
        )
        return 1

    base = git(
        ["branch", "--show-current"], capture_output=True, text=True
    ).stdout.rstrip()

    update_branch = "update-plugins"

    print("switching branch to " + update_branch, file=sys.stderr)
    git(["switch", "-C", update_branch])

    try:
        for prefix in ("minimal/", ""):
            update(prefix, no_pull)
    except Exception as e:
        print(e, file=sys.stderr)
        print(
            "update failed with the above exception, switching back to "
            + base,
            file=sys.stderr,
        )
        git(["switch", "-f", base])

        return 1

    if not os.path.exists("pack/vendor_minimal"):
        os.symlink("../minimal/pack/vendor", "pack/vendor_minimal")
        git(["add", "pack/vendor_minimal"])
        git(["commit", "-m", "chore: add symlink to minimal"])

    print("switching back to " + base, file=sys.stderr)
    git(["switch", base])

    if (
        git(["rev-parse", base], capture_output=True, text=True).stdout
        == git(
            ["rev-parse", update_branch], capture_output=True, text=True
        ).stdout
    ):
        print("\nAll plugins are up to date, nothing to do", file=sys.stderr)
    else:
        print(
            "\nTag before merge in case something goes wrong:\n",
            file=sys.stderr,
        )
        git(["show", "--oneline"])
        print("\nPlugins updated, merging to apply changes", file=sys.stderr)
        git(["merge", update_branch])

    print(f"\nDeleting {update_branch} branch", file=sys.stderr)
    git(["branch", "-D", update_branch])

    nvim_args = ["nvim", "--headless", "+helptags ALL", "+TSUpdateSync", "+q"]
    print("\nRunning " + " ".join(nvim_args), file=sys.stderr)
    subprocess.run(nvim_args, check=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
