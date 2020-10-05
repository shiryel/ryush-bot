[
  main: "readme",
  extras: [
    "README.md"
  ],
  groups_for_modules: [
    Base: [
      Ryush,
      Ryush.Application,
    ],
    Discord_Connection: [
      RyushDiscord.Connection.ApiBot,
      RyushDiscord.Connection.GatewayBot,
      RyushDiscord.Connection.GatewayBot.HandshakeWorkflow,
      RyushDiscord.Connection.GatewayBot.MessageWorkflow
    ],
    Discord_Guild: [
      RyushDiscord.Guild,
      RyushDiscord.Guild.Talk,
      RyushDiscord.Guild.GuildServer,
      RyushDiscord.Guild.GuildRegistry,
      RyushDiscord.Guild.GuildSupervisor,
      RyushDiscord.Talk.TalkServer,
      RyushDiscord.Talk.TalkRegistry,
      RyushDiscord.Talk.TalkSupervisor,
      RyushDiscord.Flow.FlowServer,
      RyushDiscord.Flow.FlowRegistry,
      RyushDiscord.Flow.FlowSupervisor
    ],
    Database: [
      Ryush.Repo,
      Ryush.Discord,
      Ryush.Discord.Guild
    ],
    Phoenix: [
      RyushWeb,
      RyushWeb.Endpoint,
      RyushWeb.Router,
      RyushWeb.Router.Helpers,
      RyushWeb.UserSocket,
      RyushWeb.Gettext,
      RyushWeb.ErrorView,
      RyushWeb.ErrorHelpers
    ],
  ]
]
