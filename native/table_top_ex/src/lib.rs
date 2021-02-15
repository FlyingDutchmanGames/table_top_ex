#![allow(dead_code)]
#![feature(array_map)]
#![allow(non_snake_case)]

#[macro_use]
extern crate rustler;
use rustler::{Env, Term};

mod games;
use crate::games::{marooned, tic_tac_toe};

use lib_table_top::games::marooned::GameState as MaroonedGameState;
use lib_table_top::games::tic_tac_toe::GameState as TicTacToeGameState;

struct MaroonedResource(MaroonedGameState);
struct TicTacToeResource(TicTacToeGameState);

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
        atom other_player_turn;
        atom P1;
        atom P2;
        atom P3;
        atom P4;
        atom P5;
        atom P6;
        atom P7;
        atom P8;

        // TicTacToe
        atom in_progress;
        atom draw;
        atom space_is_taken;
        atom position_outside_of_board;

        // Marooned
        atom cant_remove_the_same_position_as_move_to;
        atom invalid_move_to_target;
        atom invalid_remove;
    }
}

rustler::rustler_export_nifs! {
    "Elixir.TableTopEx.NifBridge",
    [
        // Tic Tac Toe
        ("tic_tac_toe_available", 1, tic_tac_toe::available),
        ("tic_tac_toe_board", 1, tic_tac_toe::board),
        ("tic_tac_toe_apply_action", 3, tic_tac_toe::apply_action),
        ("tic_tac_toe_new", 0, tic_tac_toe::new),
        ("tic_tac_toe_status", 1, tic_tac_toe::status),
        ("tic_tac_toe_whose_turn", 1, tic_tac_toe::whose_turn),
        ("tic_tac_toe_history", 1, tic_tac_toe::history),
        // Marooned
        ("marooned_new", 0, marooned::new),
        ("marooned_whose_turn", 1, marooned::whose_turn),
        ("marooned_history", 1, marooned::history),
        ("marooned_status", 1, marooned::status),
        ("marooned_removable_for_player", 2, marooned::removable_for_player),
        ("marooned_removed", 1, marooned::removed),
        ("marooned_player_position", 2, marooned::player_position),
        ("marooned_apply_action", 2, marooned::apply_action),
    ],
    Some(load)
}

fn load(env: Env, _info: Term) -> bool {
    resource_struct_init!(MaroonedResource, env);
    resource_struct_init!(TicTacToeResource, env);
    true
}
