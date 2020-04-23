FROM python:3.7.3-stretch

WORKDIR /tmp

ENV JUMANPP_VERSION=2.0.0-rc3

ENV MECAB_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE" \
    IPADIC_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM" \
    JUMAN_DOWNLOAD_URL="http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.01.tar.bz2" \
    JUMANPP_DOWNLOAD_URL="https://github.com/ku-nlp/jumanpp/releases/download/v${JUMANPP_VERSION}/jumanpp-${JUMANPP_VERSION}.tar.xz"
# KNP_DOWNLOAD_URL="http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/knp-4.20.tar.bz2"
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libboost-dev cmake && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# install mecab
RUN curl -SL -o mecab-0.996.tar.gz ${MECAB_URL} && \
    tar zxf mecab-0.996.tar.gz
WORKDIR /tmp/mecab-0.996
RUN ./configure --enable-utf8-only --with-charset=utf8 && make && make install

# install mecab-ipadic
WORKDIR /tmp
RUN curl -SL -o mecab-ipadic-2.7.0-20070801.tar.gz ${IPADIC_URL} && \
    tar zxf mecab-ipadic-2.7.0-20070801.tar.gz && \
    ldconfig
WORKDIR /tmp/mecab-ipadic-2.7.0-20070801
RUN ./configure --with-charset=utf8 && make && make install

# install mecab-ipadic-neologd
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git && \
    mecab-ipadic-neologd/bin/install-mecab-ipadic-neologd -n -y && \
    rm -rf *

# install juman
WORKDIR /tmp
RUN curl -L -o juman.tar.bz2 "${JUMAN_DOWNLOAD_URL}" && \
    tar xjvf juman.tar.bz2 -C /tmp
WORKDIR /tmp/juman-7.01
RUN ./configure --prefix=/usr/local/ && make && make install

# install juman++
WORKDIR /tmp
RUN curl -L -o jumanpp.tar.xz "${JUMANPP_DOWNLOAD_URL}" && \
    tar xJvf jumanpp.tar.xz
WORKDIR /tmp/jumanpp-${JUMANPP_VERSION}

# hadolint ignore=DL3003
RUN mkdir bld && cd bld && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/ && \
    make .. && make install

RUN echo "include /usr/local/lib" >> /etc/ld.so.conf && ldconfig
WORKDIR /tmp
RUN rm -rf *