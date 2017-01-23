{
  "targets": [{
    "target_name": "scrypt_binding",
    "dependencies": [
      "../deps/scrypt/scrypt.gyp:scrypt",
    ],
    "include_dirs": [
      ".",
      "../",
      "<!(node -e \"require('nan')\")",
    ],
    "sources": [
      "src/scrypt.cc",

      "../src/common.c",
      "../src/util.c",
    ],
  }],
}
