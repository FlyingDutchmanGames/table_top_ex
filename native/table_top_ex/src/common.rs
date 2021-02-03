use rustler::{Encoder, Env, OwnedBinary, Term};
use std::io::Write;

pub struct Bin<T>(pub T);

// Basically the same impl as string, but this is specifically for Vec<u8> I want to return
// https://github.com/rusterlium/rustler/blob/1991191359dfa514155ea95ad9d40f9afdca2fe5/rustler/src/types/string.rs#L28-L41
impl<T> Encoder for Bin<T> where T: std::borrow::Borrow<[u8]> {
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        let buf: &[u8] = self.0.borrow();
        let bin_len = buf.len();
        let mut bin = match OwnedBinary::new(bin_len) {
            Some(bin) => bin,
            None => panic!("binary term allocation fail"),
        };
        bin.as_mut_slice()
            .write_all(buf)
            .expect("memory copy of string failed");
        bin.release(env).to_term(env)
    }
}
