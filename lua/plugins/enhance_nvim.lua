return {
  {
    "csmhowitzer/enhance.nvim",
    config = function()
      require("enhance").setup({
        enabled = true,
        connections = {
          {
            name = "AcculynxDB-Dev",
            type = "sqlserver",
            server = "dev-monolith-sqlserver.acculynx.com",
            database = "AcculynxDB-Dev",
            user = "mono_web_app",
            password = "fOlJO43d69ZlAU0MtDJpT0csQDP8jp",
          },
          {
            name = "AcculynxDB-Stage",
            type = "sqlserver",
            server = "dev-monolith-sqlserver.acculynx.com",
            database = "AcculynxDB-Stage",
            user = "mono_web_app",
            password = "fOlJO43d69ZlAU0MtDJpT0csQDP8jp",
          },
        },
        --[{"url": "sqlserver://dev-monolith-sqlserver.acculynx.com/AcculynxDB-Dev;user=mono_web_app;password=fOlJO43d69ZlAU0MtDJpT0csQDP8jp;TrustServerCertificate=yes;", "name": "AcculynxDB-Dev"}, {"url": "sqlserver://dev-monolith-sqlserver.acculynx.com/AcculynxDB-Stage;user=mono_web_app;password=fOlJO43d69ZlAU0MtDJpT0csQDP8jp;TrustServerCertificate=yes;", "name": "AcculynxDB-Stage"}]
        --url = "sqlserver://dev-monolith-sqlserver.acculynx.com/AcculynxDB-Dev;user=mono_web_app;password=fOlJO43d69ZlAU0MtDJpT0csQDP8jp;TrustServerCertificate=yes;",
      })
    end,
  },
}
