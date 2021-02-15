use crate::{atoms, TicTacToeResource};
use lib_table_top::games::tic_tac_toe::{
    Col, Col::*, Error::*, GameState, Player, Player::*, Position, Row, Row::*, Status::*,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, NifResult, Term};

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let resource = ResourceArc::new(TicTacToeResource(GameState::new()));
    Ok((atoms::ok(), resource).encode(env))
}

pub fn board<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
    let board: Vec<Vec<rustler::Atom>> = game
        .0
        .board()
        .iter()
        .map(|(_col_num, row)| {
            row.iter()
                .map(|(_row_num, player)| player.map_or(atoms::nil(), player_to_atom))
                .collect()
        })
        .collect();

    Ok((atoms::ok(), board).encode(env))
}

pub fn available<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
    let available: Vec<(u8, u8)> = game
        .0
        .available()
        .map(|position| position_to_ints(&position))
        .collect();

    Ok((atoms::ok(), available).encode(env))
}

pub fn status<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;

    match game.0.status() {
        InProgress => Ok(atoms::in_progress().encode(env)),
        Draw => Ok(atoms::draw().encode(env)),
        Win { player, positions } => {
            let spaces: Vec<(u8, u8)> = positions.map(|pos| position_to_ints(&pos)).into();
            Ok((atoms::win(), player_to_atom(player), spaces).encode(env))
        }
    }
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
    Ok((atoms::ok(), player_to_atom(game.0.whose_turn())).encode(env))
}

pub fn apply_action<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
    let player = atom_to_player(args[1].decode()?)?;
    let position = ints_to_position(&args[2].decode()?)?;

    match game.0.apply_action((player, position)) {
        Ok(new_game) => {
            let game = ResourceArc::new(TicTacToeResource(new_game));
            Ok((atoms::ok(), game).encode(env))
        }
        Err(err) => {
            let error = match err {
                SpaceIsTaken { .. } => atoms::space_is_taken(),
                OtherPlayerTurn { .. } => atoms::other_player_turn(),
            };

            Ok((atoms::error(), error).encode(env))
        }
    }
}

pub fn history<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<TicTacToeResource> = args[0].decode()?;
    let hist: Vec<(rustler::Atom, (u8, u8))> = game
        .0
        .history()
        .map(|(player, position)| (player_to_atom(player), position_to_ints(&position)))
        .collect();

    Ok((atoms::ok(), hist).encode(env))
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
