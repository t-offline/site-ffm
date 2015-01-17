GLUON_BUILD_DIR := gluon-build
GLUON_GIT_URL := git://github.com/freifunk-gluon/gluon.git
GLUON_GIT_REF := v2014.4

SECRET_KEY_FILE ?= ${HOME}/.gluon-secret-key

_GIT_DESCRIBE = $(shell git describe --tags 2>/dev/null)
ifneq (,${_GIT_DESCRIBE})
  GLUON_RELEASE := ${_GIT_DESCRIBE}
  GLUON_BRANCH := stable
else
  GLUON_RELEASE ?= snapshot~$(shell date '+%Y%m%d')~$(shell git describe --always)
endif

JOBS ?= $(shell cat /proc/cpuinfo | grep processor | wc -l)

GLUON_MAKE := ${MAKE} -j ${JOBS} -C ${GLUON_BUILD_DIR} \
                      GLUON_RELEASE=${GLUON_RELEASE} \
                      GLUON_BRANCH=${GLUON_BRANCH}

all: build manifest

build: gluon-prepare
	echo '${GLUON_RELEASE} (${GLUON_BRANCH})'
	${GLUON_MAKE}

manifest: gluon-prepare
	${GLUON_MAKE} manifest

sign: manifest
	gluon-build/contrib/sign.sh ${SECRET_KEY_FILE} gluon-build/images/sysupgrade/${GLUON_BRANCH}.manifest

${GLUON_BUILD_DIR}:
	git clone ${GLUON_GIT_URL} ${GLUON_BUILD_DIR}

gluon-prepare: ${GLUON_BUILD_DIR}
	(cd ${GLUON_BUILD_DIR} && git fetch origin && git checkout -q ${GLUON_GIT_REF})
	ln -sfT .. ${GLUON_BUILD_DIR}/site
	${GLUON_MAKE} update

clean:
	rm -rf ${GLUON_BUILD_DIR}
