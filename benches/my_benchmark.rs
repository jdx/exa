use criterion::{black_box, criterion_group, criterion_main, Criterion};

pub fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("logger", |b| {
        b.iter(|| {
            exa::logger::configure(black_box(std::env::var_os(exa::options::vars::EXA_DEBUG)))
        })
    });
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
