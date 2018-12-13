# lavapotion

An experimental [Lavalink](https://github.com/Frederikam/Lavalink) client for [Elixir](https://elixir-lang.org).
Not fully complete, but **should** be ready for normal use. As explained below, only releases on Hex are considered
fully stable and ready for use in production. Releases from Git are usually not tested (properly) and not documented.
Use at your own caution.

Completion Checklist:
* All functionality besides Equalizer support.
* Load balancing.
* **Theoretical** multi-node support (**not** multiple clients though, only one ETS table is used).
* Documentation **not done** as of the 13th December 2018.
* Tested partially using the [Coxir](https://github.com/satom99/coxir) library, tests **not** included in the library.
* No Hex releases yet so full documentation/testing hasn't been done. Not recommended for production use yet. 

Feel free to add this package via Git:
```elixir
defp deps do
  [{:lavapotion, git: "https://github.com/SamOphis/lavapotion.git"}]
end
```

Hex releases will be made available once this project becomes stable enough for use in production.
You should consider all releases straight from Git to be experimental and not fit for safe use, whereas
Hex releases should all be tested and fit for production.