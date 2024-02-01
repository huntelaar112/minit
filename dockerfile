FROM golang:1.21.6-bookworm as build

ARG USER=root
ADD --chown=${USER}:${USER} . /build-minit 
WORKDIR /build-minit 

RUN go build -o minit



FROM debian:12.4
LABEL maintainer="khacman98@gmail.com"

ARG EXPOSE_PORT="80 443"
ENV TZ=Asia/Ho_Chi_Minh

COPY --from=build /build-minit /build-minit 
RUN /build-minit/image-prepare.sh && \
	/build-minit/image-system_services.sh && \
	/build-minit/image-cleanup.sh && \
    cp /build-minit/minit /bin

ENV DEBIAN_FRONTEND="teletype" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

EXPOSE ${EXPOSE_PORT}
CMD ["/bin/minit"]