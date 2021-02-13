use crate::{atoms, common::Bin, TicTacToeResource};
use lib_table_top::games::tic_tac_toe::{
    Col, Col::*, Error::*, GameState, Player, Player::*, Position, Row, Row::*, Status::*,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, NifResult, Term, Binary};
use std::sync::Mutex;

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = GameState::new();
    let resource = ResourceArc::new(TicTacToeResource(Mutex::new(game)));
    Ok((atoms::ok(), resource).encode(env))
}

pub fn board<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        let board: Vec<Vec<rustler::Atom>> = game
            .board()
            .iter()
            .map(|(_col_num, row)| {
                row.iter()
                    .map(|(_row_num, player)| player.map_or(atoms::nil(), player_to_atom))
                    .collect()
            })
            .collect();

        Box::new((atoms::ok(), board))
    })
}

pub fn available<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        let available: Vec<(u8, u8)> = game
            .available()
            .map(|position| position_to_ints(&position))
            .collect();

        Box::new((atoms::ok(), available))
    })
}

pub fn status<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| match game.status() {
        InProgress => Box::new(atoms::in_progress()),
        Draw => Box::new(atoms::draw()),
        Win { player, positions } => {
            let spaces: Vec<(u8, u8)> = positions.map(|pos| position_to_ints(&pos)).into();
            Box::new((atoms::win(), player_to_atom(player), spaces))
        }
    })
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        Box::new((atoms::ok(), player_to_atom(game.whose_turn())))
    })
}

pub fn apply_action<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let player = atom_to_player(args[1].decode()?)?;
    let position = ints_to_position(&args[2].decode()?)?;

    with_game_state(env, args, |game| match game.apply_action((player, position)) {
        Ok(_) => Box::new(atoms::ok()),
        Err(err) => {
            let error = match err {
                SpaceIsTaken { .. } => atoms::space_is_taken(),
                OtherPlayerTurn { .. } => atoms::other_player_turn(),
            };

            Box::new((atoms::error(), error))
        }
    })
}

pub fn history<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        let hist: Vec<(rustler::Atom, (u8, u8))> = game
            .history()
            .map(|(player, position)| (player_to_atom(player), position_to_ints(&position)))
            .collect();

        Box::new((atoms::ok(), hist))
    })
}

pub fn clone<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        let new_game: GameState = game.clone();
        let resource = ResourceArc::new(TicTacToeResource(Mutex::new(new_game)));
        Box::new((atoms::ok(), resource))
    })
}

pub fn to_json<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| {
        let result = match serde_json::to_string(game) {
            Ok(json) => (atoms::ok(), json),
            Err(err) => (atoms::error(), err.to_string()),
        };

        Box::new(result)
    })
}

pub fn from_json<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let encoded: &str = args[0].decode()?;
    match serde_json::from_str::<GameState>(&encoded) {
        Ok(game) => {
            let resource = ResourceArc::new(TicTacToeResource(Mutex::new(game)));
            Ok((atoms::ok(), resource).encode(env))
        }
        Err(err) => Ok((atoms::error(), err.to_string()).encode(env)),
    }
}

pub fn to_bincode<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    with_game_state(env, args, |game| match bincode::serialize(game) {
        Ok(bincode) => Box::new((atoms::ok(), Bin(bincode))),
        Err(_) => Box::new(atoms::error()),
    })
}

pub fn from_bincode<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let encoded: Binary<'_> = args[0].decode()?;
    match bincode::deserialize::<GameState>(&encoded) {
        Ok(game) => {
            let resource = ResourceArc::new(TicTacToeResource(Mutex::new(game)));
            Ok((atoms::ok(), resource).encode(env))
        }
        Err(err) => Ok((atoms::error(), err.to_string()).encode(env)),
    }
}

fn with_game_state<'a, F: FnOnce(&mut GameState) -> Box<dyn Encoder>>(
    env: Env<'a>,
    args: &[Term<'a>],
    f: F,
) -> NifResult<Term<'a>> {
    let resource: ResourceArc<TicTacToeResource> = args[0].decode()?;
    let mut game = resource
        .0
        .lock()
        .map_err(|_| Error::RaiseAtom("failure_unlocking_mutex"))?;

    Ok(f(&mut (*game)).encode(env))
}

fn atom_to_player(atom: rustler::Atom) -> Result<Player, Error> {
    if atom == atoms::x() {
        Ok(X)
    } else if atom == atoms::o() {
        Ok(O)
    } else {
        Err(Error::RaiseAtom("invalid_player"))
    }
}

fn player_to_atom(player: Player) -> rustler::Atom {
    match player {
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
        _ => Err(Error::Atom("position_outside_of_board")),
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
