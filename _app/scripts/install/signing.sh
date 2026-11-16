#!/bin/zsh
# One stable local code-signing identity for nhetrinh-readback.app (risk R-2, P0-SIGN-1).
# An ad-hoc signature changes with every build, and macOS then drops the app's Accessibility and
# Screen Recording grants (seen 2026-11-16). A self-signed certificate keeps the app's designated
# requirement (identifier + certificate) the same, so a rebuild should keep the grants (not proven).
#
#   signing.sh            say whether the identity exists; changes nothing
#   signing.sh identity   print its SHA-1 when it can sign code, else nothing (used by readback_app.sh)
#   signing.sh create     create it in the login keychain, only if missing, after the headmate types yes
#
# The keychain is the headmate's: only `create` changes it, and only after it printed the change.
set -euo pipefail
NAME="nhetrinh local signing"
KEYCHAIN=~/Library/Keychains/login.keychain-db

# Identities that can sign code (valid and trusted), by SHA-1.
signers() {
  security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null \
    | awk -v name="\"$NAME\"" 'index($0, name) { print $2 }' || true
}

# Certificates with the name, trusted or not.
certificates() {
  security find-certificate -a -c "$NAME" -Z "$KEYCHAIN" 2>/dev/null | awk '/^SHA-1 hash:/ { print $3 }' || true
}

identity() {
  local found
  found=("${(@f)$(signers)}")
  found=(${found:#})
  if (( ${#found} > 1 )); then
    echo "more than one '$NAME' identity (${#found}); keep one, see 'signing.sh'" >&2
    exit 1
  fi
  (( ${#found} == 0 )) || print -r -- "${found[1]}"
}

status() {
  local signer cert
  signer=$(identity)
  cert=$(certificates | head -n 1)
  if [[ -n "$signer" ]]; then
    echo "present: '$NAME' ($signer) signs code; readback_app.sh uses it"
  elif [[ -n "$cert" ]]; then
    echo "present but not trusted for code signing: '$NAME' ($cert); readback_app.sh signs ad hoc"
  else
    echo "missing: '$NAME'; readback_app.sh signs ad hoc. 'signing.sh create' makes it (asks first)"
  fi
}

plan() {
  cat <<PLAN
This changes the login keychain (~/Library/Keychains/login.keychain-db):
  1. makes, in a private temporary folder, a 2048-bit RSA key and a self-signed certificate:
     common name '$NAME', valid 10 years, basic constraints CA:false,
     key usage digitalSignature, extended key usage codeSigning (/usr/bin/openssl)
  2. imports key and certificate into the login keychain; only /usr/bin/codesign may use the key
     (security import -T /usr/bin/codesign); the temporary folder is then removed
  3. trusts this certificate for code signing only, for this user (security add-trusted-cert
     -p codeSign); macOS asks for the login password
Nothing else changes. Undo: security delete-identity -c '$NAME' ~/Library/Keychains/login.keychain-db
After it, the next 'readback_app.sh' rebuilds the readback app once (the signature joins its
source hash), and the headmate grants Accessibility and Screen Recording once more.
PLAN
}

create() {
  if [[ -n "$(certificates)" ]]; then
    status
    echo "not created: '$NAME' already exists (one identity only)"
    return 0
  fi
  plan
  [[ -t 0 ]] || { echo "not created: no terminal to confirm on (the headmate must type yes)" >&2; exit 2; }
  local answer
  read -r "answer?Type yes to create it: "
  [[ "$answer" == "yes" ]] || { echo "not created"; exit 1; }

  local dir pass
  dir=$(mktemp -d -t nhetrinh-signing)
  trap "rm -rf '$dir'" EXIT
  chmod 700 "$dir"
  pass=$(/usr/bin/openssl rand -hex 16)
  cat > "$dir/req.cnf" <<CNF
[req]
distinguished_name = dn
prompt = no
x509_extensions = ext
[dn]
CN = $NAME
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
CNF
  /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$dir/req.cnf" \
    -keyout "$dir/key.pem" -out "$dir/cert.pem"
  PASS="$pass" /usr/bin/openssl pkcs12 -export -inkey "$dir/key.pem" -in "$dir/cert.pem" \
    -name "$NAME" -out "$dir/id.p12" -passout env:PASS
  security import "$dir/id.p12" -k "$KEYCHAIN" -f pkcs12 -P "$pass" -T /usr/bin/codesign
  security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$dir/cert.pem"
  status
}

case "${1:-}" in
  "") status ;;
  identity) identity ;;
  create) create ;;
  *) echo "usage: signing.sh [identity | create]" >&2; exit 2 ;;
esac
