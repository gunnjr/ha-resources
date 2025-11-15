#!/usr/bin/env python3
"""
HA Zigbee Log Formatter - Streaming log formatter for Home Assistant Zigbee logs.
Reads from STDIN, filters Zigbee-related lines, optionally filters by device,
and outputs compact one-line summaries.

Usage:
    ha core logs -f | ./ha_zigbee_logfmt.py
    cat saved.log | ./ha_zigbee_logfmt.py

Configuration (environment variables):
    DEVICE_NWK    - Zigbee short address (e.g., "0x92A7")
    DEVICE_IEEE   - Zigbee IEEE/EUI-64 (e.g., "0x00124B0012345678")
    MODULE_FILTER - Pipe-separated module names (default: "zigpy|zha|bellows|zigpy_znp|zigpy_deconz")
"""

import sys
import re
import os

# Configuration from environment
DEVICE_NWK = os.environ.get("DEVICE_NWK", "").strip()
DEVICE_IEEE = os.environ.get("DEVICE_IEEE", "").strip()
MODULE_FILTER = os.environ.get("MODULE_FILTER", "zigpy|zha|bellows|zigpy_znp|zigpy_deconz")

# Compile module filter patterns
MODULE_PATTERNS = [p.strip() for p in MODULE_FILTER.split("|") if p.strip()]

# Cluster ID to name mapping
CLUSTER_NAMES = {
    0x0006: "OnOff",
    0x0008: "LevelControl",
    0xEF00: "TuyaEF00",
    61184: "TuyaEF00",
    0x0B04: "ElectricalMeas",
    2820: "ElectricalMeas",
    0x0400: "Illuminance",
    1024: "Illuminance",
}


def matches_module_filter(line):
    """Check if line contains any of the module filter patterns."""
    return any(pattern in line for pattern in MODULE_PATTERNS)


def matches_device_filter(line):
    """Check if line references the configured device (NWK or IEEE)."""
    if not DEVICE_NWK and not DEVICE_IEEE:
        # No device filter configured - accept all
        return True

    if DEVICE_NWK:
        patterns = [
            f"SrcAddr={DEVICE_NWK}",
            f"MacSrcAddr={DEVICE_NWK}",
            f"[{DEVICE_NWK}:",
            f"address={DEVICE_NWK}",
        ]
        if any(p in line for p in patterns):
            return True

    if DEVICE_IEEE and DEVICE_IEEE in line:
        return True

    return False


def parse_log_prefix(line):
    """Extract timestamp, level, logger, and message from HA log line."""
    parts = line.split(None, 4)  # Split on whitespace, max 5 parts
    if len(parts) < 5:
        return None, None, None, line

    timestamp = f"{parts[0]} {parts[1]}"
    level = parts[2]

    # Extract logger from [logger] format
    rest = parts[4]
    logger_match = re.search(r'\[([^\]]+)\]', rest)
    if logger_match:
        logger = logger_match.group(1)
        # Message is everything after the first '] '
        msg_start = rest.find('] ')
        message = rest[msg_start + 2:] if msg_start >= 0 else rest
    else:
        logger = ""
        message = rest

    return timestamp, level, logger, message


def extract_field(pattern, line, default=-1):
    """Extract a numeric field value using regex."""
    match = re.search(pattern, line)
    return int(match.group(1)) if match else default


def extract_data_bytes(line):
    """Parse Data=b'...' field and return list of byte values."""
    match = re.search(r"Data=b'([^']*)'", line)
    if not match:
        return []

    data_str = match.group(1)
    bytes_list = []

    # Parse \xHH sequences
    i = 0
    while i < len(data_str):
        if i + 3 < len(data_str) and data_str[i:i+2] == '\\x':
            try:
                hex_str = data_str[i+2:i+4]
                bytes_list.append(int(hex_str, 16))
                i += 4
                continue
            except ValueError:
                pass
        i += 1

    return bytes_list


