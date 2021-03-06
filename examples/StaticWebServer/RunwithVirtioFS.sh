#!/bin/bash
export KERNEL_HEAD=$(git rev-parse HEAD|cut -c1-7)
app="StaticWebServer"
applink="StaticWebServer.link"
appbin="StaticWebServer.bin"
compileropt="-dUseSerialasConsole"
qemuparams="-M pc -cpu host -smp 1 -m 4G,maxmem=4G -object memory-backend-file,id=mem,size=4G,mem-path=/dev/shm,share=on -numa node,memdev=mem -chardev socket,id=char0,path=/tmp/vhostqemu -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=myfstoro -nographic -device vhost-vsock-pci,guest-cid=3 -append virtiosocket,virtiofs,myfstoro"
rm -f ../../rtl/*.o ../../rtl/*.ppu ../../rtl/drivers/*.o ../../rtl/drivers/*.ppu
fpc -s -TLinux $compileropt -O2 $app.pas -Fu../../rtl/ -Fu../../rtl/drivers -MObjfpc
ld -S -nostdlib -nodefaultlibs -T $applink  -o kernel64.elf64
readelf -SW "kernel64.elf64" | python ../../builder/getsection.py 0x440000 kernel64.elf64 kernel64.section
objcopy --add-section .KERNEL64="kernel64.section" --set-section-flag .KERNEL64=alloc,data,load,contents ../../builder/multiboot.o kernel64.o
readelf -sW "kernel64.elf64" | python ../../builder/getsymbols.py "start64"  kernel64.symbols
ld -melf_i386 -T ../../builder/link_start64.ld -T kernel64.symbols kernel64.o -o $app.bin
echo "qemu.args=$qemuparams"
echo "Press Ctrl-a x to exit emulator"
~/qemu-for-virtiofs/build/x86_64-softmmu/qemu-system-x86_64 --enable-kvm -kernel $appbin $qemuparams
