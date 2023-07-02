#!/bin/bash

# exit when any command fails
set -e

OS_DIR=${OS_DIR:-'ubuntu/bionic'}
SRCDIR=${SRCDIR:-'/opt'}
DESTDIR=${DESTDIR:-'.'}

echo "OS_DIR=${OS_DIR}"
echo "SRCDIR=${SRCDIR}"
echo "DESTDIR=${DESTDIR}"

riscv() 
{
    echo "prebuilt riscv-gnu-toolchain..."
    tar -C $SRCDIR -cvjf riscv-gnu-toolchain.tar.bz2 riscv-gnu-toolchain
    split -b 50M riscv-gnu-toolchain.tar.bz2 "riscv-gnu-toolchain.tar.bz2.part"    
    mv riscv-gnu-toolchain.tar.bz2.part* $DESTDIR/riscv-gnu-toolchain/$OS_DIR
    rm riscv-gnu-toolchain.tar.bz2
}

riscv64() 
{
    echo "prebuilt riscv64-gnu-toolchain..."
    tar -C $SRCDIR -cvjf riscv64-gnu-toolchain.tar.bz2 riscv64-gnu-toolchain
    split -b 50M riscv64-gnu-toolchain.tar.bz2 "riscv64-gnu-toolchain.tar.bz2.part"    
    mv riscv64-gnu-toolchain.tar.bz2.part* $DESTDIR/riscv64-gnu-toolchain/$OS_DIR
    rm riscv64-gnu-toolchain.tar.bz2
}

llvm-vortex() 
{
    echo "prebuilt llvm-vortex..."
    tar -C $SRCDIR -cvjf llvm-vortex.tar.bz2 llvm-vortex
    split -b 50M llvm-vortex.tar.bz2 "llvm-vortex.tar.bz2.part"    
    mv llvm-vortex.tar.bz2.part* $DESTDIR/llvm-vortex/$OS_DIR
    rm llvm-vortex.tar.bz2
}

llvm-pocl() 
{
    echo "prebuilt llvm-pocl..."
    tar -C $SRCDIR -cvjf llvm-pocl.tar.bz2 llvm-pocl
    split -b 50M llvm-pocl.tar.bz2 "llvm-pocl.tar.bz2.part"    
    mv llvm-pocl.tar.bz2.part* $DESTDIR/llvm-pocl/$OS_DIR
    rm llvm-pocl.tar.bz2
}

pocl() 
{
    echo "prebuilt pocl..."
    tar -C $SRCDIR -cvjf pocl.tar.bz2 pocl
    mv pocl.tar.bz2 $DESTDIR/pocl/$OS_DIR
}

verilator() 
{
    echo "prebuilt verilator..."
    tar -C $SRCDIR -cvjf verilator.tar.bz2 verilator
    mv verilator.tar.bz2 $DESTDIR/verilator/$OS_DIR
}

show_usage()
{
    echo "Setup Pre-built Vortex Toolchain"
    echo "Usage: $0 [[--riscv] [--llvm-vortex] [--llvm-pocl] [--pocl] [--verilator] [--all] [-h|--help]]"
}

while [ "$1" != "" ]; do
    case $1 in
        --pocl ) pocl
                ;;
        --verilator ) verilator
                ;;
        --riscv ) riscv
                ;;
        --riscv64 ) riscv64
                ;;
        --llvm-vortex ) llvm-vortex
                ;;
        --llvm-pocl ) llvm-pocl
                ;;
        --all ) riscv
                riscv64
                llvm-vortex
                llvm-pocl
                pocl
                verilator
                ;;
        -h | --help ) show_usage
                exit
                ;;
        * ) show_usage
                exit 1
    esac
    shift
done
