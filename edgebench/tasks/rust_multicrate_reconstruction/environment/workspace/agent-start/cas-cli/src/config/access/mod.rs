mod get;
mod global;
mod hooks_traits;
mod io;
mod list;
mod set;

pub use global::{
    get_telemetry_consent, global_cas_dir, load_global_config, prompt_telemetry_consent,
    save_global_config, set_telemetry_consent,
};
