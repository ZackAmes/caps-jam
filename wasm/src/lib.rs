mod utils;

use cairo1_run::{Cairo1RunConfig, FuncArg};
use cairo_lang_sierra::ProgramParser;
use cairo_vm::types::layout_name::LayoutName;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(msg: &str);
}

#[wasm_bindgen(start)]
pub fn start() {
    crate::utils::set_panic_hook();
}

macro_rules! wrap_error {
    ($xp: expr) => {
        $xp.map_err(|e| JsValue::from_str(&format!("Error from CairoRunner: {}", e.to_string())))
    };
}

#[wasm_bindgen(js_name = runCairoProgram)]
pub fn run_cairo_program(cap_type_id: u16) -> Result<String, JsValue> {
    let cairo_run_config = Cairo1RunConfig {
        args: &[FuncArg::Single(cap_type_id.into())],
        layout: LayoutName::all_cairo,
        relocate_mem: true,
        trace_enabled: true,
        serialize_output: true,
        ..Default::default()
    };

    let sierra_program = {
        let program_str = include_str!("../cairo/types.sierra");
        wrap_error!(ProgramParser::new().parse(program_str))?
    };

    let (_, _, serialized_output) = wrap_error!(cairo1_run::cairo_run_program(
        &sierra_program,
        cairo_run_config
    ))?;

    let output = serialized_output.unwrap();

    log(&output);

    Ok(output)
}
