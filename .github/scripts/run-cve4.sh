#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# run-cve4.sh — run cv32e40p-dv Verilator simulation from an ELF file
#
# The testbench reads the ELF header to extract the entry point (boot_addr)
# and loads the pre-generated <base>.hex via $readmemh internally.
# Run "make gen" before invoking this script to ensure the .hex files exist.
#
# Usage:
#   run-cve4.sh <elf-file>
#
# Environment:  
#   CVE4_DV_ROOT  — path to the cv32e40p-dv checkout (required)                                                                                             
#   CV_SW_PREFIX  — riscv toolchain prefix (default: riscv64-unknown-elf-) ok lets do step 5
set -euo pipefail

CFG=""
ELF=""

while [[ $# -gt 0 ]]; do
    case "$1" in                                                                                                                                              
        --cfg) CFG="$2"; shift 2 ;;
        --elf) ELF="$2"; shift 2 ;;                                                                                                                             
        *)                     
        echo "Unknown argument: $1" >&2                                                                                                                       
        echo "Usage: run-cve4.sh --cfg <CV_CORE_CONFIG> --elf <elf-file>" >&2
        exit 2                                                                                                                                                
        ;;                   
    esac                                                                                                                                                      
done

: "${CFG:?--cfg is required}"                                                                                                                               
: "${ELF:?--elf is required}"
: "${CVE4_DV_ROOT:?CVE4_DV_ROOT is not set}" 

CV_SW_PREFIX="${CV_SW_PREFIX:-riscv64-unknown-elf-}"

SIM="$CVE4_DV_ROOT/sim/core/simulation_results/certification_${CFG}/verilator_executable" 
[[ -x "$SIM" ]] || { echo "verilator_executable not found for cfg=$CFG at $SIM" >&2; exit 2; } 


# Generate <base>.hex if missing or older than the ELF.                                                                                                     
HEX="${ELF%.*}.hex"                                                                                                                                         
if [[ ! -f "$HEX" || "$ELF" -nt "$HEX" ]]; then                                                                                                             
    "${CV_SW_PREFIX}objcopy" -O verilog "$ELF" "$HEX"                                                                                                         
fi                                                                                                                                                          
                                                                                                                                                            
exec "$SIM" "+elf_file=$ELF"
