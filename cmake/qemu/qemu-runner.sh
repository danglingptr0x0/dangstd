#!/bin/sh
set -eu

ARCH=""
BINARY=""
VARIANT="dev"
KERNEL_MODULE=""
MODULE_NAME=""
DKMS=0
GCOV_DIR=""
BUILD_DIR=""
DATA_DIR=""
TIMEOUT=120
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/id_qemu_test"
SSH_CONTROL="/tmp/qemu-ssh-$$"
SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 -o ControlMaster=auto -o ControlPath=${SSH_CONTROL} -o ControlPersist=30"

VIRSH="virsh -c qemu:///system"
VM_NAME_PREFIX="qemu-test"

while [ $# -gt 0 ]; do
    case "$1" in
        --arch) ARCH="$2"; shift 2 ;;
        --binary) BINARY="$2"; shift 2 ;;
        --variant) VARIANT="$2"; shift 2 ;;
        --kernel-module) KERNEL_MODULE="$2"; DKMS=1; shift 2 ;;
        --module-name) MODULE_NAME="$2"; shift 2 ;;
        --gcov-dir) GCOV_DIR="$2"; shift 2 ;;
        --build-dir) BUILD_DIR="$2"; shift 2 ;;
        --data-dir) DATA_DIR="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) echo "unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$ARCH" ] || [ -z "$BINARY" ]; then
    echo "usage: qemu-runner.sh --arch ARCH --binary PATH [--variant dev|deploy]"
    echo "       [--kernel-module PATH] [--gcov-dir PATH] [--build-dir PATH]"
    echo "       [--timeout SECS]"
    exit 1
fi

if [ ! -x "$BINARY" ]; then
    echo "error: binary not found or not executable: $BINARY"
    exit 1
fi

if [ "$DKMS" -eq 1 ] && [ -z "$MODULE_NAME" ]; then
    echo "error: --module-name is required with --kernel-module"
    exit 1
fi

VM_NAME="${VM_NAME_PREFIX}-${VARIANT}-${ARCH}"

if ! $VIRSH domstate "$VM_NAME" | grep -q running; then
    echo "error: VM not running: $VM_NAME"
    echo "start with: virsh start $VM_NAME"
    exit 1
fi

VM_IP=$($VIRSH domifaddr "$VM_NAME" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

if [ -z "$VM_IP" ]; then
    echo "error: cannot resolve IP for VM: $VM_NAME"
    exit 1
fi

REMOTE_DIR="/tmp/qemu-test-$$"

ssh $SSH_OPTS "${SSH_USER}@${VM_IP}" "mkdir -p ${REMOTE_DIR}/gcda"

scp $SSH_OPTS "$BINARY" "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/test_binary"

if [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR" ]; then
    ssh $SSH_OPTS "${SSH_USER}@${VM_IP}" "mkdir -p ${REMOTE_DIR}/tests"
    scp -r $SSH_OPTS "$DATA_DIR" "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/tests/"
fi

if [ "$DKMS" -eq 1 ] && [ -n "$KERNEL_MODULE" ]; then
    if [ ! -f "$KERNEL_MODULE" ]; then
        echo "error: kernel module not found: $KERNEL_MODULE"
        exit 1
    fi
    scp $SSH_OPTS "$KERNEL_MODULE" "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/test_module.ko"
fi

if [ -n "$BUILD_DIR" ]; then
    STRIP_DEPTH=$(echo "$BUILD_DIR" | tr -cd '/' | wc -c)
else
    STRIP_DEPTH=0
fi

REMOTE_CMD="cd ${REMOTE_DIR} && export GCOV_PREFIX=${REMOTE_DIR}/gcda && export GCOV_PREFIX_STRIP=${STRIP_DEPTH}"

if [ "$DKMS" -eq 1 ]; then
    REMOTE_CMD="${REMOTE_CMD} && insmod ${REMOTE_DIR}/test_module.ko"
fi

REMOTE_CMD="${REMOTE_CMD} && chmod +x ${REMOTE_DIR}/test_binary && ${REMOTE_DIR}/test_binary"

RC=0
ssh $SSH_OPTS -o "ServerAliveInterval=10" "${SSH_USER}@${VM_IP}" "timeout ${TIMEOUT} sh -c '${REMOTE_CMD}'" || RC=$?

if [ "$DKMS" -eq 1 ]; then
    ssh $SSH_OPTS "${SSH_USER}@${VM_IP}" "dmesg > ${REMOTE_DIR}/gcda/dmesg.log; rmmod ${MODULE_NAME}"
fi

if [ -n "$GCOV_DIR" ]; then
    ssh $SSH_OPTS "${SSH_USER}@${VM_IP}" "cd ${REMOTE_DIR}/gcda && tar cf - ." | tar xf - -C "${GCOV_DIR}/" || true

    if [ "$DKMS" -eq 1 ]; then
        scp $SSH_OPTS "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/gcda/dmesg.log" "${GCOV_DIR}/dmesg.log" || true
    fi
fi

ssh $SSH_OPTS "${SSH_USER}@${VM_IP}" "rm -rf ${REMOTE_DIR}"

exit "$RC"
