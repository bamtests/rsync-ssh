# rsync-ssh

A Distroless container for running `rsync`, including SSH support for remote-shell transfers.

Build it locally:

```sh
podman build -t rsync-ssh .
```

By default, the wrappers use the locally built `rsync-ssh` image. The GitHub Actions workflow publishes `ghcr.io/bamtests/rsync-ssh:0.0.1` and `ghcr.io/bamtests/rsync-ssh:beta` on pushes to `main` and when manually dispatched.

To use the published beta image from Bash:

```sh
export PODMAN_RSYNC_IMAGE=ghcr.io/bamtests/rsync-ssh:beta
bash ./bin/podman-rsync /from/dir/ /to/dir/
```

Or select it in Fish:

```fish
set -gx PODMAN_RSYNC_IMAGE ghcr.io/bamtests/rsync-ssh:beta
podman-rsync /from/dir/ /to/dir/
```

Use the `:0.0.1` tag instead of `:beta` to pin that version. The package must be public to pull it without authenticating to GHCR.

The Bash wrapper runs archive-mode rsync in the image. It bind-mounts the local source and destination directories, mounts `~/.ssh` read-only when present, and forwards `SSH_AUTH_SOCK` when set. The image name can be overridden with `PODMAN_RSYNC_IMAGE`.

Run a local transfer:

```sh
bash ./bin/podman-rsync /from/dir/ /to/dir/
```

Use it from Fish by sourcing the function file:

```sh
source /path/to/rsync-ssh/fish/functions/podman-rsync.fish
podman-rsync /from/dir/ /to/dir/
```

SSH transfers use the same command, with the remote endpoint in standard rsync syntax:

```sh
podman-rsync /from/dir/ backup@example.com:/srv/backup/
podman-rsync backup@example.com:/srv/backup/ /to/dir/
```

Pass rsync options before the source and destination, for example `podman-rsync --delete /from/dir/ /to/dir/`. `--userns=keep-id` maps the container's unprivileged UID to the invoking host user so files written to mounted directories retain the host user's ownership.