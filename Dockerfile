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
	for library in /lib/*/libnss_files.so.2 /lib/*/libnss_dns.so.2; do \
		cp -L --parents "$library" /rootfs; \
		for dependency in $(ldd "$library" | awk '$2 == "=>" && $3 ~ /^\// { print $3 } $1 ~ /^\// { print $1 }'); do \
			cp -L --parents "$dependency" /rootfs; \
		done; \
	done; \
	printf 'rsync:x:1000:1000:rsync:/home/rsync:/sbin/nologin\n' > /rootfs/etc/passwd; \
	printf 'rsync:x:1000:\n' > /rootfs/etc/group; \
	printf 'passwd: files\ngroup: files\nhosts: files dns\n' > /rootfs/etc/nsswitch.conf; \
	chown -R 1000:1000 /rootfs/home/rsync

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /rootfs/ /
COPY --from=build /etc/ssh/ssh_config /etc/ssh/ssh_config

ENV HOME=/home/rsync \
	PATH=/usr/bin:/bin
USER 1000:1000
ENTRYPOINT ["/usr/bin/rsync"]