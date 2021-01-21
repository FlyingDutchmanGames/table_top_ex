#![allow(dead_code)]
#![feature(array_map)]

#[macro_use]
extern crate rustler;

mod games;
use crate::games::tic_tac_toe;

use lib_table_top::games::tic_tac_toe::GameState as TicTacToeGameState;
use rustler::{Env, Term};
use std::sync::Mutex;

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

        // general
        atom win;
        atom lose;

        // tic tac toe
        atom x;
        atom o;
        atom in_progress;
        atom draw;
        atom space_is_taken;
        atom other_player_turn;
    }
}

rustler::rustler_export_nifs! {
    "Elixir.TableTopEx.NifBridge",
    [
        ("tic_tac_toe_new", 0, tic_tac_toe::new),
        ("tic_tac_toe_available", 1, tic_tac_toe::available),
        ("tic_tac_toe_whose_turn", 1, tic_tac_toe::whose_turn),
        ("tic_tac_toe_status", 1, tic_tac_toe::status),
        ("tic_tac_toe_at_position", 2, tic_tac_toe::at_position),
        ("tic_tac_toe_make_move", 3, tic_tac_toe::make_move)
    ],
    Some(load)
}

fn load(env: Env, _info: Term) -> bool {
    resource_struct_init!(TicTacToeResource, env);
    true
}
