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
        atom position_outside_of_board;
    }
}

rustler::rustler_export_nifs! {
    "Elixir.TableTopEx.NifBridge",
    [
        ("tic_tac_toe_available", 1, tic_tac_toe::available),
        ("tic_tac_toe_board", 1, tic_tac_toe::board),
        ("tic_tac_toe_make_move", 3, tic_tac_toe::make_move),
        ("tic_tac_toe_new", 0, tic_tac_toe::new),
        ("tic_tac_toe_status", 1, tic_tac_toe::status),
        ("tic_tac_toe_whose_turn", 1, tic_tac_toe::whose_turn),
        ("tic_tac_toe_history", 1, tic_tac_toe::history),
        ("tic_tac_toe_clone", 1, tic_tac_toe::clone),
        ("tic_tac_toe_undo", 1, tic_tac_toe::undo),
        ("tic_tac_toe_to_json", 1, tic_tac_toe::to_json),
        ("tic_tac_toe_from_json", 1, tic_tac_toe::from_json),
        ("tic_tac_toe_to_bincode", 1, tic_tac_toe::to_bincode),
        ("tic_tac_toe_from_bincode", 1, tic_tac_toe::from_bincode),
    ],
    Some(load)
}

fn load(env: Env, _info: Term) -> bool {
    resource_struct_init!(TicTacToeResource, env);
    true
}
