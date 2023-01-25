#!/usr/bin/env bash

FINGERPRINT_KEY1="1537 3514 494A 5273 3FAA  F7C9 8FDE AEDC 3B8C 0109"
FINGERPRINT_KEY2="E1B1 7BEA 095F 5B25 4135  F6D1 F820 25E7 800B 3CCF"

import_keys()
{
    gpg --import key-one.priv.asc
    gpg --import key-two.priv.asc
}

setup_key1()
{
    git config user.name "Key One"
    git config user.email "test1@example.com"
    git config user.signingkey "${FINGERPRINT_KEY1}"
}

setup_key2()
{
    git config user.name "Key Two"
    git config user.email "test2@example.com"
    git config user.signingkey "${FINGERPRINT_KEY2}"
}

authorize_key1()
{
    setup_key1
    git add .guix-authorizations
    git commit -s -m "Authorize Key One."
}

authorize_key2()
{
    setup_key1
    git add .guix-authorizations
    git commit -s -m "Authorize Key Two."
}

key2_commit()
{
    setup_key2
    git add dummy
    git commit -s -m "Test."
}

#
INITIAL_COMMIT="$(git rev-parse HEAD)"

import_keys

cat <<EOF >.guix-authorizations
(authorizations
 (version 0)
 (("${FINGERPRINT_KEY1}"
   (name "Key One"))))
EOF
authorize_key1

INTRODUCTION_COMMIT="$(git rev-parse HEAD)"

cat <<EOF >.guix-authorizations
(authorizations
 (version 0)
 (("${FINGERPRINT_KEY1}"
   (name "Key One")))
 (("${FINGERPRINT_KEY2}"
   (name "Key Two"))))
EOF
authorize_key2

cat <<EOF >dummy
test
EOF
key2_commit

guix git authenticate "${INTRODUCTION_COMMIT}" "${FINGERPRINT_KEY1}"

#
git reset --hard "${INTRODUCTION_COMMIT}"

cat <<EOF >.guix-authorizations
(authorizations
 (version 0)
 (("${FINGERPRINT_KEY2}"
   (name "Key Two")))
 (("${FINGERPRINT_KEY1}"
   (name "Key One"))))
EOF
authorize_key2

cat <<EOF >dummy
test
EOF
key2_commit

guix git authenticate "${INTRODUCTION_COMMIT}" "${FINGERPRINT_KEY1}"

git reset --hard "${INITIAL_COMMIT}"
