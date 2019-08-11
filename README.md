# Elixir challenge

This repository holds the spec of the recruiting challenge for Elixir developers
at Impraise.

## How to apply

1. fork the repository
2. write your code
3. let us know when you're done!

### What we're paying attention to

- if the project works & respects the spec
- your approach to the problem
- your tests
- your use of OTP
- your domain modelling
- your choice of technologies

## The challenge: tic-tac-toe game

The challenge, if you decide to accept it, is to create a [tic-tac-toe](https://en.wikipedia.org/wiki/Tic-tac-toe) game server.

### The rules

- your project should be well tested because you're not a monster
- your Git history should be meaningful
- if your project involves a few different technologies, a `docker-compose`
  setup will be appreciated

**Good luck!** not that you need any :)

### Tips

- less is more
- domain modelling is important
- SOLID
- choose the right tool for the right job.

---

### Specs

_The spec is voluntarily lightweight, as we want to see how you are
approaching the task and what solution(s) you can come up with._

- the server needs to be able to handle multiple concurrent games
- if a game crashes, we should be able to recover to a good state automatically
- we should be able to play by launching your project with `iex -S mix`

![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Tic_tac_toe.svg/1200px-Tic_tac_toe.svg.png)
