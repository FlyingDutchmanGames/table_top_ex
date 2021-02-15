#![allow(unused_imports)]

use crate::{atoms, MaroonedResource};
use lib_table_top::games::marooned::{
    Action, ActionError, Col, Dimensions, GameState,
    Player::{self, *},
    Position, Row, Settings, SettingsBuilder,
    SettingsError::*,
    Status::*,
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

pub fn history<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let hist: Vec<_> = game
        .0
        .history()
        .map(|Action { player, to, remove }| {
            (
                player_to_atom(*player),
                position_to_ints(*to),
                position_to_ints(*remove),
            )
        })
        .collect();

    Ok((atoms::ok(), hist).encode(env))
}

pub fn status<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;

    match game.0.status() {
        InProgress => Ok(atoms::in_progress().encode(env)),
        Win { player } => { Ok((atoms::win(), player_to_atom(player)).encode(env)) }
    }
}

pub fn removed<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let removed: Vec<_> = game.0.removed_positions().map(position_to_ints).collect();
    Ok((atoms::ok(), removed).encode(env))
}

pub fn removable<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let removable: Vec<_> = game.0.removable_positions().map(position_to_ints).collect();
    Ok((atoms::ok(), removable).encode(env))
}

pub fn player_position<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>>  {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let player: Player = atom_to_player(args[1].decode()?)?;
    Ok((atoms::ok(), position_to_ints(game.0.player_position(player))).encode(env))
}

fn position_to_ints((Col(col), Row(row)): Position) -> (u8, u8) {
    (col, row)
}

fn player_to_atom(player: Player) -> rustler::Atom {
    match player {
        P1 => atoms::P1(),
        P2 => atoms::P2(),
    }
}

fn atom_to_player(atom: rustler::Atom) -> Result<Player, Error> {
    if atom == atoms::P1() {
        Ok(P1)
    } else if atom == atoms::P2() {
        Ok(P2)
    } else {
        Err(Error::RaiseAtom("invalid_player"))
    }
}
