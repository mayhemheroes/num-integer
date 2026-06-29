#![no_main]
use libfuzzer_sys::fuzz_target;
use num_integer::Average;
use num_integer::Integer;

fuzz_target!(|data: u32| {
    let _rt = data.average_floor(&100);
    let _rt = data.average_ceil(&100);
    Integer::gcd(&data, &3);
    Integer::is_even(&data);
    Integer::is_odd(&data);
    Integer::div_floor(&data, &3);
    Integer::mod_floor(&data, &3);
    Integer::lcm(&data, &20);
    Integer::is_multiple_of(&data, &3);
    Integer::div_rem(&data, &3);
    Integer::div_ceil(&data, &3);
});
