#![allow(non_snake_case, unused_macros)]

use proconio::input;
use rand::prelude::*;
use std::{collections::BTreeSet, ops::RangeBounds};
use svg::node::element::{path::Data, Path};

pub trait SetMinMax {
    fn setmin(&mut self, v: Self) -> bool;
    fn setmax(&mut self, v: Self) -> bool;
}
impl<T> SetMinMax for T
where
    T: PartialOrd,
{
    fn setmin(&mut self, v: T) -> bool {
        *self > v && {
            *self = v;
            true
        }
    }
    fn setmax(&mut self, v: T) -> bool {
        *self < v && {
            *self = v;
            true
        }
    }
}

#[macro_export]
macro_rules! mat {
	($($e:expr),*) => { Vec::from(vec![$($e),*]) };
	($($e:expr,)*) => { Vec::from(vec![$($e),*]) };
	($e:expr; $d:expr) => { Vec::from(vec![$e; $d]) };
	($e:expr; $d:expr $(; $ds:expr)+) => { Vec::from(vec![mat![$e $(; $ds)*]; $d]) };
}

pub const W: i64 = 10000;

#[derive(Clone, Debug)]
pub struct Input {
    pub ps: Vec<(i64, i64)>,
    pub size: Vec<i64>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rect {
    pub x1: i64,
    pub x2: i64,
    pub y1: i64,
    pub y2: i64,
}

impl Rect {
    pub fn size(&self) -> i64 {
        (self.x2 - self.x1) * (self.y2 - self.y1)
    }
}

impl std::fmt::Display for Input {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "{}", self.ps.len())?;
        for i in 0..self.ps.len() {
            writeln!(f, "{} {} {}", self.ps[i].0, self.ps[i].1, self.size[i])?;
        }
        Ok(())
    }
}

pub fn parse_input(f: &str) -> Input {
    let f = proconio::source::once::OnceSource::from(f);
    input! {
        from f,
        n: usize,
        xys: [(i64, i64, i64); n]
    }
    let ps = xys.iter().map(|&(x, y, _)| (x, y)).collect::<Vec<_>>();
    let size = xys.iter().map(|&(_, _, s)| s).collect::<Vec<_>>();
    Input { ps, size }
}

pub fn read<T: Copy + PartialOrd + std::fmt::Display + std::str::FromStr, R: RangeBounds<T>>(
    token: Option<&str>,
    range: R,
) -> Result<T, String> {
    if let Some(v) = token {
        if let Ok(v) = v.parse::<T>() {
            if !range.contains(&v) {
                Err(format!("Out of range: {}", v))
            } else {
                Ok(v)
            }
        } else {
            Err(format!("Parse error: {}", v))
        }
    } else {
        Err("Unexpected EOF".to_owned())
    }
}

pub struct Output {
    pub out: Vec<Rect>,
}

pub fn parse_output(input: &Input, f: &str) -> Result<Output, String> {
    let mut out = vec![];
    let mut f = f.split_whitespace();
    for _ in 0..input.ps.len() {
        out.push(Rect {
            x1: read(f.next(), 0..=W)?,
            y1: read(f.next(), 0..=W)?,
            x2: read(f.next(), 0..=W)?,
            y2: read(f.next(), 0..=W)?,
        });
    }
    if f.next().is_some() {
        return Err("Too many rectangles".to_owned());
    }
    Ok(Output { out })
}

pub fn gen(seed: u64) -> Input {
    let mut rng = rand_chacha::ChaCha20Rng::seed_from_u64(seed);
    let n = (50.0 * 4.0f64.powf(rng.gen::<f64>())).round() as usize;
    let mut ps = vec![];
    let mut used = BTreeSet::new();
    for _ in 0..n {
        loop {
            let x = rng.gen_range(0i32, 10000) as i64;
            let y = rng.gen_range(0i32, 10000) as i64;
            if used.insert((x, y)) {
                ps.push((x, y));
                break;
            }
        }
    }
    let mut q = rand::seq::index::sample(&mut rng, 10000 * 10000 - 1, n - 1)
        .into_iter()
        .map(|a| a + 1)
        .collect::<Vec<_>>();
    q.sort();
    q.insert(0, 0);
    q.push(10000 * 10000);
    let mut size = vec![];
    for i in 0..n {
        size.push((q[i + 1] - q[i]) as i64);
    }
    Input { ps, size }
}

pub fn compute_score(input: &Input, out: &Output) -> (i64, String) {
    let (mut score, err, _) = compute_score_details(input, &out.out);
    if err.len() > 0 {
        score = 0;
    }
    (score, err)
}

pub fn intersect(r1: &Rect, r2: &Rect) -> bool {
    r1.x2.min(r2.x2) > r1.x1.max(r2.x1) && r1.y2.min(r2.y2) > r1.y1.max(r2.y1)
}

