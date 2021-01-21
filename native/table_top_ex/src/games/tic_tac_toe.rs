use crate::atoms;
use crate::TicTacToeResource;
use lib_table_top::games::tic_tac_toe::{
    Col, Col::*, Error::*, GameState, Marker, Marker::*, Position, Row, Row::*, Status::*,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, NifResult, Term};
use std::sync::Mutex;

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = GameState::new();
    let resource = ResourceArc::new(TicTacToeResource(Mutex::new(game)));

    Ok((atoms::ok(), resource).encode(env))
}

pub fn at_position<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game,
    };

    let position: Position = ints_to_position(&args[1].decode()?)?;
    let at = game
        .at_position(position)
        .map(marker_to_atom)
        .unwrap_or(atoms::nil());

    Ok((atoms::ok(), at).encode(env))
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
        InProgress => atoms::in_progress().encode(env),
        Draw => atoms::draw().encode(env),
        Win { marker, spaces } => {
            let spaces: Vec<(u8, u8)> = spaces.map(|pos| position_to_ints(&pos)).into();
            (atoms::win(), marker_to_atom(marker), spaces).encode(env)
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

pub fn make_move<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = match args[0].decode() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(r) => r,
    };

    let mut game = match resource.0.lock() {
        Err(_) => return Ok((atoms::error(), atoms::bad_reference()).encode(env)),
        Ok(game) => game,
    };

    let marker = atom_to_marker(args[1].decode()?)?;
    let position = ints_to_position(&args[2].decode()?)?;

    game.make_move(marker, position)
        .and_then(|_| Ok(atoms::ok().encode(env)))
        .or_else(|err| {
            let error = match err {
                SpaceIsTaken => atoms::space_is_taken(),
                OtherPlayerTurn { .. } => atoms::other_player_turn(),
            };

            Ok((atoms::error(), error).encode(env))
        })
}

fn atom_to_marker(atom: rustler::Atom) -> Result<Marker, Error> {
    if atom == atoms::x() {
        Ok(X)
    } else if atom == atoms::o() {
        Ok(O)
    } else {
        Err(Error::RaiseTerm(Box::new((
            atoms::error(),
            "Only atoms :x or :o are allowed",
        ))))
    }
}

fn marker_to_atom(marker: Marker) -> rustler::Atom {
    match marker {
        X => atoms::x(),
        O => atoms::o(),
    }
}

fn ints_to_position(&(col, row): &(u8, u8)) -> Result<Position, Error> {
    let col: Option<Col> = match col {
        0 => Some(Col0),
        1 => Some(Col1),
        2 => Some(Col2),
        _ => None,
    };

    let row: Option<Row> = match row {
        0 => Some(Row0),
        1 => Some(Row1),
        2 => Some(Row2),
        _ => None,
    };

    match (col, row) {
        (Some(col), Some(row)) => Ok((col, row)),
        _ => Err(Error::RaiseTerm(Box::new((
            atoms::error(),
            "row and cols must be in [0, 1, 2]",
        )))),
    }
}

fn position_to_ints(&(col, row): &Position) -> (u8, u8) {
    let col = match col {
        Col0 => 0,
        Col1 => 1,
        Col2 => 2,
    };

    let row = match row {
        Row0 => 0,
        Row1 => 1,
        Row2 => 2,
    };

    (col, row)
}
