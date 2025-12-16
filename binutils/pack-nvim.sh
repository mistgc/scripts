#!/bin/env bash

set -eu

CURRENT_DIR=$(dirname $0)

OUTPUT_FILE=nvim.sfx.sh

DATE=$(date "+%Y%m%d")
PACK_WORKSPACE=/tmp/${DATE}-pack-nvim
OUTPUT_FILE_PATH=${PACK_WORKSPACE}/${OUTPUT_FILE}

mkdir -p ${PACK_WORKSPACE}

NVIM_CONFIG_DIR=$HOME/.config/nvim
NVIM_DATA_DIR=$HOME/.local/share/nvim

OUTPUT_NVIM_CONFIG_TARBALL=${PACK_WORKSPACE}/nvim-config.tar.gz
OUTPUT_NVIM_DATA_TARBALL=${PACK_WORKSPACE}/nvim-data.tar.gz
OUTPUT_NVIM_LATEST_BIN_TARBALL=${PACK_WORKSPACE}/nvim-linux-x86_64.tar.gz

tar -czvf ${OUTPUT_NVIM_CONFIG_TARBALL} --exclude=".git" -C ${NVIM_CONFIG_DIR} .
tar -czvf ${OUTPUT_NVIM_DATA_TARBALL} -C ${NVIM_DATA_DIR} \
    --exclude=".git" \
    --exclude="mason/bin/gopls" \
    --exclude="mason/packages/gopls" \
    --exclude="mason/bin/texlab" \
    --exclude="mason/packages/texlab" \
    --exclude="mason/bin/typescript-language-server" \
    --exclude="mason/packages/typescript-language-server" \
    --exclude="mason/bin/vue-language-server" \
    --exclude="mason/packages/vue-language-server" \
    lazy mason
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    -O ${OUTPUT_NVIM_LATEST_BIN_TARBALL}

ARCHIVE_FILE_PATH=${PACK_WORKSPACE}/archive.tar.gz
tar -czvf ${ARCHIVE_FILE_PATH} -C ${PACK_WORKSPACE} nvim-config.tar.gz nvim-data.tar.gz nvim-linux-x86_64.tar.gz

HEADER_FILE_PATH=${PACK_WORKSPACE}/header.sh

cat > ${HEADER_FILE_PATH} << "EOF"
#!/bin/bash

### NOTE: THIS FILE IS GENERATED. DON'T EDIT IT.

set -eu

PREFIX=${PREFIX:-"./"}
BIN_PREFIX=${BIN_PREFIX:-"/usr/local/"}
DATE=$(date "+%Y%m%d")

get_line() {
    FILE=$1
    awk '/^# ARCHIVE_DATA #$/{print NR; exit}' $FILE
}

MARKER_LINE=$(get_line $0)
echo $MARKER_LINE
if [ -z "${MARKER_LINE}" ]; then
    echo "Error: Cannot found ARCHIVE marker."
    exit 1
fi

OFFSET=$(($(head -n "${MARKER_LINE}" "$0" | wc -c) + 1))

TEMP_DIR=$(mktemp -d 2>/dev/null || (mkdir -p "/tmp/nvim-pack-${DATE}/" && echo "/tmp/nvim-pack-${DATE}/"))
echo "$TEMP_DIR"
if [ ! -d "${TEMP_DIR}" ]; then
    echo "Error: Cannot create TEMP directory."
    exit 1
fi

tail -c +${OFFSET} $0 | base64 -d - | tar -zxf - -C "${TEMP_DIR}"
if [ $? -ne 0 ]; then
    echo "Error: Extracting archive failed."
    rm -rf ${TEMP_DIR}
    exit 1
fi

ls -al ${TEMP_DIR} || { echo "Error: Cannot change directory."; exit 1; }

NVIM_CONFIG_DIR=${PREFIX}/.config/nvim
NVIM_DATA_DIR=${PREFIX}/.local/share/nvim
NVIM_BIN_DIR=${PREFIX}/.local/bin
NVIM_CONFIG_TARBALL=${TEMP_DIR}/nvim-config.tar.gz
NVIM_DATA_TARBALL=${TEMP_DIR}/nvim-data.tar.gz
NVIM_BIN_TARBALL=${TEMP_DIR}/nvim-linux-x86_64.tar.gz

mkdir -p ${NVIM_CONFIG_DIR} ${NVIM_DATA_DIR} ${BIN_PREFIX}
tar -xvf ${NVIM_CONFIG_TARBALL} -C ${NVIM_CONFIG_DIR}
tar -xvf ${NVIM_DATA_TARBALL} -C ${NVIM_DATA_DIR}
tar -xvf ${NVIM_BIN_TARBALL} -C ${TEMP_DIR}

### Install

NVIM_BIN_DIR=${TEMP_DIR}/nvim-linux-x86_64

cp -r ${TEMP_DIR}/nvim-linux-x86_64 /opt/nvim

echo "echo \"export PATH=\$PATH:/opt/nvim/bin\" >> ~/.bashrc"

rm -rf ${TEMP_DIR}

exit 0
EOF

{
    cat ${HEADER_FILE_PATH}
    echo "# ARCHIVE_DATA #"
    base64 ${ARCHIVE_FILE_PATH}
} > ${OUTPUT_FILE_PATH}

chmod +x ${OUTPUT_FILE_PATH}

cp ${OUTPUT_FILE_PATH} ${CURRENT_DIR}/${OUTPUT_FILE}
echo ${PACK_WORKSPACE}

rm -r ${PACK_WORKSPACE}
