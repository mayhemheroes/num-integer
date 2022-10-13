#![no_main]
use libfuzzer_sys::fuzz_target;
use std::io::{Read, Write};
use num_integer::Roots;
use num_integer::Average;
use num_integer::Integer;
use std::f64::MANTISSA_DIGITS;
use std::fmt::Debug;
use std::mem;

fuzz_target!(|data: u32| {
  let rt=data.average_floor(&100);
  let rt=data.average_ceil(&100);
  data.gcd(&3);
  data.is_even();
  data.is_odd();
  data.div_floor(&3);
  data.mod_floor(&3);
  data.lcm(&20);
  data.is_multiple_of(&3);
  data.div_rem(&3);
  data.div_ceil(&3);

});
