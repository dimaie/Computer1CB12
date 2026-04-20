import serial
import sys
import os
import struct
import time

# Configuration
COM_PORT = 'COM7'      # Change this to your actual serial port!
BAUD_RATE = 115200
ACK = b'\x06'
NAK = b'\x15'

def load_hex_file(filename):
    min_addr = 0xFFFF
    max_addr = 0x0000
    data_dict = {}

    current_addr = 0

    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            if line.startswith(':'):
                byte_count = int(line[1:3], 16)
                address = int(line[3:7], 16)
                record_type = int(line[7:9], 16)
                
                if record_type == 0x00: # Data record
                    for i in range(byte_count):
                        data_byte = int(line[9 + i*2 : 11 + i*2], 16)
                        addr = address + i
                        data_dict[addr] = data_byte
                        if addr < min_addr: min_addr = addr
                        if addr > max_addr: max_addr = addr
                continue

            # Handle custom/Verilog HEX format (strip comments)
            line = line.split('//')[0].split(';')[0].strip()
            if not line:
                continue
                
            for token in line.split():
                if token.startswith('@'):
                    current_addr = int(token[1:], 16)
                else:
                    try:
                        data_dict[current_addr] = int(token, 16)
                        if current_addr < min_addr: min_addr = current_addr
                        if current_addr > max_addr: max_addr = current_addr
                        current_addr += 1
                    except ValueError:
                        pass
                
    if not data_dict:
        return None, None
        
    # Create a flat bytearray from the min address to the max address
    length = (max_addr - min_addr) + 1
    payload = bytearray(length) # Defaults to 0x00 (NOP)
    
    for addr, val in data_dict.items():
        payload[addr - min_addr] = val
        
    return min_addr, payload

def send_payload(filename, manual_address=None):
    if not os.path.exists(filename):
        print(f"Error: File '{filename}' not found.")
        return

    if filename.lower().endswith('.hex'):
        address, payload = load_hex_file(filename)
        if payload is None:
            print("Error: No valid data found in HEX file.")
            return
    else:
        if manual_address is None:
            print("Error: A hex address must be provided for raw .bin files.")
            return
        address = int(manual_address, 16)
        with open(filename, 'rb') as f:
            payload = f.read()

    length = len(payload)
    if length == 0 or length > 65535:
        print("Error: Payload must be between 1 and 65535 bytes.")
        return

    # Pack header as Little-Endian unsigned shorts (<H)
    header = struct.pack('<HH', address, length)
    checksum = (sum(header) + sum(payload)) % 256

    print("==================================================")
    print(f" SAP-3 Smart Payload Transmitter")
    print("==================================================")
    print(f" File:     {filename}")
    print(f" Address:  0x{address:04X} (Auto-detected)" if filename.lower().endswith('.hex') else f" Address:  0x{address:04X}")
    print(f" Size:     {length} bytes (0x{length:04X})")
    print(f" Checksum: 0x{checksum:02X}")
    print("==================================================")
    print(f"\n1. Please type 'R' (and press Enter) on the SAP-3 Monitor.")
    print(f"2. Waiting for SAP-3 ACK signal on {COM_PORT}...")

    try:
        # Added STOPBITS_TWO to force a hardware-level idle gap between bytes
        with serial.Serial(COM_PORT, BAUD_RATE, stopbits=serial.STOPBITS_TWO, timeout=None) as ser:
            while True:
                if ser.read(1) == ACK:
                    break

            print("\n[+] SAP-3 is ready! Transmitting Header + Payload...")
            
            full_data = header + payload + bytes([checksum])
            ser.write(full_data)
            
            print("[+] Data sent. Waiting for verification...")
            resp = ser.read(1)
            if resp == ACK:
                print("\n[SUCCESS] Transfer complete and checksum verified!")
            elif resp == NAK:
                print("\n[FAILED] SAP-3 reported a checksum mismatch.")
            else:
                print(f"\n[WARNING] Unknown response received: {resp}")
                
    except serial.SerialException as e:
        print(f"\n[ERROR] Could not connect to {COM_PORT}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python sap3_send.py <file.hex | file.bin> [hex_address_for_bin]")
    else:
        send_payload(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)