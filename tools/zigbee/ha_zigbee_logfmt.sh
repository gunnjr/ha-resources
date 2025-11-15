#!/usr/bin/env bash
# ha_zigbee_logfmt.sh
# Read Home Assistant log lines from stdin, filter Zigbee ZNP/ZHA lines, and print
# a compact, human-readable summary focused on AF.IncomingMsg (closest to device).
#
# Usage examples:
#   tail -f /config/home-assistant.log | bash ha_zigbee_logfmt.sh
#   grep 'AF.IncomingMsg.Callback' /config/home-assistant.log | ./ha_zigbee_logfmt.sh
#
# Compatible with macOS Bash 3.2 and BusyBox ash; awk required.

awk -v IGNORECASE=1 '
function hex(n,  fmt){fmt = (n < 0x10000 ? "0x%04X" : "0x%X"); return sprintf(fmt, n)}
function h2(n,   s){return sprintf("0x%02X", n)}
function cluster_name(cid,  h){
  h = sprintf("0x%04X", cid)
  if (h=="0x0006") return h " (OnOff)"
  if (h=="0x0008") return h " (LevelControl)"
  if (h=="0xEF00" || cid==61184) return "0xEF00 (TuyaEF00)"
  if (h=="0x0B04" || cid==2820) return "0x0B04 (ElectricalMeas)"
  if (h=="0x0400" || cid==1024) return "0x0400 (Illuminance)"
  return h
}
function dirbit(b){ return (b==1) ? "right" : (b==0 ? "left" : ("dir?" b)) }
function parse_data(d, arr,   n,i,hexbyte){
  # Input like: \x11\x25\xFC\x01  (no quotes)
  n=split(d, arr_raw, "\\\\x"); # first token may be ""
  i=0
  for (k=1;k<=n;k++){
    if (length(arr_raw[k])==0) continue
    hexbyte = substr(arr_raw[k],1,2)
    if (hexbyte ~ /^[0-9A-Fa-f]{2}$/){
      i++
      arr[i] = strtonum("0x" hexbyte)
      # append any residual? ignore
    }
  }
  return i
}
function zcl_fc_flags(fc,  ft,ms,dir,ddr){
  ft = (fc & 0x03); ms = (fc & 0x04) ? 1:0; dir = (fc & 0x08) ? 1:0; ddr = (fc & 0x10) ? 1:0
  return sprintf("ft=%s ms=%d dir=%s ddr=%d", (ft==0?"prof":(ft==1?"cluster":"other")), ms, (dir?"srv→cli":"cli→srv"), ddr)
}
function decode_level(cmd, payload, np,   sm,ss,tt,mm,rate){
  if ((cmd==0x03 || cmd==0x06) && np>=3){ # step / step_with_on_off
    sm = payload[1]; ss = payload[2]; tt = payload[3];
    return sprintf("Level: %s step_size=%d tt_ds=%d",
      (sm==1?"DOWN":"UP"), ss, tt)
  }
  if ((cmd==0x02 || cmd==0x05) && np>=2){ # move / move_with_on_off
    mm = payload[1]; rate = payload[2];
    return sprintf("Level: %s rate=%d/s", (mm==1?"DOWN":"UP"), rate)
  }
  return ""
}
function decode_onoff_vendor(cmd, payload, np,   p){
  # vendor cmds seen: 0xFC/0xFD with 1-byte direction; tiny 0x01..0x04
  if ((cmd==0xFC || cmd==0xFD) && np>=1){
    return sprintf("VendorRotate cmd=%s dir=%s", h2(cmd), dirbit(payload[1]))
  }
  if (cmd>=1 && cmd<=4){
    return sprintf("VendorMini cmd=%s", h2(cmd))
  }
  return ""
}
function decode_report_attrs(payload, np,   aid_lo,aid_hi,aid,type,val_lo,val_hi){
  if (np>=4){
    aid_lo = payload[1]; aid_hi = payload[2]; type = payload[3];
    aid = aid_lo + 256*aid_hi
    # Try short values
    if (type==0x10 && np>=5){ # bool
      return sprintf("Report attr=0x%04X bool=%d", aid, payload[4])
    } else if (type==0x20 && np>=5){ # u8
      return sprintf("Report attr=0x%04X u8=%d", aid, payload[4])
    } else if (type==0x21 && np>=6){ # u16
      val_lo = payload[4]; val_hi = payload[5];
      return sprintf("Report attr=0x%04X u16=%d", aid, val_lo + 256*val_hi)
    } else if (type==0x29 && np>=6){ # s16
      val_lo = payload[4]; val_hi = payload[5];
      v = val_lo + 256*val_hi; if (v>=32768) v-=65536;
      return sprintf("Report attr=0x%04X s16=%d", aid, v)
    }
    return sprintf("Report attr=0x%04X type=0x%02X ...", aid, type)
  }
  return "Report attrs ..."
}

# Process lines
/AF\.IncomingMsg\.Callback/ {
  # Extract fields
  ts   = $1 " " $2
  gsub(/DEBUG|INFO|WARNING|ERROR/,"", ts)
  # ClusterId
  if (match($0, /ClusterId=([0-9]+)/, m)) { cid = m[1]+0 } else { cid=-1 }
  # SrcAddr
  if (match($0, /SrcAddr=0x([0-9A-Fa-f]+)/, m)) { src = "0x" m[1] } else { src="?" }
  # SrcEndpoint
  if (match($0, /SrcEndpoint=([0-9]+)/, m)) { ep = m[1]+0 } else { ep=0 }
  # LQI
  if (match($0, /LQI=([0-9]+)/, m)) { lqi = m[1]+0 } else { lqi=-1 }
  # Data blob
  data = ""
  if (match($0, /Data=b'\([^']+\)'/, m)) {
    data = m[1]
  }
  # Convert data to byte array
  delete payload
  nbytes = parse_data(data, payload)
  out = ""
  if (nbytes>=3){
    fc = payload[1]; tsn = payload[2]; cmd = payload[3]
    fcflags = zcl_fc_flags(fc)
    # human decoder
    human = ""
    # Profile-wide reports/reads
    if ((fc & 0x03) == 0x00){ # profile-wide
      if (cmd==0x0A){ human = decode_report_attrs(payload, nbytes) }
      else if (cmd==0x01){ human = "ReadAttrResponse ..." }
      else if (cmd==0x0B){ human = "DefaultResponse" }
    } else if ((fc & 0x03) == 0x01){ # cluster-specific
      if (cid==0x0008){ human = decode_level(cmd, payload, nbytes) }
      else if (cid==0x0006){ human = decode_onoff_vendor(cmd, payload, nbytes) }
    }
    # Build output
    printf("[%s] %s EP=%d %s LQI=%d | FC=%s TSN=%d CMD=%s | ",
           ts, src, ep, cluster_name(cid), lqi, fcflags, tsn, h2(cmd))
    if (length(human)>0) printf("%s | ", human)
    # Raw payload
    printf("DATA:")
    for (i=1;i<=nbytes;i++) printf(" %s", h2(payload[i]))
    printf("\n")
  } else {
    # Not enough bytes, just print header
    printf("[%s] %s EP=%d %s LQI=%d | (no ZCL bytes)\n",
           ts, src, ep, cluster_name(cid), lqi)
  }
  next
}

# Also surface zigpy.zcl direction-only summaries if present
/\[zigpy\.zcl\]/ {
  print $0
  next
}

# Ignore everything else by default
{ next }
'