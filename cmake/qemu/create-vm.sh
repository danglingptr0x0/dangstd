#!/bin/sh
set -eu

VARIANT="${1:-}"
SSH_PUBKEY_FILE="${2:-${HOME}/.ssh/id_qemu_test.pub}"
DISK_SIZE="20G"
RAM="4096"
VCPUS="4"
VM_DIR="${HOME}/.local/share/libvirt/images"

if [ -z "$VARIANT" ]; then
    echo "usage: create-vm.sh <dev|deploy> [ssh-pubkey-file]"
    exit 1
fi

if [ ! -f "$SSH_PUBKEY_FILE" ]; then
    echo "error: SSH public key not found: $SSH_PUBKEY_FILE"
    exit 1
fi

SSH_PUBKEY=$(cat "$SSH_PUBKEY_FILE")

case "$VARIANT" in
    dev)
        VM_NAME="qemu-test-dev-x86_64"
        CLOUD_IMG=$(ls ~/Downloads/debian-13-cloud*.qcow2 2>/dev/null | head -1)
        OS_VARIANT="debiantesting"
        ;;
    deploy)
        VM_NAME="qemu-test-deploy-x86_64"
        CLOUD_IMG=$(ls ~/Downloads/debian-12-cloud*.qcow2 2>/dev/null | head -1)
        OS_VARIANT="debian12"
        ;;
    arch)
        VM_NAME="qemu-test-arch-x86_64"
        CLOUD_IMG=$(ls ~/Downloads/arch-cloud*.qcow2 2>/dev/null | head -1)
        OS_VARIANT="archlinux"
        ;;
    *)
        echo "error: unknown variant: $VARIANT"
        exit 1
        ;;
esac

if [ -z "$CLOUD_IMG" ]; then
    echo "error: cloud image not found in ~/Downloads/"
    exit 1
fi

mkdir -p "$VM_DIR"

DISK="${VM_DIR}/${VM_NAME}.qcow2"
SEED="${VM_DIR}/${VM_NAME}-seed.iso"

echo "creating disk from cloud image..."
cp "$CLOUD_IMG" "$DISK"
qemu-img resize "$DISK" "$DISK_SIZE"

echo "creating cloud-init seed..."
WORK_DIR=$(mktemp -d)

cat > "${WORK_DIR}/meta-data" <<EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF

cat > "${WORK_DIR}/user-data" <<EOF
#cloud-config
hostname: ${VM_NAME}
manage_etc_hosts: true
ssh_authorized_keys:
  - ${SSH_PUBKEY}
disable_root: false
ssh_pwauth: false
chpasswd:
  expire: false
packages:
  - build-essential
  - openssh-server
runcmd:
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  - systemctl restart sshd
EOF

genisoimage -output "$SEED" -volid cidata -joliet -rock "${WORK_DIR}/user-data" "${WORK_DIR}/meta-data" 2>/dev/null || \
    mkisofs -output "$SEED" -volid cidata -joliet -rock "${WORK_DIR}/user-data" "${WORK_DIR}/meta-data"

rm -rf "$WORK_DIR"

echo "creating VM: $VM_NAME"
virt-install \
    --connect qemu:///system \
    --name "$VM_NAME" \
    --memory "$RAM" \
    --vcpus "$VCPUS" \
    --disk "path=${DISK},format=qcow2" \
    --disk "path=${SEED},device=cdrom" \
    --os-variant "$OS_VARIANT" \
    --network default \
    --noautoconsole \
    --import

echo "waiting for cloud-init to finish..."
sleep 30

echo "VM ready: $VM_NAME"
