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
      "src/cli.c",
      "src/common.c",
      "src/util.c",
    ],
  }]
}
