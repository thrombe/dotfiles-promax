use anyhow::Result;

fn main() -> Result<()> {
    let names = std::env::args().collect::<Vec<String>>();
    let c = libwmctl::WmCtl::connect()?;
    let cnt = c
        .windows(false)?
        .into_iter()
        .filter_map(|w| c.win_class(w).ok())
        .filter(|s| names.contains(&s))
        .count();
    println!("{cnt}");
    Ok(())
}
