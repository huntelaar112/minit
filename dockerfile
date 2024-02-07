ARG USER=root BUILDDIR="/build"

FROM golang:1.21.6-bookworm as build
ARG USER BUILDDIR
CMD /bin/bash
COPY . ${BUILDDIR}
#WORKDIR /build-minit 

RUN cd ${BUILDDIR} && go build -o minit


################################################
FROM debian:12.4
LABEL maintainer="khacman98@gmail.com"

ARG USER BUILDDIR EXPOSE_PORT="80 443 22"
ENV TZ=Asia/Ho_Chi_Minh

COPY --from=build ${BUILDDIR} ${BUILDDIR} 

RUN apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"
RUN chmod +x ${BUILDDIR}/buildconfig && cp ${BUILDDIR}/buildconfig /bin
RUN ${BUILDDIR}/imageSetup/imagePrepare.sh && \
	${BUILDDIR}/imageSetup/imageSystemServices.sh && \
    cp ${BUILDDIR}/minit /bin && \
	${BUILDDIR}/imageSetup/imageCleanup.sh 
   

ENV DEBIAN_FRONTEND="teletype" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

EXPOSE ${EXPOSE_PORT}
ENTRYPOINT ["/bin/minit"]

################################################
# app layer you want to build
