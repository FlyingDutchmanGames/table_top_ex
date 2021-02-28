#![allow(unused_imports)]

use std::sync::Arc;
use std::convert::TryInto;
use crate::{atoms, CrazyEightsResource};
use lib_table_top::common::rand::RngSeed;
use lib_table_top::games::crazy_eights::{GameState, Settings, NumberOfPlayers, Player, Player::*};
use rustler::resource::ResourceArc;
use rustler::{Atom, Binary, Encoder, Env, Error, NifResult, Term};

pub fn new<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let seed: RngSeed = binary_to_seed(args[0].decode()?)?;
    let number_of_players = int_to_number_of_players(args[1].decode()?)?;
    let settings = Settings { seed, number_of_players };
    let resource = ResourceArc::new(CrazyEightsResource(GameState::new(Arc::new(settings))));
    Ok((atoms::ok(), resource).encode(env))
}

pub fn whose_turn<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game: ResourceArc<CrazyEightsResource> = args[0].decode()?;
    Ok((atoms::ok(), player_to_atom(game.0.whose_turn())).encode(env))
}

fn binary_to_seed<'a>(binary: Binary<'a>) -> Result<RngSeed, Error> {
    binary
        .as_slice()
        .try_into()
        .map(|seed| RngSeed(seed))
        .map_err(|_| Error::RaiseAtom("seeds_must_be_exactly_32_bytes"))
}

fn int_to_number_of_players(int: u8) -> Result<NumberOfPlayers, Error> {
    match int {
        2 => Ok(NumberOfPlayers::Two),
        3 => Ok(NumberOfPlayers::Three),
        4 => Ok(NumberOfPlayers::Four),
        5 => Ok(NumberOfPlayers::Five),
        6 => Ok(NumberOfPlayers::Six),
        7 => Ok(NumberOfPlayers::Seven),
        8 => Ok(NumberOfPlayers::Eight),
        _ => Err(Error::RaiseAtom("invalid_number_of_players")),
    }
}

fn player_to_atom(player: Player) -> rustler::Atom {
    match player {
        P1 => atoms::P1(),
        P2 => atoms::P2(),
        P3 => atoms::P3(),
        P4 => atoms::P4(),
        P5 => atoms::P5(),
        P6 => atoms::P6(),
        P7 => atoms::P7(),
        P8 => atoms::P8(),
    }
}
