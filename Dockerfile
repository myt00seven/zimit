FROM oldwebtoday/chrome:84 as chrome

FROM nikolaik/python-nodejs:python3.8-nodejs14

RUN apt-get update -y \
    && apt-get install --no-install-recommends -qqy fonts-stix locales-all \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PROXY_HOST=localhost \
    PROXY_PORT=8080 \
    PROXY_CA_URL=http://wsgiprox/download/pem \
    PROXY_CA_FILE=/tmp/proxy-ca.pem \
    NO_SOCAT=1

RUN pip install gevent>=20.9.0 pywb uwsgi

RUN pip install warc2zim==1.1.0

COPY --from=chrome /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/
COPY --from=chrome /lib/x86_64-linux-gnu/libdbus* /lib/x86_64-linux-gnu/

RUN useradd zimit --shell /bin/bash --create-home \
  && usermod -a -G sudo zimit \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'zimit:secret' | chpasswd

WORKDIR /app

ADD package.json /app/

RUN chown -R zimit /app

RUN yarn install

ADD config.yaml /app/
ADD uwsgi.ini /app/
ADD run.sh /app/
ADD index.js /app/
RUN ln -s /app/run.sh /usr/bin/zimit

CMD ["zimit"]
