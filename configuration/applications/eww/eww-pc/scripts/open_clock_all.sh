#!/usr/bin/env bash

set -u

mapfile -t monitors < <(hyprctl monitors | awk '/^Monitor / { print $2 }')

if [ "${#monitors[@]}" -eq 0 ]; then
  eww open clock
  exit 0
fi

eww close clock >/dev/null 2>&1 || true

for monitor in "${monitors[@]}"; do
  sanitized_monitor="${monitor//[^a-zA-Z0-9_]/_}"
  eww close "clock-${sanitized_monitor}" >/dev/null 2>&1 || true
  eww open clock --id "clock-${sanitized_monitor}" --arg "screen=${monitor}"
done
