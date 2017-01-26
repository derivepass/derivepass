{
  "variables": {
    "gypkg_deps": [
      "git://github.com/indutny/scrypt.git@^1.0.1 => scrypt.gyp:scrypt",
    ],
  },
  "targets": [{
    "target_name": "derivepass",
    "type": "<!(gypkg type)",
    "dependencies": [
      "<!@(gypkg deps <(gypkg_deps))"
    ],
    "include_dirs": [
      ".",
      "include",
    ],
    "direct_dependent_settings": {
      "include_dirs": [
        "include"
      ],
    },
    "sources": [
      "src/derivepass.c"
    ],
  }, {
    "target_name": "derivepass-cli",
    "type": "executable",
    "dependencies": [
      "<!@(gypkg deps <(gypkg_deps))",
      "derivepass"
    ],
    "include_dirs": [
      ".",
    ],
    "sources": [
      "src/cli.c",
    ],
  }]
}
