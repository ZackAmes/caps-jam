use cairo_vm::cairo_run;
use cairo_vm::hint_processor::builtin_hint_processor::builtin_hint_processor_definition::BuiltinHintProcessor;
use cairo_vm::types::layout_name::LayoutName;
use std::fs;

fn main() {
    println!("Loading and running executable...");

    let program_content = fs::read("target/dev/caps_wasm.executable.json")
        .expect("Failed to read executable file. Make sure you have run 'scarb build'.");

    let mut hint_processor = CairoHintProcessor {
        runner: None,
        user_args: vec![vec![Arg::Array(
            args.run.arguments.clone().read_arguments()?,
        )]],
        string_to_hint,
        starknet_state: Default::default(),
        run_resources: Default::default(),
        syscalls_used_resources: Default::default(),
        no_temporary_segments: false,
        markers: Default::default(),
        panic_traceback: Default::default(),
    };

    let proof_mode = false;

    let cairo_run_config = CairoRunConfig {
        allow_missing_builtins: Some(true),
        layout: LayoutName::all_cairo,
        proof_mode,
        secure_run: None,
        relocate_mem: output.is_standard(),
        trace_enabled: output.is_standard(),
        disable_trace_padding: proof_mode,
        ..Default::default()
    };

    let mut runner =
        cairo_run_program(&program, &cairo_run_config, &mut hint_processor).map_err(|err| {
            if let Some(panic_data) = hint_processor.markers.last() {
                anyhow!(format_for_panic(panic_data.iter().copied()))
            } else {
                anyhow::Error::from(err).context("Cairo program run failed")
            }
        })?;

    let mut cairo_runner = cairo_run::cairo_run(
        &program_content,
        &cairo_run::CairoRunConfig {
            layout: LayoutName::all_cairo,
            ..cairo_run::CairoRunConfig::default()
        },
        &mut hint_processor,
    )
    .expect("Cairo run failed");

    println!("Executable ran successfully.");

    // You can inspect the VM state or return values here if needed.
    // The 'cairo_runner' variable is mutable and currently unused, which will
    // cause compiler warnings. This is intentional so you can uncomment the
    // following lines to inspect the execution results.
    //
    // let return_values = cairo_runner.get_return_values(2).expect("Failed to get return values");
    // println!("Return values: {:?}", return_values);
}