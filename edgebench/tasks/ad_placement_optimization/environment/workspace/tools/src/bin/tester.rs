fn judge() -> i32 {
    let input = std::fs::read_to_string(std::env::args().nth(1).unwrap()).unwrap();
    let Ok(output) = std::fs::read_to_string(std::env::args().nth(2).unwrap()) else {
        eprintln!("wrong answer: not utf-8");
        return 1;
    };
    let input = tools::parse_input(&input);
    match tools::parse_output(&input, &output) {
        Ok(out) => {
            let (score, err) = tools::compute_score(&input, &out);
            if err.len() > 0 {
                eprintln!("wrong answer: {}", err);
                return 1;
            } else {
                eprintln!("Score = {}", score);
                return 0;
            }
        }
        Err(err) => {
            eprintln!("wrong answer: {}", err);
            return 1;
        }
    }
}

fn main() {
    let ret = judge();
    std::process::exit(ret);
}
