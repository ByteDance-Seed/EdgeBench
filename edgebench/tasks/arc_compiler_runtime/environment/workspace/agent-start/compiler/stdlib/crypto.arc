# Arc Standard Library: crypto module
# Hashing, encryption, and cryptographic utilities

# --- Hashing ---

pub fn md5(text) => crypto_hash("md5", text)
pub fn sha1(text) => crypto_hash("sha1", text)
pub fn sha256(text) => crypto_hash("sha256", text)
pub fn sha512(text) => crypto_hash("sha512", text)

# --- HMAC ---

pub fn hmac_sha256(key, message) => crypto_hmac("sha256", key, message)
pub fn hmac_sha512(key, message) => crypto_hmac("sha512", key, message)

# --- Random ---

pub fn random_bytes(n) {
  if n < 0 { panic("random_bytes: n must be non-negative") }
  el { crypto_random_bytes(n) }
}

pub fn random_int(min, max) {
  if min > max { panic("random_int: min must be <= max") }
  el { crypto_random_int(min, max) }
}

pub fn uuid() => crypto_uuid()

# --- Base64 ---

pub fn base64_encode(text) => crypto_encode_base64(text)
pub fn base64_decode(text) => crypto_decode_base64(text)

# --- Password Hashing ---

pub fn hash_password(password, salt) {
  let input = salt ++ ":" ++ password
  let mut hash = sha256(input)
  for i in 0..100 {
    hash = sha256(hash ++ salt)
  }
  hash
}

pub fn verify_password(password, salt, hash) {
  let computed = hash_password(password, salt)
  computed == hash
}

# --- Utility ---

pub fn constant_time_eq(a, b) {
  if len(a) != len(b) { false }
  el {
    let mut result = true
    for i in 0..len(a) {
      if char_at(a, i) != char_at(b, i) { result = false }
    }
    result
  }
}
