# Changelog

All notable changes to remote-zed-opener. Versions follow [semver](https://semver.org).

## [1.0.0] - 2026-11-10

### Faster: both ssh hops stay warm

- **Linux → Mac.** Every `zed` call used to pay a fresh ssh handshake to the Mac (1.0–1.3 s measured over Tailscale). The first call now opens one multiplexed connection that stays up for 4 hours after the last call; later calls take 0.24–0.32 s.
- **Mac → Linux.** Zed reuses a running ssh master it finds at the `ControlPath` the Mac's `~/.ssh/config` sets for the Linux host. After each call, `zed` keeps one such master up on the Mac. A Zed window opened when no window for that host is open now skips the ssh login (`reusing existing ControlMaster, skipping authentication` in Zed's log). Nothing extra is opened when the host has no `ControlPath`.
- **No more hangs.** An asleep or unreachable Mac made `zed .` hang for the OS TCP timeout (75 s measured). It now fails in about 5 s with a message naming the Mac. A connection that went stale while the Mac slept recovers in about 9 s, or fails cleanly in about 14 s if the Mac is still away.

### Fixed

- `zed .` sent `…/dir/.`, `zed ..` sent `…/sub/..`, and top-level paths such as `zed /usr` sent `ssh://host//usr`. Paths are now resolved to clean absolute paths.
- Paths containing `#`, `?`, `%XX`, spaces, non-ASCII or newlines (including a trailing one) could open the wrong folder, because Zed parses the argument as a URL. The path is now percent-encoded, and every byte reaches Zed intact.
- `zed a b` failed on Zed 1.27 with "cannot open both local and ssh paths". Each path is now opened in its own call.
- Flags that take a value (`--user-data-dir X`), `--`, `-` and `--diff` were mangled into ssh URLs. Flags are now an allowlist (`-n -a -e -w --version`); anything else exits 2 with a message.
- `MAC_ZED_BIN=~/…` broke on bash 4 and later. The tilde now expands on the Mac.
- `zed` inside a `while read` loop swallowed the rest of the loop's input.
- `zed --setup` wrote the answers unescaped into a config file that is sourced on every run: a `"` broke every command, and `$(…)` ran on each call. Host answers are now validated and the file is written with shell quoting. Existing config files keep working.
- `zed --setup` without a terminal exited silently. It now says how to write the config by hand.
- Errors from ssh or the Mac now say what to do next: "could not reach <mac>" or "no zed cli at <path> on <mac>; run zed --setup".

### Installer

- `curl … | bash` never ran the interactive setup, because stdin is the script. It now asks on the terminal (`/dev/tty`), and keeps an existing config on upgrade.
- It installed whatever file named `zed` was in the current directory. It now copies only from its own checkout, and otherwise downloads the `zed` of the same release.
- It wrote through an existing symlink, so it could overwrite the Zed editor's own Linux CLI. It now refuses to replace a `zed` (file, symlink or dangling symlink) that isn't remote-zed-opener, and installs atomically.
- A captive portal or proxy page returned with HTTP 200 would have been installed as `zed`. The download is now checked first, and nothing changes if it's wrong.
- The PATH hint always printed `$HOME/.local/bin`, even with a custom `INSTALL_DIR`.
- Installs come from GitHub releases: `releases/latest/download/install.sh` for the newest version, or `releases/download/vX.Y.Z/install.sh` to pin one.

### Added

- [`zed-gate`](zed-gate): an optional forced command for the Mac's `authorized_keys`. It limits the Linux box's key to opening `ssh://<alias>/…` paths in Zed, the setup's connection test and the warm-up commands. Everything else is denied.
- `zed --help` shows the version.
- A MIT `LICENSE` file. The README said MIT, but there was no license file.

### Docs

- The README documented env-var defaults that did not exist (`ZED_MAC_HOST` and `ZED_REMOTE_HOST` are required), said setup asks two questions (it asks three), and gave an outdated Zed command name (it is now `cli: install cli binary`).
- New notes: the Mac must be awake with you logged in to the desktop; `sudo systemsetup -setremotelogin on` needs Full Disk Access for the terminal; Homebrew installs the Zed CLI at `/opt/homebrew/bin/zed`.
- Example hosts are now placeholders (`203.0.113.10`, `macbook.your-tailnet.ts.net`, `<mac-username>`) instead of real addresses.
- New sections: fast repeat opens, lock it down, uninstall. The AI-agent prompt now says which steps need you on the Mac.

### Known limitations

- Zed starts a new remote server for every new window, so opening a new folder still takes a moment. A folder that's already open just gets focus, and `zed -a` adds to the open window.
- The Linux side needs bash.

## [0.1.0] - 2026-08-08

- First version: `zed` shim, `install.sh` and README (untagged).

[1.0.0]: https://github.com/yigitkonur/remote-zed-opener/releases/tag/v1.0.0
