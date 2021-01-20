use crate::atoms;
use std::sync::Mutex;
use lib_table_top::games::tic_tac_toe::{GameState, Position, Col::*, Row::*, Marker::*};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, NifResult, Term};
use crate::TicTacToeResource;

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = GameState::new();
    let resource = ResourceArc::new(TicTacToeResource(Mutex::new(game)));

    Ok((atoms::ok(), resource).encode(env))
}

pub fn available<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game
    };

    let available: Vec<(u8, u8)> =
        game
            .available()
            .iter()
            .map(position_to_ints)
            .collect();

    Ok((atoms::ok(), available).encode(env))
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game
    };

    let whose_turn = match game.whose_turn() {
        Some(X) => atoms::x(),
        Some(O) => atoms::o(),
        None => atoms::nil(),
    };

    Ok((atoms::ok(), whose_turn).encode(env))
}

fn position_to_ints(&(col, row): &Position) -> (u8, u8) {
    let x = match col {
        Col0 => 0,
        Col1 => 1,
        Col2 => 2,
    };

    let y = match row {
        Row0 => 0,
        Row1 => 1,
        Row2 => 2
    };

    (x, y)
}
