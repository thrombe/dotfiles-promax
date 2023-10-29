use anyhow::Result;

fn main() -> Result<()> {
    let names = std::env::args().collect::<std::collections::HashSet<String>>();
    let c = libwmctl::WmCtl::connect().unwrap();
    let start_time = std::time::Instant::now();
    while !c
        .windows(false)?
        .into_iter()
        .filter_map(|w| c.win_class(w).ok())
        .any(|s| names.contains(&s))
    {
        if std::time::Instant::now()
            .duration_since(start_time)
            .as_secs_f64()
            > 10.0
        {
            println!("-1");
            return Ok(());
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
    }
    println!("1");

    Ok(())
}
