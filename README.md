# Tic-Tac-Toe Gmae server

## Documentation

For how to use the API to play the game in elixir shell, please see documentation in
module TicTacToe.

For the explanation of the mechanism of handling concurrency and fault-tolerency, please
see documentation in module TicTacToe.Router.

## Test

To run the tests, please used

```
mix test --no-start
```

## Background

This is a challenge assignment I wrote during the recruitment process of a company I applied.

Below are some of the original requirments that came with the challenge.

### What we're paying attention to

- if the project works & respects the spec
- your approach to the problem
- your tests
- your use of OTP (if you decide to use it)
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

_The spec is deliberately lightweight, as we want to see how you are
approaching the task and what solution(s) you can come up with._

- the server needs to be able to handle multiple concurrent games
- if a game crashes, we should be able to recover to a good state automatically
- we should be able to play by launching your project with `iex -S mix`

![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Tic_tac_toe.svg/1200px-Tic_tac_toe.svg.png)
