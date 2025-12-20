mod utils;

use cairo1_run::{Cairo1RunConfig, FuncArg};
use cairo_lang_sierra::ProgramParser;
use cairo_vm::types::layout_name::LayoutName;
use cairo_vm::Felt252;
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

/// Run the test_input Cairo program with a Game struct and ActionType enum
/// 
/// Input format: JSON array where each element is either:
/// - A string/number for a single felt
/// - An array of strings/numbers for an Array<T> field
/// 
/// For Game { id, player1, player2, caps_ids, turn_count, over, effect_ids, last_action_timestamp }
/// + ActionType { variant, x, y }
#[wasm_bindgen(js_name = runTestInput)]
pub fn run_test_input(args_js: Vec<JsValue>) -> Result<String, JsValue> {
    let mut args: Vec<FuncArg> = Vec::new();
    
    for (i, v) in args_js.iter().enumerate() {
        if v.is_array() {
            // This is an array field - convert to FuncArg::Array
            let arr = js_sys::Array::from(v);
            let felts: Vec<Felt252> = arr
                .iter()
                .map(|elem| {
                    let s = elem.as_string().unwrap_or_else(|| elem.as_f64().unwrap().to_string());
                    Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0))
                })
                .collect();
            log(&format!("Arg {}: Array with {} elements", i, felts.len()));
            args.push(FuncArg::Array(felts));
        } else {
            // Single felt value
            let s = v.as_string().unwrap_or_else(|| v.as_f64().unwrap().to_string());
            let felt = Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0));
            log(&format!("Arg {}: Single({})", i, s));
            args.push(FuncArg::Single(felt));
        }
    }
    
    log(&format!("Total args for test_input: {}", args.len()));
    
    let cairo_run_config = Cairo1RunConfig {
        args: &args,
        layout: LayoutName::all_cairo,
        relocate_mem: true,
        trace_enabled: true,
        serialize_output: true,
        ..Default::default()
    };

    let sierra_program = {
        let program_str = include_str!("../cairo/test_input.sierra");
        wrap_error!(ProgramParser::new().parse(program_str))?
    };

    let (_, _, serialized_output) = wrap_error!(cairo1_run::cairo_run_program(
        &sierra_program,
        cairo_run_config
    ))?;

    let output = serialized_output.unwrap();

    log(&format!("test_input output: {}", output));

    Ok(output)
}

/// Run the test_output Cairo program
/// 
/// Input format: Array where each element is either:
/// - A string/number for a single felt
/// - An array of strings/numbers for an Array<T> field
/// 
/// Arguments in order:
/// 1. Game struct fields (id, player1, player2, caps_ids array, turn_count, over, effect_ids array, last_action_timestamp)
/// 2. Cap struct fields (id, owner, location variant, location x, location y, set_id, cap_type, dmg_taken, shield_amt)
/// 3. Effect struct fields (game_id, effect_id, effect_type variant, effect_target variant, remaining_triggers)
/// 
/// Returns: (Game, Cap, Effect)
#[wasm_bindgen(js_name = runTestOutput)]
pub fn run_test_output(args_js: Vec<JsValue>) -> Result<String, JsValue> {
    let mut args: Vec<FuncArg> = Vec::new();
    
    for (i, v) in args_js.iter().enumerate() {
        if v.is_array() {
            let arr = js_sys::Array::from(v);
            let felts: Vec<Felt252> = arr
                .iter()
                .map(|elem| {
                    let s = elem.as_string().unwrap_or_else(|| elem.as_f64().unwrap().to_string());
                    Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0))
                })
                .collect();
            log(&format!("TestOutput Arg {}: Array with {} elements", i, felts.len()));
            args.push(FuncArg::Array(felts));
        } else {
            let s = v.as_string().unwrap_or_else(|| v.as_f64().unwrap().to_string());
            let felt = Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0));
            log(&format!("TestOutput Arg {}: Single({})", i, s));
            args.push(FuncArg::Single(felt));
        }
    }
    
    log(&format!("Total args for test_output: {}", args.len()));
    
    let cairo_run_config = Cairo1RunConfig {
        args: &args,
        layout: LayoutName::all_cairo,
        relocate_mem: true,
        trace_enabled: true,
        serialize_output: true,
        
        ..Default::default()
    };

    let sierra_program = {
        let program_str = include_str!("../cairo/test_output.sierra");
        wrap_error!(ProgramParser::new().parse(program_str))?
    };

    let (_runner, return_values, serialized_output) = wrap_error!(cairo1_run::cairo_run_program(
        &sierra_program,
        cairo_run_config
    ))?;

    // Get both serialized output (for structure) and return values (for raw variant IDs)
    // Format: serialized_output on first line, then return_values on subsequent lines
    let mut output_parts = Vec::new();
    
    if let Some(ref serialized) = serialized_output {
        output_parts.push(format!("SERIALIZED: {}", serialized));
    }
    
    output_parts.push("RETURN_VALUES:".to_string());
    for (i, val) in return_values.iter().enumerate() {
        output_parts.push(format!("[{}] {}", i, val.to_string()));
    }

    let output = output_parts.join("\n");

    log(&format!("test_output serialized: {:?}", serialized_output));
    log(&format!("test_output return_values count: {}", return_values.len()));
    log(&format!("test_output output: {}", output));

    Ok(output)
}

/// Run the simulate Cairo program
/// 
/// Input format: Array where each element is either:
/// - A string/number for a single felt
/// - An array of strings/numbers for an Array<T> field
/// 
/// Arguments in order:
/// 1. Game struct fields
/// 2. Array of Cap structs (as nested array)
/// 3. Array of Effect structs (as nested array)  
/// 4. Array of Action structs (as nested array)
#[wasm_bindgen(js_name = runSimulate)]
pub fn run_simulate(args_js: Vec<JsValue>) -> Result<String, JsValue> {
    let mut args: Vec<FuncArg> = Vec::new();
    
    for (i, v) in args_js.iter().enumerate() {
        if v.is_array() {
            let arr = js_sys::Array::from(v);
            let felts: Vec<Felt252> = arr
                .iter()
                .map(|elem| {
                    let s = elem.as_string().unwrap_or_else(|| elem.as_f64().unwrap().to_string());
                    Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0))
                })
                .collect();
            log(&format!("Simulate Arg {}: Array with {} elements", i, felts.len()));
            args.push(FuncArg::Array(felts));
        } else {
            let s = v.as_string().unwrap_or_else(|| v.as_f64().unwrap().to_string());
            let felt = Felt252::from_dec_str(&s).unwrap_or_else(|_| Felt252::from(0));
            log(&format!("Simulate Arg {}: Single({})", i, s));
            args.push(FuncArg::Single(felt));
        }
    }
    
    log(&format!("Total args for simulate: {}", args.len()));
    
    let cairo_run_config = Cairo1RunConfig {
        args: &args,
        layout: LayoutName::all_cairo,
        relocate_mem: true,
        trace_enabled: true,
        serialize_output: true,
        ..Default::default()
    };

    let sierra_program = {
        let program_str = include_str!("../cairo/simulate.sierra");
        wrap_error!(ProgramParser::new().parse(program_str))?
    };

    let (_, _, serialized_output) = wrap_error!(cairo1_run::cairo_run_program(
        &sierra_program,
        cairo_run_config
    ))?;

    let output = serialized_output.unwrap();

    log(&format!("simulate output: {}", output));

    Ok(output)
}
