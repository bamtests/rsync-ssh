FROM debian:bookworm-slim AS build

RUN apt-get update \
	&& apt-get install -y --no-install-recommends rsync openssh-client \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eu; \
	mkdir -p /rootfs/home/rsync /rootfs/etc; \
	cp --parents /usr/bin/rsync /usr/bin/ssh /rootfs; \
	for binary in /usr/bin/rsync /usr/bin/ssh; do \
		for library in $(ldd "$binary" | awk '$2 == "=>" && $3 ~ /^\// { print $3 } $1 ~ /^\// { print $1 }'); do \
			cp -L --parents "$library" /rootfs; \
		done; \
	done; \
	printf 'rsync:x:1000:1000:rsync:/home/rsync:/sbin/nologin\n' > /rootfs/etc/passwd; \
	printf 'rsync:x:1000:\n' > /rootfs/etc/group; \
	chown -R 1000:1000 /rootfs/home/rsync

FROM gcr.io/distroless/base-debian12:nonroot

COPY --from=build /rootfs/ /
COPY --from=build /etc/ssh/ssh_config /etc/ssh/ssh_config

ENV HOME=/home/rsync \
	PATH=/usr/bin:/bin
USER 1000:1000
ENTRYPOINT ["/usr/bin/rsync"]