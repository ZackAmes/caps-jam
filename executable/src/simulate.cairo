use caps_wasm::set_zero::{get_cap_type, use_ability};
use caps_wasm::types::cap::CapType;
#[executable]
fn main(id: u16) -> ByteArray {
    let cap_type: CapType = get_cap_type(id).unwrap();
    cap_type.name

}