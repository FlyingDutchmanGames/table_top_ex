#![allow(unused_imports)]

use crate::{atoms, MaroonedResource};
use lib_table_top::games::marooned::{
    Action,
    ActionError::*,
    Col, Dimensions, GameState,
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
        .map(|&action| action_to_tuple(action))
        .collect();

    Ok((atoms::ok(), hist).encode(env))
}

pub fn dimensions<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let dimensions = game.0.dimensions();
    Ok((dimensions.rows, dimensions.cols).encode(env))
}

pub fn valid_action<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let action = game.0.valid_actions().map(action_to_tuple).next();
    match action {
        Some(action) => Ok((atoms::ok(), action).encode(env)),
        None => Ok(atoms::nil().encode(env)),
    }
}

pub fn valid_actions<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let actions: Vec<_> = game.0.valid_actions().map(action_to_tuple).collect();
    Ok((atoms::ok(), actions).encode(env))
}

pub fn status<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;

    match game.0.status() {
        InProgress => Ok(atoms::in_progress().encode(env)),
        Win { player } => Ok((atoms::win(), player_to_atom(player)).encode(env)),
    }
}

pub fn removed<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let removed: Vec<_> = game.0.removed().map(position_to_ints).collect();
    Ok((atoms::ok(), removed).encode(env))
}

pub fn removable_for_player<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let player: Player = atom_to_player(args[1].decode()?)?;
    let removable: Vec<_> = game
        .0
        .removable_for_player(player)
        .map(position_to_ints)
        .collect();
    Ok((atoms::ok(), removable).encode(env))
}

pub fn is_position_allowed_to_be_removed<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let position: Position = ints_to_position(args[1].decode()?);
    let player: Player = atom_to_player(args[2].decode()?)?;
    Ok(game
        .0
        .is_position_allowed_to_be_removed(position, player)
        .encode(env))
}

pub fn player_position<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let player: Player = atom_to_player(args[1].decode()?)?;
    Ok((
        atoms::ok(),
        position_to_ints(game.0.player_position(player)),
    )
        .encode(env))
}

pub fn allowed_movement_targets_for_player<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let player: Player = atom_to_player(args[1].decode()?)?;
    let targets: Vec<(u8, u8)> = game
        .0
        .allowed_movement_targets_for_player(player)
        .map(position_to_ints)
        .collect();
    Ok((atoms::ok(), targets).encode(env))
}

pub fn apply_action<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let (player, to, remove): (rustler::Atom, (u8, u8), (u8, u8)) = args[1].decode()?;
    let action = Action {
        player: atom_to_player(player)?,
        remove: ints_to_position(remove),
        to: ints_to_position(to),
    };

    match game.0.apply_action(action) {
        Ok(game) => Ok((atoms::ok(), ResourceArc::new(MaroonedResource(game))).encode(env)),
        Err(err) => match err {
            OtherPlayerTurn { .. } => Ok((atoms::error(), atoms::other_player_turn()).encode(env)),
            InvalidRemove { .. } => Ok((atoms::error(), atoms::invalid_remove()).encode(env)),
            InvalidMoveToTarget { .. } => {
                Ok((atoms::error(), atoms::invalid_move_to_target()).encode(env))
            }
            CantRemoveTheSamePositionAsMoveTo { .. } => Ok((
                atoms::error(),
                atoms::cant_remove_the_same_position_as_move_to(),
            )
                .encode(env)),
        },
    }
}

fn action_to_tuple(Action { to, remove, player }: Action) -> (rustler::Atom, (u8, u8), (u8, u8)) {
    (
        player_to_atom(player),
        position_to_ints(to),
        position_to_ints(remove),
    )
}

fn position_to_ints((Col(col), Row(row)): Position) -> (u8, u8) {
    (col, row)
}

fn ints_to_position((col, row): (u8, u8)) -> Position {
    (Col(col), Row(row))
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
