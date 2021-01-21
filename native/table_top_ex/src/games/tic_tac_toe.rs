use crate::atoms;
use crate::TicTacToeResource;
use lib_table_top::games::tic_tac_toe::{
    Col::*, GameState, Marker, Marker::*, Position, Row::*, Status::*,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, NifResult, Term};
use std::sync::Mutex;

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
        Ok(game) => game,
    };

    let available: Vec<(u8, u8)> = game.available().iter().map(position_to_ints).collect();

    Ok((atoms::ok(), available).encode(env))
}

pub fn status<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game,
    };

    let status = match game.status() {
        InProgress => (atoms::ok(), atoms::in_progress()).encode(env),
        Draw => (atoms::ok(), atoms::draw()).encode(env),
        Win { marker, spaces } => {
            let spaces: Vec<(u8, u8)> = spaces.map(|pos| position_to_ints(&pos)).into();
            (atoms::ok(), atoms::win(), marker_to_atom(marker), spaces).encode(env)
        }
    };

    Ok(status)
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game,
    };

    Ok((
        atoms::ok(),
        game.whose_turn().map_or(atoms::nil(), marker_to_atom),
    )
        .encode(env))
}

fn marker_to_atom(marker: Marker) -> rustler::Atom {
    match marker {
        X => atoms::x(),
        O => atoms::o(),
    }
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
        Row2 => 2,
    };

    (x, y)
}
