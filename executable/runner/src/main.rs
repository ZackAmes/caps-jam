use anyhow::{Context, Result};
use cairo_lang_executable::executable::{EntryPointKind, Executable};
use cairo_lang_runner::{build_hints_dict, Arg, CairoHintProcessor};
use cairo_vm::cairo_run::{cairo_run_program, CairoRunConfig};
use cairo_vm::types::layout_name::LayoutName;
use cairo_vm::types::program::Program;
use cairo_vm::types::relocatable::MaybeRelocatable;
use cairo_vm::Felt252;
use std::fs;

fn main() -> Result<()> {
    println!("Loading and running executable...");

    // 1. Load and deserialize the executable file.
    let executable_json = fs::read("../target/dev/caps_wasm.executable.json")
        .context("Failed to read executable file. Make sure you have run 'scarb build'.")?;
    let executable: Executable =
        serde_json::from_slice(&executable_json).context("Failed to deserialize executable.")?;

    // 2. Extract data and hints from the executable.
    let data: Vec<MaybeRelocatable> = executable
        .program
        .bytecode
        .iter()
        .map(Felt252::from)
        .map(MaybeRelocatable::from)
        .collect();

    let (hints, string_to_hint) = build_hints_dict(&executable.program.hints);

    // 3. Find the 'Standalone' entrypoint to define the program.
    let entrypoint = executable
        .entrypoints
        .iter()
        .find(|e| matches!(e.kind, EntryPointKind::Standalone))
        .context("No `Standalone` entrypoint found in executable.")?;

    let program = Program::new(
        entrypoint.builtins.clone(),
        data,
        Some(entrypoint.offset),
        hints,
        Default::default(), // reference_manager
        Default::default(), // identifiers
        vec![],             // error_message_attributes
        None,               // instruction_locations
    )
    .context("Failed to build program from executable.")?;

    // 4. Setup the hint processor.
    let mut hint_processor = CairoHintProcessor {
        runner: None,
        user_args: vec![vec![Arg::Array(vec![])]],
        string_to_hint,
        starknet_state: Default::default(),
        run_resources: Default::default(),
        syscalls_used_resources: Default::default(),
        no_temporary_segments: false,
        markers: Default::default(),
        panic_traceback: Default::default(),
    };

    // 5. Configure the Cairo run.
    let proof_mode = false;
    let cairo_run_config = CairoRunConfig {
        allow_missing_builtins: Some(true),
        layout: LayoutName::all_cairo,
        proof_mode,
        relocate_mem: true,
        trace_enabled: true,
        disable_trace_padding: proof_mode,
        ..Default::default()
    };

    // 6. Run the program.
    let mut runner = cairo_run_program(&program, &cairo_run_config, &mut hint_processor)
        .context("Cairo program run failed.")?;

    println!("Executable ran successfully.");

    // 7. Write program output to the console.
    let mut output_buffer = String::new();
    runner.vm.write_output(&mut output_buffer)?;
    if !output_buffer.is_empty() {
        println!("--- Program output ---");
        print!("{}", output_buffer);
        println!("----------------------");
    }

    Ok(())
}