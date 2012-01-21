VERSION = $(shell git describe --tags)
PREFIX = /usr

all: broom doc

broom:
	mkdir -p out
	sed "s/^VERSION=*.*/VERSION=${VERSION}/" < src/broom.sh > out/broom.sh

doc:
	mkdir -p out
	pod2man --section=1 --center="Broom Manual" --name="BROOM" --release="broom ${VERSION}" README.pod > out/broom.1

dist: clean
	mkdir -p out/broom-${VERSION}
	cp -R src/ completion/ README.pod out/broom-${VERSION}
	sed "s/^VERSION = *.*/VERSION = ${VERSION}/" < Makefile > out/broom-${VERSION}/Makefile
	cd out && tar cvzf broom-${VERSION}.tar.gz broom-${VERSION}

clean:
	${RM} -r out

install: broom doc
	install -Dm755 out/broom.sh ${DESTDIR}${PREFIX}/bin/broom
	install -Dm644 out/broom.1 ${DESTDIR}${PREFIX}/share/man/man1/broom.1
	install -Dm644 completion/completion.bash ${DESTDIR}/etc/bash_completion.d/broom
	install -Dm644 completion/completion.zsh ${DESTDIR}/usr/share/zsh/site-functions/_broom

uninstall:
	${RM} ${DESTDIR}${PREFIX}/bin/broom
	${RM} ${DESTDIR}${PREFIX}/share/man/man1/broom.1
	${RM} ${DESTDIR}/etc/bash_completion.d/broom
	${RM} ${DESTDIR}/usr/share/zsh/site-functions/_broom