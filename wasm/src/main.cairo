use core::dict::{Felt252Dict, SquashedFelt252Dict, SquashedFelt252DictTrait, Felt252DictTrait};

#[executable]
fn main() -> u32 {
    let mut dict: Felt252Dict<u32> = Default::default();

    dict.insert(1, 1);
    dict.insert(2, 2);
    dict.insert(3, 3);
    dict.insert(4, 4);
    dict.insert(5, 5);

    let mut sdict: SquashedFelt252Dict<u32> = dict.squash();

    let entries = sdict.into_entries();

    for entry in entries {
        println!("")
    }

    0
    
}

fn fib(mut n: u32) -> u32 {
    let mut a: u32 = 0;
    let mut b: u32 = 1;
    while n != 0 {
        n = n - 1;
        let temp = b;
        b = a + b;
        a = temp;
    };
    a
}

#[cfg(test)]
mod tests {
    use super::fib;

    #[test]
    fn it_works() {
        assert(fib(16) == 987, 'it works!');
    }
}
