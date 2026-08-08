# remote-zed-opener

ever wanted to type `zed .` inside your ssh session on a remote linux server and have it instantly pop open in zed on your macbook?

yeah, me too. so i built this.

---

### copy to your ai prompt

```text
install and set up remote-zed-opener on this linux machine so typing `zed .` opens the current directory in zed on my macbook over ssh.

1. fetch installer: curl -fsSL https://raw.githubusercontent.com/yigitkonur/remote-zed-opener/main/install.sh | bash
2. check if passwordless ssh works both ways (mac -> linux and linux -> mac).
3. ensure mac remote login is enabled (system settings -> general -> sharing -> remote login).
4. ask or detect mac ssh host alias (e.g. macbook) and linux ssh host alias (e.g. hetzner).
5. save config to ~/.config/remote-zed-opener/config with MAC_HOST, REMOTE_HOST, and MAC_ZED_BIN.
6. run `zed .` to verify it opens zed on the macbook.
```

---

## how it works

1. you run `zed .` on your remote linux server
2. the script ssh'es back to your mac (`ssh macbook`)
3. it calls zed's cli on your mac with `zed ssh://hetzner/path/to/folder`
4. zed on your mac connects to your linux box over ssh and opens the folder natively
5. pure magic. zero file sync, zero code duplication.

## TL;DR install

run this on your remote linux server:

```bash
curl -fsSL https://raw.githubusercontent.com/yigitkonur/remote-zed-opener/main/install.sh | bash
```

it puts `zed` inside `~/.local/bin/zed` and walks you through a 10 second interactive setup.

---

## step-by-step setup guide

for this magic to work, **passwordless ssh must work in BOTH directions**.

### 0. enable ssh on your mac (remote login)

macOS disables incoming ssh by default. you need to turn it on:

1. open **System Settings** on your mac
2. go to **General** -> **Sharing**
3. toggle **Remote Login** to **ON**
4. click `(i)` next to Remote Login and ensure your user account has access

or just run this in your mac terminal:
```bash
sudo systemsetup -setremotelogin on
```

> **official guide**: see [apple's remote login guide](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac) for more info.

---

### 1. mac -> linux (zed's connection)

your mac needs to reach your linux box via an ssh alias without asking for a password.

on your mac, edit `~/.ssh/config`:

```ssh
Host hetzner
    HostName 65.108.140.207
    User root
    IdentityFile ~/.ssh/id_ed25519
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
    HostName 100.124.210.121   # tailscale ip or local ip
    User mac                    # your mac username
    IdentityFile ~/.ssh/id_ed25519
```

test it from your linux terminal:
```bash
ssh macbook "echo ok"
# should output: ok (no password prompt!)
```

> **tip**: using [tailscale](https://tailscale.com) makes this 10x easier because your mac and server get permanent stable ips no matter where your laptop is.

---

### 3. zed cli on your mac

make sure zed's cli is installed on your mac.

open zed on your mac, hit `cmd + shift + p`, and run:
```
zed: install cli
```
this creates `/usr/local/bin/zed` on your mac.

---

### 4. install remote-zed-opener on linux

now run the installer on your linux box:

```bash
curl -fsSL https://raw.githubusercontent.com/yigitkonur/remote-zed-opener/main/install.sh | bash
```

it will ask you two simple questions:
- **mac ssh host**: `macbook` (the alias from step 2)
- **remote host name**: `hetzner` (the alias from step 1)

and saved! config lives in `~/.config/remote-zed-opener/config`.

---

## usage

```bash
# open current directory in zed on mac
zed .

# open a specific file or folder
zed src/main.rs

# open in a brand new zed window
zed -n .

# re-configure anytime
zed --setup
```

## environment variables

you can also override options via env vars:

- `ZED_MAC_HOST` - ssh host for mac (default: `macbook`)
- `ZED_REMOTE_HOST` - ssh host for this linux box as seen by mac (default: `$(hostname)`)
- `ZED_MAC_BIN` - path to zed cli on mac (default: `/usr/local/bin/zed`)

## license

mit
