#![allow(unused_imports)]

use crate::{atoms, MaroonedResource};
use lib_table_top::games::marooned::{
    Action, ActionError, Col, Dimensions, GameState, Player::{self, *}, Position, Row, Settings,
    SettingsBuilder, SettingsError::*, Status,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, NifResult, Term};

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = SettingsBuilder::new().build_game().unwrap();
    let resource = ResourceArc::new(MaroonedResource(game));
    Ok((atoms::ok(), resource).encode(env))
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    Ok((atoms::ok(), player_to_atom(game.0.whose_turn())).encode(env))
}

// pub fn history<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
//     let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
//     let hist: Vec<(rustler::Atom, (u8, u8))> = game
//         .0
//         .history()
//         .map(|(player, position)| (player_to_atom(player), position_to_ints(&position)))
//         .collect();
// 
//     Ok((atoms::ok(), hist).encode(env))
// }

fn player_to_atom(player: Player) -> rustler::Atom {
    match player {
        P1 => atoms::P1(),
        P2 => atoms::P2(),
    }
}
