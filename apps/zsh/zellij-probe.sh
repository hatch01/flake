#!/usr/bin/env bash

# 1. Fast path: check if zellij is ALREADY installed and executable
if [ -x "$HOME/.zellij/zellij" ]; then
  echo "DIR:$HOME/.zellij"
  exit 0
fi
if [ -x "/tmp/.zellij/zellij" ]; then
  echo "DIR:/tmp/.zellij"
  exit 0
fi
for base in /MIDDLE /WEBS /DATA; do
  [ -d "$base" ] || continue
  for sub in "$base"/* "$base"; do
    [ -d "$sub" ] || continue
    if [ -x "$sub/.zellij/zellij" ]; then
      echo "DIR:$sub/.zellij"
      exit 0
    fi
  done
done

# 2. Decision tree for new installation
# Test 1: $HOME (if writable and not mounted noexec)
t="$HOME/.zellij_test.$$"
if (printf '#!/bin/sh\nexit 0\n' > "$t" && chmod 755 "$t" && "$t" && rm -f "$t") 2>/dev/null; then
  mkdir -p "$HOME/.zellij" && chmod 755 "$HOME/.zellij"
  echo "DIR:$HOME/.zellij"
  exit 0
fi

# Test 2: /tmp (if writable and not mounted noexec)
t="/tmp/.zellij_test.$$"
if (printf '#!/bin/sh\nexit 0\n' > "$t" && chmod 755 "$t" && "$t" && rm -f "$t") 2>/dev/null; then
  mkdir -p "/tmp/.zellij" && (chmod 777 "/tmp/.zellij" 2>/dev/null || chmod 755 "/tmp/.zellij")
  echo "DIR:/tmp/.zellij"
  exit 0
fi

# Cleanup old failed loose files from /tmp if /tmp is noexec
rm -f /tmp/zellij /tmp/zellij-www.kdl /tmp/zellij-www-shell 2>/dev/null

# Test 3: /MIDDLE, /WEBS, /DATA
# Try directly as SSH user first
for base in /MIDDLE /WEBS /DATA; do
  [ -d "$base" ] || continue
  for sub in "$base"/* "$base"; do
    [ -d "$sub" ] || continue
    t="$sub/.zellij_test.$$"
    if (printf '#!/bin/sh\nexit 0\n' > "$t" && chmod 755 "$t" && "$t" && rm -f "$t") 2>/dev/null; then
      mkdir -p "$sub/.zellij" && (chmod 777 "$sub/.zellij" 2>/dev/null || chmod 755 "$sub/.zellij")
      echo "DIR:$sub/.zellij"
      exit 0
    fi
  done
done

# Try via sudo su - www if SSH user cannot write (for /MIDDLE, /WEBS, /DATA)
sudo su - www << 'SU_EOF' 2>/dev/null
for base in /MIDDLE /WEBS /DATA; do
  [ -d "$base" ] || continue
  for sub in "$base"/* "$base"; do
    [ -d "$sub" ] || continue
    t="$sub/.zellij_test.$$"
    if (printf '#!/bin/sh\nexit 0\n' > "$t" && chmod 755 "$t" && "$t" && rm -f "$t") 2>/dev/null; then
      mkdir -p "$sub/.zellij" && chmod 777 "$sub/.zellij"
      echo "DIR:$sub/.zellij"
      exit 0
    fi
  done
done
SU_EOF
