# Copyright (C) 2026 Sam Dornan
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# ==========================================
# STAGE 1: The Harvester (Pure Trixie Edition)
# ==========================================

# 0. Uses standard Debian for testing and harvesting the necessary binaries and libraries
FROM debian:13 AS harvester

# 1. Install prerequisites
RUN apt-get update && apt-get install -y curl ca-certificates

# 2. Securely prepare the keyring directory
RUN mkdir -p /usr/share/keyrings

# 3. Pull the modern SHA-256 key directly from the rpi-image-gen repo
RUN curl -fsSL https://raw.githubusercontent.com/raspberrypi/rpi-image-gen/master/keydir/raspberrypi-archive-keyring.gpg \
    -o /usr/share/keyrings/raspberrypi-archive-keyring.gpg

# 4. Use the Modernized DEB822 format required by Trixie
RUN echo "Types: deb\n\
URIs: http://archive.raspberrypi.com/debian/\n\
Suites: trixie\n\
Components: main\n\
Signed-By: /usr/share/keyrings/raspberrypi-archive-keyring.gpg" > /etc/apt/sources.list.d/raspi.sources

# 5. Install required underlying utilities
RUN apt-get update && apt-get install -y curl raspi-utils

# ==========================================
# STAGE 2: The Final Base (Distroless Debian 13)
# ==========================================

#0. Uses debug version of Distroless base image, which includes a busybox shell to run bash scripts.
FROM gcr.io/distroless/base-debian13:debug

# 1. Bring over the binaries
COPY --from=harvester /usr/bin/curl /usr/bin/curl
COPY --from=harvester /usr/bin/vcgencmd /usr/bin/vcgencmd

# 2. Bring over the shared libraries required by those binaries
COPY --from=harvester /lib/aarch64-linux-gnu/ /lib/aarch64-linux-gnu/
COPY --from=harvester /usr/lib/aarch64-linux-gnu/ /usr/lib/aarch64-linux-gnu/
COPY --from=harvester /lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1

ENV PATH="/usr/bin:/bin"
ENV LD_LIBRARY_PATH="/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu"