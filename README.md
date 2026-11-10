# remote-zed-opener

ever wanted to type `zed .` inside your ssh session on a remote linux server and have it instantly pop open in zed on your macbook?

yeah, me too. so i built this.

---

### copy to your ai prompt

```text
install and set up remote-zed-opener on this linux machine so typing `zed .` here opens the folder in zed on my mac over ssh.

you are on the linux box and cannot change the mac: ask me to do the mac steps.

1. ask me to confirm on the mac: remote login is on (system settings -> general -> sharing -> remote login), the zed cli is installed (zed command palette: "cli: install cli binary"), and the mac's ~/.ssh/config has an alias for this linux box (e.g. hetzner).
2. check that this box reaches the mac without a password: `ssh -o BatchMode=yes <mac alias> echo ok` (e.g. macbook). if it fails, help me set up a key and a Host block on this box.
3. install: curl -fsSL https://github.com/yigitkonur/remote-zed-opener/releases/latest/download/install.sh | bash
4. without a terminal for the setup questions, write ~/.config/remote-zed-opener/config yourself:
   MAC_HOST=<the mac's alias on this box>
   REMOTE_HOST=<this box's alias on the mac>
   MAC_ZED_BIN=/usr/local/bin/zed
5. run `zed .` and ask me whether zed opened the folder on my mac.
```

---

## how it works

1. you run `zed .` on your remote linux server
2. the script ssh'es back to your mac (`ssh macbook`) over one connection it keeps open
3. it calls zed's cli on your mac with `zed ssh://hetzner/path/to/folder`
4. zed on your mac connects to your linux box over ssh and opens the folder natively
5. zero file sync, zero code duplication.

## fast repeat opens

both ssh hops are kept warm, so only the first open of the day pays for an ssh login:

- **linux → mac**: the first `zed` call opens an ssh connection to the mac that stays up for 4h after the last call (openssh `ControlMaster`, socket in `$XDG_RUNTIME_DIR/rzo` or `~/.cache/rzo`). measured over tailscale: 1.2 s for the first call, 0.2–0.3 s after that (it used to be ~1.1 s every time).
- **mac → linux**: zed reuses a running ssh master it finds at the `ControlPath` your mac's `~/.ssh/config` sets for the linux host, and then skips the ssh login. after each call the script keeps one such master up on the mac (4h after last use). this needs two lines in the linux host's block on your mac, plus `mkdir -p ~/.ssh/sockets`:

  ```ssh
  Host hetzner
      ControlMaster auto
      ControlPath ~/.ssh/sockets/%C
  ```

  without a `ControlPath` for the host, nothing extra is opened.
- **zed itself**: a folder that's already open just gets focus. a new folder opens a new window, and zed starts a fresh remote server for every new window. `zed -a` adds the folder to the open window instead.

## TL;DR install

run this on your remote linux server:

```bash
curl -fsSL https://github.com/yigitkonur/remote-zed-opener/releases/latest/download/install.sh | bash
```

