#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "node.h"
#include "node_buffer.h"
#include "v8.h"
#include "nan.h"
#include "errno.h"

#include "scrypt.h"
#include "../src/common.h"

namespace node {
namespace scrypt_binding {

using namespace v8;

NAN_METHOD(Scrypt) {
  Nan::HandleScope scope;

  const char* passphrase = Buffer::Data(info[0]);
  size_t passphrase_len = Buffer::Length(info[0]);
  const char* salt = Buffer::Data(info[1]);
  size_t salt_len = Buffer::Length(info[1]);
  int out_len = info[2]->Uint32Value();

  scrypt_state_t state;

  state.n = kDeriveScryptN;
  state.r = kDeriveScryptR;
  state.p = kDeriveScryptP;

  int err = scrypt_state_init(&state);
  assert(err == 0);

  char* out = new char[out_len];

  scrypt(&state,
         reinterpret_cast<const uint8_t*>(passphrase),
         passphrase_len,
         reinterpret_cast<const uint8_t*>(salt),
         salt_len,
         reinterpret_cast<uint8_t*>(out),
         out_len);
  scrypt_state_destroy(&state);

  info.GetReturnValue().Set(Nan::NewBuffer(out, out_len).ToLocalChecked());
}


NAN_METHOD(DerivePass) {
  Nan::HandleScope scope;

  Nan::Utf8String secret(info[0]);
  Nan::Utf8String domain(info[1]);

  scrypt_state_t state;

  state.n = kDeriveScryptN;
  state.r = kDeriveScryptR;
  state.p = kDeriveScryptP;

  char* out = derive(&state, *secret, *domain);
  assert(out != nullptr);

  info.GetReturnValue().Set(Nan::CopyBuffer(out, strlen(out)).ToLocalChecked());
  free(out);
}


static void Init(Handle<Object> target) {
  Nan::SetMethod(target, "scrypt", Scrypt);
  Nan::SetMethod(target, "derivepass", DerivePass);
}


}  // namespace scrypt_binding
}  // namespace node

NODE_MODULE(mmap, node::scrypt_binding::Init);
