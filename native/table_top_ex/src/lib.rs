#![allow(dead_code)]

#[macro_use]
extern crate rustler;

mod games;
use crate::games::tic_tac_toe;

use std::sync::Mutex;
use rustler::{Encoder, Env, Error, Term};
use lib_table_top::games::tic_tac_toe::GameState as TicTacToeGameState;

pub struct TicTacToeResource(Mutex<TicTacToeGameState>);

mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;
        atom nil;
        atom __true__ = "true";
        atom __false__ = "false";

        // Resource Atoms
        atom bad_reference;
        atom lock_fail;

        // tic tac toe
        atom x;
        atom o;
    }
}

rustler::rustler_export_nifs! {
    "Elixir.TableTopEx.NifBridge",
    [
        ("add", 2, add),
        ("tic_tac_toe_new", 0, tic_tac_toe::new),
        ("tic_tac_toe_available", 1, tic_tac_toe::available),
        ("tic_tac_toe_whose_turn", 1, tic_tac_toe::whose_turn)
    ],
    Some(load)
}

fn load(env: Env, _info: Term) -> bool {
    resource_struct_init!(TicTacToeResource, env);
    true
}

fn add<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let num1: i64 = args[0].decode()?;
    let num2: i64 = args[1].decode()?;

    Ok((atoms::ok(), num1 + num2).encode(env))
}