it installs the latest [release](https://github.com/yigitkonur/remote-zed-opener/releases) to `~/.local/bin/zed` and asks three setup questions on your terminal (an existing config is kept). run the same command again to upgrade. it refuses to overwrite a `zed` that isn't this script, such as the zed editor's own linux cli.

to pin a version, swap `latest/download` for `download/v1.0.0`. what changed in each release: [CHANGELOG.md](CHANGELOG.md).

---

## step-by-step setup guide

for this to work, **passwordless ssh must work in BOTH directions**, and your mac must be awake with you logged in to the desktop (zed is started through macos launchservices).

### 0. enable ssh on your mac (remote login)

macos disables incoming ssh by default. turn it on:

1. open **System Settings** on your mac
2. go to **General** -> **Sharing**
3. toggle **Remote Login** to **ON**
4. click `(i)` next to Remote Login and make sure your user account has access

the terminal route, `sudo systemsetup -setremotelogin on`, only works when your terminal app has Full Disk Access; the settings route above always works.

> **official guide**: see [apple's remote login guide](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac).

---

### 1. mac -> linux (zed's connection)

your mac needs to reach your linux box via an ssh alias without asking for a password.

on your mac, edit `~/.ssh/config`:

```ssh
Host hetzner
    HostName 203.0.113.10          # your server's ip or dns name
    User <linux-user>
    IdentityFile ~/.ssh/id_ed25519
    ControlMaster auto             # optional: lets zed skip the ssh login (see "fast repeat opens")
    ControlPath ~/.ssh/sockets/%C
```

test it from your mac terminal:
```bash
ssh hetzner "echo ok"
# should output: ok (no password prompt!)
```

---

### 2. linux -> mac (the remote trigger)

your linux box needs to reach your mac without a password prompt.

on your linux box, edit `~/.ssh/config`:

```ssh
Host macbook
    HostName macbook.your-tailnet.ts.net   # tailscale name/ip or local ip
    User <mac-username>
    IdentityFile ~/.ssh/id_ed25519
```

test it from your linux terminal:
```bash
ssh macbook "echo ok"
# should output: ok (no password prompt!)
```

> **tip**: [tailscale](https://tailscale.com) makes this much easier: your mac and server keep stable addresses no matter where your laptop is.

---

### 3. zed cli on your mac

open zed on your mac, hit `cmd + shift + p`, and run:
```
cli: install cli binary
```
this creates `/usr/local/bin/zed` on your mac. installed zed with homebrew instead? then the cli is `/opt/homebrew/bin/zed`; give that path in the setup.

---

### 4. install remote-zed-opener on linux

run the installer on your linux box:

```bash
curl -fsSL https://github.com/yigitkonur/remote-zed-opener/releases/latest/download/install.sh | bash
```

it asks three questions:
- **mac ssh host**: `macbook` (the alias from step 2)
- **this box's alias on your mac**: `hetzner` (the alias from step 1)
- **zed cli path on your mac**: `/usr/local/bin/zed` (step 3)

config lives in `~/.config/remote-zed-opener/config`. run `zed --setup` to change it.

---

## usage

```bash
# open current directory in zed on mac
zed .

# open a specific file, or a file at a line
zed src/main.rs
zed src/main.rs:12

# open in a brand new zed window
zed -n .

# add a folder to the open zed window
zed -a ../other-project

# several paths are opened one after the other
zed src docs

# re-configure anytime
zed --setup
```

flags passed on to zed: `-n/--new`, `-a/--add`, `-e/--existing`, `-w/--wait`, `--version`. other zed flags don't make sense across ssh and are refused.

## configuration

`~/.config/remote-zed-opener/config` holds `MAC_HOST`, `REMOTE_HOST` and `MAC_ZED_BIN`. env vars override it:

- `ZED_MAC_HOST` - ssh host for the mac on this box (required)
- `ZED_REMOTE_HOST` - this box's ssh host as seen by the mac (required)
- `ZED_MAC_BIN` - path to the zed cli on the mac (default: `/usr/local/bin/zed`)

## lock it down (optional)

the linux box holds a key that logs into your mac without a password. if the box were compromised, that key would give a shell on your mac. [`zed-gate`](zed-gate) limits the key to opening folders in zed:

1. on the linux box, make a dedicated key and use it for the mac:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_zed
   ```
   in the `Host macbook` block: `IdentityFile ~/.ssh/id_ed25519_zed` and `IdentitiesOnly yes`.
2. on the mac, copy [`zed-gate`](zed-gate) to `~/.local/bin/zed-gate`, `chmod 755` it, and set `ZED` (same as `MAC_ZED_BIN`) and `ALIASES` (the linux boxes' aliases) at the top.
3. on the mac, add the new public key to `~/.ssh/authorized_keys` with a forced command:
   ```
   restrict,command="/Users/<you>/.local/bin/zed-gate" ssh-ed25519 AAAA... zed@linux-box
   ```
   add `from="<linux box ip>",` in front to also pin where it may come from.

the key can then only run zed with `ssh://<alias>/...` paths (or `zed --version`), the setup's `echo ok` test, and the two fixed warm-up commands (`ssh -O check <alias>` and the one that starts the master); anything else is denied.

## uninstall

```bash
rm ~/.local/bin/zed
rm -r ~/.config/remote-zed-opener ~/.cache/rzo
```

on the mac, remove the zed-gate line from `~/.ssh/authorized_keys` if you added one.

## license

MIT, see [LICENSE](LICENSE).
