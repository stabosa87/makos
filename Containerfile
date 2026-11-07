ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
# Empty for the base image; otherwise one of IMAGE_FLAVORS from image.env.
ARG IMAGE_FLAVOR=""

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ${BASE_IMAGE}
ARG IMAGE_FLAVOR

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" /ctx/build.sh

RUN bootc container lint