pub fn compute_score_details(input: &Input, out: &[Rect]) -> (i64, String, ()) {
    let n = input.ps.len();
    let mut score = 0.0;
    for i in 0..n {
        if out[i].x1 < 0 || out[i].x2 > W || out[i].y1 < 0 || out[i].y2 > W {
            return (0, format!("rectangle {} is out of range", i), ());
        }
        if out[i].x1 >= out[i].x2 || out[i].y1 >= out[i].y2 {
            return (
                0,
                format!("rectangle {} does not have positive area", i),
                (),
            );
        }
        if !(out[i].x1 <= input.ps[i].0
            && input.ps[i].0 < out[i].x2
            && out[i].y1 <= input.ps[i].1
            && input.ps[i].1 < out[i].y2)
        {
            continue;
        }
        for j in 0..i {
            if intersect(&out[i], &out[j]) {
                return (0, format!("rectangles {} and {} overlap", j, i), ());
            }
        }
        let s = out[i].size().min(input.size[i]) as f64 / out[i].size().max(input.size[i]) as f64;
        score += 1.0 - (1.0 - s) * (1.0 - s);
    }
    ((1e9 * score / n as f64).round() as i64, String::new(), ())
}

pub fn vis_default(input: &Input, out: &Output) -> (i64, String, String) {
    let (mut score, err, svg) = vis(input, &out.out, true);
    if err.len() > 0 {
        score = 0;
    }
    (score, err, svg)
}

fn rect(r: Rect) -> Data {
    Data::new()
        .move_to((r.x1, r.y1))
        .line_by((r.x2 - r.x1, 0))
        .line_by((0, r.y2 - r.y1))
        .line_by((r.x1 - r.x2, 0))
        .close()
}

// 0 <= val <= 1
fn color(val: f64) -> String {
    let tmp = ((-(2.0 * std::f64::consts::PI * val).cos() / 2.0 + 0.5) * 255.0) as i32;
    if val >= 0.5 {
        format!("#{:02x}{:02x}{:02x}", 255, 0, tmp)
    } else {
        format!("#{:02x}{:02x}{:02x}", tmp, 0, 255)
    }
}

pub fn vis(input: &Input, out: &[Rect], show_id: bool) -> (i64, String, String) {
    let (score, err, _) = compute_score_details(input, &out);
    let mut doc = svg::Document::new()
        .set("id", "vis")
        .set("viewBox", (-100, -100, W + 200, W + 200))
        .set("width", 600)
        .set("height", 600)
        .set("style", "background-color:white");
    doc = doc.add(Path::new().set("fill", "white").set(
        "d",
        rect(Rect {
            x1: 0,
            y1: 0,
            x2: W,
            y2: W,
        }),
    ));
    for i in 0..input.ps.len() {
        let val = if out[i].size() > input.size[i] {
            1.0 - input.size[i] as f64 / out[i].size() as f64 / 2.0
        } else {
            out[i].size() as f64 / input.size[i] as f64 / 2.0
        };
        let path = Path::new()
            .set("fill", color(val))
            .set("stroke", "black")
            .set("stroke-width", 5.0)
            .set("d", rect(out[i]));
        doc = doc.add(path);
    }
    for i in 0..input.ps.len() {
        let data = rect(Rect {
            x1: input.ps[i].0 - 30,
            x2: input.ps[i].0 + 30,
            y1: input.ps[i].1 - 30,
            y2: input.ps[i].1 + 30,
        });
        let path = Path::new().set("fill", "green").set("d", data);
        doc = doc.add(path);
        let cx = (out[i].x1 + out[i].x2) as f64 / 2.0;
        let cy = (out[i].y1 + out[i].y2) as f64 / 2.0;
        let data = Data::new()
            .move_to(input.ps[i])
            .line_by((cx - input.ps[i].0 as f64, cy - input.ps[i].1 as f64));
        let path = Path::new()
            .set("stroke", "black")
            .set("stroke-width", 5.0)
            .set("d", data);
        doc = doc.add(path);
    }
    if show_id {
        let fontsize = 200.0 / (input.ps.len() as f64 / 50.0).sqrt();
        for i in 0..input.ps.len() {
            let cx = (out[i].x1 + out[i].x2) as f64 / 2.0;
            let cy = (out[i].y1 + out[i].y2) as f64 / 2.0;
            doc = doc.add(
                svg::node::element::Text::new()
                    .set("x", cx)
                    .set("y", cy + fontsize * 0.35)
                    .set("font-size", fontsize)
                    .set("text-anchor", "middle")
                    .add(svg::node::Text::new(format!("{}", i))),
            );
        }
    }
    (score, err, doc.to_string())
}
