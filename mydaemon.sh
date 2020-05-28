#!/bin/bash

if [[ ! "$FILE" ]]; then
    echo "Enter the file name" >&2
    exit 1
fi

if [[ ! "$KEY_WORD" ]]; then
    echo "Enter a search term" >&2
fi

echo "Searching ${KEY_WORD} in ${FILE}"

grep "$KEY_WORD" "$FILE"
