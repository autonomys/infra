mod sync_config;
mod types;

use crate::sync_config::sync_config;
use crate::types::Command;
use clap::Parser;

fn main() {
    let command: Command = Command::parse();
    match command {
        Command::SyncConfig(config) => sync_config(config),
    }
}
