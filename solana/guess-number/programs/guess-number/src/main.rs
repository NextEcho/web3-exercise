#[warn(dead_code)]
fn test_func() {
    let arr = [10, 20, 30, 40, 50];
    for idx in 0..=5 {
        println!("{}", arr[idx]);
    }
}

fn main() {
    let add_number = |x: i32| {
        return x + 1;
    };
}
