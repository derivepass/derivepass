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

struct Request {
  enum RequestType {
    kRequestScrypt,
    kRequestDerivePass
  };

  uv_work_t req;

  RequestType type;
  char* passphrase;
  size_t passphrase_len;
  char* salt;
  size_t salt_len;

  char* out;
  size_t out_len;

  Nan::Callback cb;
};


static void Compute(uv_work_t* work) {
  Request* req = reinterpret_cast<Request*>(work->data);

  scrypt_state_t state;

  state.n = kDeriveScryptN;
  state.r = kDeriveScryptR;
  state.p = kDeriveScryptP;

  if (req->type == Request::kRequestScrypt) {
    int err = scrypt_state_init(&state);
    assert(err == 0);

    req->out = new char[req->out_len];

    scrypt(&state,
           reinterpret_cast<const uint8_t*>(req->passphrase),
           req->passphrase_len,
           reinterpret_cast<const uint8_t*>(req->salt),
           req->salt_len,
           reinterpret_cast<uint8_t*>(req->out),
           req->out_len);
    scrypt_state_destroy(&state);

    return;
  }

  req->out = derive(&state, req->passphrase, req->salt);
  assert(req->out != nullptr);
}


static void AfterCompute(uv_work_t* work, int status) {
  Nan::HandleScope scope;
  Request* req = reinterpret_cast<Request*>(work->data);

  if (req->type == Request::kRequestScrypt) {
    Local<Value> argv[] = {
      Nan::NewBuffer(req->out, req->out_len).ToLocalChecked()
    };
    req->cb(1, argv);
    return;
  }

  Local<Value> argv[] = { Nan::New<String>(req->out).ToLocalChecked() };
  free(req->out);
  req->out = nullptr;
  req->cb(1, argv);
}


NAN_METHOD(Scrypt) {
  Nan::HandleScope scope;

  Request* req = new Request();
  memset(req, 0, sizeof(*req));

  req->type = Request::kRequestScrypt;

  req->passphrase_len = Buffer::Length(info[0]);
  req->passphrase = new char[req->passphrase_len];
  memcpy(req->passphrase, Buffer::Data(info[0]), req->passphrase_len);

  req->salt_len = Buffer::Length(info[1]);
  req->salt = new char[req->salt_len];
  memcpy(req->salt, Buffer::Data(info[1]), req->salt_len);

  req->out_len = info[2]->Uint32Value();

  req->cb.Reset(info[3].As<Function>());

  req->req.data = req;

  int err = uv_queue_work(uv_default_loop(),
                          &req->req,
                          Compute,
                          AfterCompute);
  assert(err == 0);
}


NAN_METHOD(DerivePass) {
  Nan::HandleScope scope;

  Nan::Utf8String secret(info[0]);
  Nan::Utf8String domain(info[1]);

  Request* req = new Request();
  memset(req, 0, sizeof(*req));

  req->type = Request::kRequestDerivePass;

  req->passphrase_len = secret.length() + 1;
  req->passphrase = new char[req->passphrase_len];
  memcpy(req->passphrase, *secret, req->passphrase_len);

  req->salt_len = domain.length() + 1;
  req->salt = new char[req->salt_len];
  memcpy(req->salt, *domain, req->salt_len);

  req->cb.Reset(info[2].As<Function>());

  req->req.data = req;

  int err = uv_queue_work(uv_default_loop(),
                          &req->req,
                          Compute,
                          AfterCompute);
  assert(err == 0);
}


static void Init(Handle<Object> target) {
  Nan::SetMethod(target, "scrypt", Scrypt);
  Nan::SetMethod(target, "derivepass", DerivePass);
}


}  // namespace scrypt_binding
}  // namespace node

NODE_MODULE(mmap, node::scrypt_binding::Init);
