#!/bin/sh

#set -euo pipefail

if [ "$#" -ne 1 ]; then
    >&2 echo "Usage: $0 path-to-pcap-folder"
    exit 1
fi

PCAP_DIR="$1"
for file in `find "${PCAP_DIR}" -name "*.pcap" -type f`; do
    echo "Processing ${file}"
    # https://tshark.dev/share/pcap_preparation/
    # Edit the file to remove error "appears to have been cut short in the middle of a packet."
    #editcap "${file}" "${file}"

    # Extract SNIs
    tshark -r "${file}" -Y 'ssl.handshake.extensions_server_name and not udp' -Tfields -e ssl.handshake.extensions_server_name > "${file%.pcap}.sni"
    # Extract http.host
    tshark -r "${file}" -Y 'http' -Tfields -e http.host > "${file%.pcap}.http_host"
done


extract () {
  local ext="$1"
  results=$(cat "${PCAP_DIR}"*"${ext}" | sort -n | uniq)
  rm "${PCAP_DIR}"*"${ext}" 
  echo "$results" | sed '/^$/d' > "${PCAP_DIR}"results"${ext}"
}

extract ".sni"
extract ".http_host"

