VERSION = $(shell git describe --tags || echo "unknown")
PREFIX = /usr

all: broom doc

broom:
	mkdir -p dist
	sed "s/^VERSION=*.*/VERSION=${VERSION}/" < src/broom.sh > dist/broom.sh

doc:
	mkdir -p dist
	pod2man --section=1 --center="Broom Manual" --name="BROOM" --release="broom ${VERSION}" README.pod > dist/broom.1

dist: clean
	mkdir -p dist/broom-${VERSION}
	cp -R src/ completion/ README.pod dist/broom-${VERSION}
	sed "s/^VERSION = *.*/VERSION = ${VERSION}/" < Makefile > dist/broom-${VERSION}/Makefile
	cd dist && tar cvzf broom-${VERSION}.tar.gz broom-${VERSION}

clean:
	${RM} -r dist

install: broom doc
	install -dm755 ${DESTDIR}${PREFIX}/bin
	install -m755 dist/broom.sh ${DESTDIR}${PREFIX}/bin/broom
	install -dm755 ${DESTDIR}${PREFIX}/share/man/man1
	install -m644 dist/broom.1 ${DESTDIR}${PREFIX}/share/man/man1/broom.1
	install -dm755 ${DESTDIR}/etc/bash_completion.d
	install -m644 completion/completion.bash ${DESTDIR}/etc/bash_completion.d/broom
	install -dm755 ${DESTDIR}/usr/share/zsh/site-functions
	install -m644 completion/completion.zsh ${DESTDIR}/usr/share/zsh/site-functions/_broom

uninstall:
	${RM} ${DESTDIR}${PREFIX}/bin/broom
	${RM} ${DESTDIR}${PREFIX}/share/man/man1/broom.1
	${RM} ${DESTDIR}/etc/bash_completion.d/broom
	${RM} ${DESTDIR}/usr/share/zsh/site-functions/_broom

packages:
	packagecore -o dist ${VERSION}
