# rsync-ssh

A Distroless container for running `rsync`, including SSH support for remote-shell transfers.

## Build or Pull

Build the image locally:

```sh
podman build -t rsync-ssh .
```

Or pull the published beta image:

```sh
podman pull ghcr.io/bamtests/rsync-ssh:beta
```

The workflow also publishes `ghcr.io/bamtests/rsync-ssh:0.0.<run-number>` for each build. Use a numbered tag to pin a specific build; `beta` always points to the latest one. The image supports `linux/amd64` and `linux/arm64`; the Distroless Static image is about 24 MB. The GHCR package must be public to pull without logging in.

## Run With Podman

Mount the working directory, then pass normal rsync arguments to the image. This example copies between two local directories under the current directory:

```sh
podman run --rm \
	--userns=keep-id:uid=1000,gid=1000 \
	-v "$PWD:/work:rw" -w /work \
	rsync-ssh --archive ./from/ ./to/
```

For a transfer over SSH, mount your SSH configuration read-only. Replace the example host and paths with your own:

```sh
podman run --rm \
	--userns=keep-id:uid=1000,gid=1000 \
	-v "$PWD:/work:rw" -w /work \
	-v "$HOME/.ssh:/home/rsync/.ssh:ro" \
	rsync-ssh --archive ./from/ backup@example.com:/srv/backup/
```

The SSH example also works with the published image by replacing `rsync-ssh` with `ghcr.io/bamtests/rsync-ssh:beta`. The image uses `rsync` as its entrypoint, so options such as `--delete` go after the image name. SSH is rsync's default remote shell.

The container runs as UID 1000. `--userns=keep-id` maps that user to your host user so files written to mounted directories retain your host ownership.

## Optional Wrappers

The wrappers are optional conveniences for mounting local endpoints and SSH files automatically. They default to the locally built `rsync-ssh` image.

For Bash, run:

```sh
bash ./bin/podman-rsync /from/dir/ /to/dir/
```

For Fish, source the function file, then call it:

```fish
source /path/to/rsync-ssh/fish/functions/podman-rsync.fish
podman-rsync /from/dir/ /to/dir/
```

To make either wrapper use the published beta image instead, set `PODMAN_RSYNC_IMAGE` first:

```sh
export PODMAN_RSYNC_IMAGE=ghcr.io/bamtests/rsync-ssh:beta
```

In Fish, use `set -gx PODMAN_RSYNC_IMAGE ghcr.io/bamtests/rsync-ssh:beta`. Both wrappers accept normal rsync options and support local or SSH endpoints.

## Publishing

GitHub Actions publishes the versioned and `beta` tags on pushes to `main`. Manual workflow runs only publish when dispatched from `main`; runs from other branches are skipped.