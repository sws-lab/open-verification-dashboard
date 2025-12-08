FROM ubuntu:26.04
USER root
RUN mkdir /dashboard
WORKDIR /dashboard

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
	autoconf \
	ca-certificates \
	clang \
	git \
	libclang-dev \
	libgmp-dev \
	libmpfr-dev \
	libpcre3-dev=2:8.39-15.1 \
	llvm \
	llvm-dev \
	m4 \
	make \
	ocaml \
	opam \
	patch \
	pkg-config \
	rsync && \
	rm -rf /var/lib/apt/lists/* && \
	useradd -m opam && \
	chown -R opam:opam /dashboard

USER opam

RUN opam init --disable-sandboxing --shell-setup -y && \
	opam switch create . 4.14.2 && \
	opam install dune

RUN	git clone -b checks https://github.com/Robotechnic/analyzer.git && \
	cd analyzer && \
	make deps && \
	make install

RUN	git clone https://gitlab.com/mopsa/mopsa-analyzer.git && \
	cd mopsa-analyzer && \
	LANG=C opam install --deps-only --with-doc --with-test . -y && \
	./configure && \
	make -j && \
	make install
	
COPY . ./dashboard
WORKDIR /dashboard/dashboard

USER root
RUN chown -R opam:opam /dashboard/dashboard
USER opam

# Install dependencies and build
RUN opam install . --deps-only -y &&\
	eval $(opam env) && \
	dune build && \
	dune install --profile release && \
	echo 'eval $(opam env)' >> ~/.bashrc
