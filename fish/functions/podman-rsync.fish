function podman-rsync
    if test (count $argv) -lt 2
        echo 'Usage: podman-rsync [rsync-options...] SOURCE DEST' >&2
        return 2
    end

    set -l podman podman
    set -q PODMAN; and set podman $PODMAN
    set -l image rsync-ssh
    set -q PODMAN_RSYNC_IMAGE; and set image $PODMAN_RSYNC_IMAGE

    if not command -q $podman
        echo "podman-rsync: Podman command not found: $podman" >&2
        return 127
    end

    set -l rsync_args $argv
    set -l source_index (math (count $argv) - 1)
    set -l destination_index (count $argv)
    set -l mount_paths

    for index in $source_index $destination_index
        set -l endpoint $rsync_args[$index]
        if test "$endpoint" = -
            continue
        end

        set -l remote false
        if not string match -q '/*' -- "$endpoint"
            if string match -q '*:*' -- "$endpoint"; and not string match -q '*/*:*' -- "$endpoint"
                set remote true
            end
        end
        if test "$remote" = true
            continue
        end

        set -l trailing_slash ''
        string match -q '*/' -- "$endpoint"; and set trailing_slash /
        if not string match -q '/*' -- "$endpoint"
            set endpoint "$PWD/$endpoint"
        end
        set endpoint (command realpath -m -- "$endpoint")
        if test "$endpoint" = /
            echo 'podman-rsync: refusing to bind-mount the host root directory' >&2
            return 2
        end
        test -n "$trailing_slash"; and set endpoint "$endpoint/"
        set rsync_args[$index] "$endpoint"

        set -l mount_path (string replace -r '/+$' '' -- "$endpoint")
        test -n "$mount_path"; or set mount_path /
        if not test -d "$mount_path"
            set mount_path (command dirname -- "$mount_path")
            while not test -d "$mount_path"; and test "$mount_path" != /
                set mount_path (command dirname -- "$mount_path")
            end
        end
        if test "$mount_path" = /
            echo 'podman-rsync: endpoint must be below an existing directory other than /' >&2
            return 2
        end
        contains -- "$mount_path" $mount_paths; or set -a mount_paths "$mount_path"
    end

    set -l podman_args run --rm --userns=keep-id:uid=1000,gid=1000
    for mount_path in $mount_paths
        set -a podman_args --volume "$mount_path:$mount_path:rw"
    end

    set -l ssh_dir "$HOME/.ssh"
    set -q SSH_DIR; and set ssh_dir $SSH_DIR
    if test -d "$ssh_dir"
        set ssh_dir (command realpath -m -- "$ssh_dir")
        set -a podman_args --volume "$ssh_dir:/home/rsync/.ssh:ro"
    end

    if set -q SSH_AUTH_SOCK; and test -S "$SSH_AUTH_SOCK"
        set -a podman_args --volume "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" --env "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    end

    command $podman $podman_args $image --archive $rsync_args
end