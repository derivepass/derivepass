# DerivePass

Simple key derivation utility.

## Usage

```
$ ./out/Release/derivepass-cli -h
Usage: ./out/Release/derivepass-cli [options]

options:
  --version, -v              Print version
  --domain host, -d host     Use domain for KDF (required)
  -n <num>                   N number for scrypt (default: 1024)
  -r <num>                   R number for scrypt (default: 8)
  -p <num>                   P number for scrypt (default: 4)

$ derivepass --domain gmail.com/username
Secret:
0UYUAM2j8xFBlkEZZrxF2Vs.
```

## Building

```bash
npm i
ls ./out/Release/derivepass-cli
```

#### LICENSE

This software is licensed under the MIT License.

Copyright Fedor Indutny, 2017.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
