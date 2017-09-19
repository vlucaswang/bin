mkdir nginxbuild
cd nginxbuild

sudo apt-get install build-essential libpcre3 libpcre3-dev zlib1g-dev unzip git autoconf libtool automake -y
wget -O nginx-ct.zip -c https://github.com/grahamedgecombe/nginx-ct/archive/v1.3.2.zip
unzip nginx-ct.zip

git clone https://github.com/bagder/libbrotli
cd libbrotli
# 如果提示 error: C source seen but 'CC' is undefined，可以在 configure.ac 最后加上 AC_PROG_CC
./autogen.sh
./configure
make
sudo make install
cd  ../

git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli
git submodule update --init
cd ../

git clone -b tls1.3-draft-18 --single-branch https://github.com/openssl/openssl.git openssl

wget -c https://nginx.org/download/nginx-1.13.3.tar.gz
tar zxf nginx-1.13.3.tar.gz
cd nginx-1.13.3/
./configure --add-module=../ngx_brotli --add-module=../nginx-ct-1.3.2 --with-openssl=../openssl --with-openssl-opt='enable-tls1_3 enable-weak-ssl-ciphers' --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module
make
sudo make install