def cluster_name(cid):
    """Get friendly cluster name or return hex format."""
    if cid in CLUSTER_NAMES:
        return f"0x{cid:04X} ({CLUSTER_NAMES[cid]})"
    elif cid >= 0:
        return f"0x{cid:04X}"
    else:
        return "0x????"


def format_af_incoming(line, timestamp):
    """Format AF.IncomingMsg.Callback line."""
    # Extract fields
    cid = extract_field(r'ClusterId=(\d+)', line)
    src_ep = extract_field(r'SrcEndpoint=(\d+)', line, 0)
    dst_ep = extract_field(r'DstEndpoint=(\d+)', line, 0)
    lqi = extract_field(r'LQI=(\d+)', line)

    # Extract NWK address for display
    src_addr = re.search(r'SrcAddr=(0x[0-9A-Fa-f]+)', line)
    dev_id = src_addr.group(1) if src_addr else (DEVICE_NWK or DEVICE_IEEE or "device")

    # Parse data bytes
    data_bytes = extract_data_bytes(line)

    if len(data_bytes) >= 3:
        fc = data_bytes[0]
        tsn = data_bytes[1]
        cmd = data_bytes[2]

        # Format data as space-separated hex
        data_hex = " ".join(f"{b:02X}" for b in data_bytes)

        return (f"[{timestamp}] {dev_id} EP={src_ep} {cluster_name(cid)} LQI={lqi} | "
                f"AF.IncomingMsg | FC=0x{fc:02X} TSN={tsn} CMD=0x{cmd:02X} | DATA: {data_hex}")
    else:
        return f"[{timestamp}] {dev_id} EP={src_ep} {cluster_name(cid)} LQI={lqi} | (no ZCL bytes)"


def format_af_tx(line, timestamp):
    """Format AF.DataRequestExt.Req line."""
    # Extract fields
    addr_match = re.search(r'address=(0x[0-9A-Fa-f]+)', line)
    address = addr_match.group(1) if addr_match else (DEVICE_NWK or DEVICE_IEEE or "????")

    dst_ep = extract_field(r'DstEndpoint=(\d+)', line, 0)
    cid = extract_field(r'ClusterId=(\d+)', line)
    tsn = extract_field(r'TSN=(\d+)', line, 0)

    # Parse data bytes (truncate for display)
    data_bytes = extract_data_bytes(line)
    data_hex = " ".join(f"{b:02X}" for b in data_bytes[:15])  # First 15 bytes
    if len(data_bytes) > 15:
        data_hex += "..."

    return (f"[{timestamp}] TX -> {address} EP={dst_ep} {cluster_name(cid)} | "
            f"AF.DataRequestExt | TSN={tsn} | DATA: {data_hex}")


def format_passthrough(line, timestamp, level, logger, message):
    """Format generic Zigbee line as truncated passthrough."""
    # Truncate message to ~200 chars
    if len(message) > 200:
        message = message[:200] + "..."

    return f"[{timestamp}] {level} {logger} | {message}"


def process_line(line):
    """Process a single log line and return formatted output or None."""
    line = line.rstrip('\n')

    # Module filter
    if not matches_module_filter(line):
        return None

    # Device filter
    if not matches_device_filter(line):
        return None

    # Parse log prefix
    timestamp, level, logger, message = parse_log_prefix(line)
    if not timestamp:
        return None

    # Handle known message types
    if "AF.IncomingMsg.Callback" in line:
        return format_af_incoming(line, timestamp)

    elif "AF.DataRequestExt.Req" in line:
        return format_af_tx(line, timestamp)

    elif "[zigpy.zcl]" in line or "homeassistant.components.zha" in line:
        return format_passthrough(line, timestamp, level, logger, message)

    else:
        # Generic Zigbee line
        return format_passthrough(line, timestamp, level, logger, message)


def main():
    """Main streaming loop."""
    try:
        for line in sys.stdin:
            output = process_line(line)
            if output:
                print(output, flush=True)
    except KeyboardInterrupt:
        pass
    except BrokenPipeError:
        # Handle pipe closing gracefully
        sys.stderr.close()


if __name__ == "__main__":
    main()
