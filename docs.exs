alias RyushDiscord.{Guild, GuildTalk, GuildFlow, GuildEmojer}

[
  main: "readme",
  logo: "assets/ryush.png",
  assets: "assets",
  extras: [
    "README.md"
  ],
  source_url: "https://github.com/shiryel/ryush_bot",
  nest_modules_by_prefix: [
    RyushDiscord.Connection,
    Guild,
    GuildTalk,
    GuildFlow,
    GuildEmojer
  ],
  groups_for_modules: [
    Base: [
      Ryush,
      Ryush.Application
    ],
    Discord_Connection: [
      RyushDiscord.Connection,
      RyushDiscord.Connection.ApiBot,
      RyushDiscord.Connection.GatewayBot,
      RyushDiscord.Connection.GatewayBot.HandshakeWorkflow,
      RyushDiscord.Connection.GatewayBot.MessageWorkflow
    ],
    Discord_Guild: [
      Guild,
      Guild.GuildBehaviour,
      Guild.GuildServer,
      Guild.Permissions,
      Guild.ServerProcess,
      GuildTalk,
      GuildTalk.TalkBehaviour,
      GuildTalk.TalkServer,
      GuildFlow,
      GuildFlow.E621,
      GuildFlow.FlowBehaviour,
      GuildFlow.FlowRestart,
      GuildEmojer,
      GuildEmojer.EmojerServer
    ],
    External: [
      RyushExternal.E621
    ],
    Database: [
      Ryush.Repo,
      Ryush.Mnesia
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
    Utils: [
      Utils.ConsoleLogger
    ]
  ]
]
