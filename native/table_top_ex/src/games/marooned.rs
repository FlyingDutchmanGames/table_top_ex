#![allow(unused_imports)]

use crate::{atoms, MaroonedResource};
use lib_table_top::games::marooned::{
    Action, ActionError, Col, Dimensions, GameState, Player::*, Position, Row, Settings,
    SettingsBuilder, SettingsError::*, Status,
};
use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, NifResult, Term};

pub fn new<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let game = SettingsBuilder::new().build_game().unwrap();
    let resource = ResourceArc::new(MaroonedResource(game));
    Ok((atoms::ok(), resource).encode(env))
}
