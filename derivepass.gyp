{
  "targets": [{
    "target_name": "derivepass",
    "type": "executable",
    "dependencies": [
      "deps/scrypt/scrypt.gyp:scrypt",
    ],
    "include_dirs": [
      ".",
    ],
    "sources": [
      "src/derivepass.c",
      "src/util.c",
    ],
  }]
}
