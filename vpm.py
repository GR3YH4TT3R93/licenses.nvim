#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from argparse import ArgumentParser


def err(msg: str):
    print(sys.argv[0] + ": " + msg, file=sys.stderr)


def git(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    if kwargs.get("check") is None:
        kwargs["check"] = True
    args.insert(0, "git")
    err(" ".join(args))
    return subprocess.run(args, **kwargs)


def get_plugins(plugins_path: list[str]) -> list[dict] | None:
    plugins = []
    for path in plugins_path:
        if not os.path.isfile(path):
            err(f"file doesn't exist: {path}")
            return None

        with open(path, encoding="utf-8") as f:
            for plugin in json.load(f):
                if isinstance(plugin, str):
                    plugin = {"repo": plugin}

                if "://" not in plugin["repo"]:
                    plugin["repo"] = "https://github.com/" + plugin["repo"]

                plugin["name"] = (plugin.get("opt") and "opt/" or "start/") + (
                    plugin.get("name") or plugin["repo"].split("/")[-1]
                )

                if plugin.get("update") is False:
                    plugin["update"] = "none"

                plugins.append(plugin)

    return plugins


def clean(plugins: list[dict]):
    res = git(["submodule", "status"], capture_output=True, text=True)
    for sm in [s.strip().split(" ")[1] for s in res.stdout.splitlines(False)]:
        if not any(v["name"] == sm for v in plugins):
            git(["rm", sm])


def install(plugin: dict):
    branch = plugin.get("branch")
    git(
        ["submodule", "add", "--force"]
        + (branch and ["--branch", branch] or [])
        + [plugin["repo"], plugin["name"]]
    )


def update(plugin: dict):
    branch = plugin.get("branch")
    git(["submodule", "update", "--init", "--remote", plugin["name"]])
    if branch:
        git(
            [
                "submodule",
                "set-branch",
                "--branch",
                branch,
                plugin["name"],
            ]
        )


def main(action: str, plugins_path: list[str], pack_path: str) -> int:
    if not (plugins := get_plugins(plugins_path)):
        return 1

    if len(plugins) == 0:
        err("no plugins specified")
        return 1

    os.makedirs(pack_path, exist_ok=True)
    os.chdir(pack_path)

    if not os.path.isdir(pack_path + "/.git"):
        git(["init"])

    if action in {"clean", "sync"}:
        clean(plugins)

    if action != "clean":
        for plugin in plugins:
            first_install = False
            if not os.path.isdir(plugin["name"]):
                first_install = True
                install(plugin)

            if update_mode := plugin.get("update"):
                git(
                    [
                        "config",
                        "submodule." + plugin["name"] + ".update",
                        update_mode,
                    ]
                )

            if not first_install and action != "install":
                update(plugin)

    git(
        ["commit", "-a", "--allow-empty-message", "--no-gpg-sign", "-m", ""],
        check=False,
    )

    return 0


if __name__ == "__main__":
    p = ArgumentParser()
    p.add_argument(
        "action",
        nargs=1,
        choices=("clean", "install", "sync", "update"),
        metavar="ACTION",
    )
    p.add_argument("plugins", nargs="+", metavar="PLUGINS")
    p.add_argument(
        "-d",
        "--dir",
        nargs=1,
        default=[
            os.getenv(
                "XDG_DATA_HOME",
                default=os.path.expanduser("~") + "/.local/share",
            )
            + "/nvim/site/pack/vpm"
        ],
    )
    parsed = p.parse_args()
    sys.exit(main(parsed.action[0], parsed.plugins, parsed.dir[0]))
