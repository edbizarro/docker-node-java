# AlpineLinux with a glibc-2.23 and Oracle Java 8
FROM alpine:3.5

MAINTAINER Eduardo Bizarro <edbizarro@gmail.com>

# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=102 \
    JAVA_VERSION_BUILD=14 \
    JAVA_PACKAGE=jdk \
    JAVA_JCE=standard \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_VERSION=2.23-r3 \
    LANG=C.UTF-8

# do all in one step
RUN apk upgrade --update && \
    apk add --update libstdc++ curl ca-certificates bash && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" >&2 && \
      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del curl glibc-i18n && \
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf


ENV VERSION=v7.4.0

ENV CONFIG_FLAGS="--fully-static" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

RUN apk add --no-cache curl make gcc g++ python linux-headers paxctl libgcc libstdc++ gnupg && \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
		  9554F04D7259F04124DE6B476D5A82AC7E37093B \
		  94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
		  0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
		  FD3A5288F042B6850C66B31F09FE44734EB7990E \
		  71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
		  DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
		  C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
		  B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
		curl -o node-${VERSION}.tar.gz -sSL https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz && \
		curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc && \
		gpg --verify SHASUMS256.txt.asc && \
		grep node-${VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
		tar -zxf node-${VERSION}.tar.gz && \
		cd node-${VERSION} && \
		export GYP_DEFINES="linux_use_gold_flags=0" && \
		./configure --prefix=/usr ${CONFIG_FLAGS} && \
		NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
		make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
		paxctl -cm out/Release/mksnapshot && \
		make -j${NPROC} && \
		make install && \
		paxctl -cm /usr/bin/node && \
		cd / && \
		if [ -x /usr/bin/npm ]; then \
		  npm install -g npm && \
		  find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
		fi && \
		apk del curl make gcc g++ python linux-headers paxctl gnupg ${DEL_PKGS} && \
		rm -rf /etc/ssl /node-${VERSION}.tar.gz /SHASUMS256.txt.asc /node-${VERSION} ${RM_DIRS} \
		  /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
		  /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html

RUN apk add --update git		
				
# EOF