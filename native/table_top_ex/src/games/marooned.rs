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
use rustler::types::map::MapIterator;
use rustler::{Atom, Encoder, Env, Error, NifResult, Term};

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = SettingsBuilder::new().build_game().unwrap();
    let resource = ResourceArc::new(MaroonedResource(game));
    Ok((atoms::ok(), resource).encode(env))
}

pub fn new_from_settings<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let iter: MapIterator = args[0].decode()?;
    let mut settings_builder = SettingsBuilder::new();

    for (key, val) in iter {
        match key.atom_to_string()?.as_str() {
            "rows" => settings_builder = settings_builder.rows(val.decode()?),
            "cols" => settings_builder = settings_builder.cols(val.decode()?),
            "p1_starting" => {
                let position: Position = ints_to_position(val.decode()?);
                settings_builder = settings_builder.p1_starting(position);
            }
            "p2_starting" => {
                let position: Position = ints_to_position(val.decode()?);
                settings_builder = settings_builder.p2_starting(position);
            }
             "starting_removed" => {
                 let removed = val.decode::<Vec<(u8, u8)>>()?.iter().map(|&pos| ints_to_position(pos)).collect();
                 settings_builder = settings_builder.starting_removed(removed);
             }
            _ => {}
        }
    }

    match settings_builder.build_game() {
        Ok(game) => Ok((atoms::ok(), ResourceArc::new(MaroonedResource(game))).encode(env)),
        Err(err) => {
            let err: Atom = match err {
                InvalidDimensions => atoms::invalid_dimensions(),
                CantRemovePositionNotOnBoard { .. } => atoms::cant_remove_position_not_on_board(),
                PlayersCantStartAtSamePosition => atoms::players_cant_start_at_same_position(),
                PlayersMustStartOnBoard { .. } => atoms::players_must_start_on_board(),
                PlayerCantStartOnRemovedSquare { .. } => {
                    atoms::player_cant_start_on_removed_square()
                }
            };

            Ok((atoms::error(), err).encode(env))
        }
    }
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
    Ok(dimensions_to_tuple(dimensions).encode(env))
}

pub fn settings<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<MaroonedResource> = args[0].decode()?;
    let settings = game.0.settings();
    Ok(settings_to_tuple(settings).encode(env))
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

fn settings_to_tuple(settings: &Settings) -> ((u8, u8), (u8, u8), (u8, u8), Vec<(u8, u8)>) {
    (
        dimensions_to_tuple(&settings.dimensions),
        position_to_ints(settings.p1_starting),
        position_to_ints(settings.p2_starting),
        settings
            .starting_removed
            .iter()
            .map(|&pos| position_to_ints(pos))
            .collect(),
    )
}

fn dimensions_to_tuple(dimensions: &Dimensions) -> (u8, u8) {
    (dimensions.rows, dimensions.cols)
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
