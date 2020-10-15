# 𝘙𝘺𝘶𝘴𝘩
[![Twitter](https://img.shields.io/twitter/follow/shiryel_.svg?style=social)](https://twitter.com/shiryel_)

Ryush is a discord bot under construction

<img src="ryush.png" alt="Ryush profile pic" height="400">

## How to test

With elixir and the phoenix framework installed:
```
export BOT_TOKEN="you discord bot_token here"

# start postgres container
podman run -d -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres

mix deps.get
mix ecto.setup
mix phx.server
```

Now you can test your bot on your discord and visit [`localhost:4000/dashboard`](http://localhost:4000/dashboard) to see the bot dashboard

## Docs

You can generate the docs with `mix docs` and then access the index from your browser

# Legal Stuff

## Software License

Give credit where credit is due. If you wish to use my code in a project, please credit me. 
Just don't blatantly copy it or refrain from crediting.

    Ryush, a bot for doing fun stuff
    Copyright (C) 2020 Shiryel

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.

[The full license can be found here](https://github.com/shiryel/ryush-bot/blob/master/LICENSE)

## Artwork License

The artwork for this project (more specificaly the Ryush profile picture) is licensed under 

    Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)
    Copyright (C) 2020 Shiryel
