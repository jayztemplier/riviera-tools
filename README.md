# riviera-tools
This repo contains all the different tools/integration kits so you can integrate Riviera Build in your workflow. Feel free to share your tools!

## rivierabuild

A command line tool useful for CI servers and other types of integration.  It uploads builds to Riviera and then optionally posts to slack (works) or sends an email to a list of email addresses (coming soon!).

Example command line:
```
rivierabuild upload "My App" ~/myapp.ipa --availability 1_month --randompasscode --note "Build notes" --appid <your app id> --apikey <your api key> --slackchannel #builds --slackhookurl https://hooks.slack.com/services/something
```

Command line options:

```
Usage: rivierabuild upload <displayname> <ipa> [options]

--randompasscode                         Generate a random passcode.
--availability <availability>            Specifies the availablility of the build.
                                         Use the following values:

                                         10_minutes
                                         1_hour
                                         3_hours
                                         6_hours
                                         12_hours
                                         24_hours
                                         1_week
                                         2_weeks
                                         1_month
                                         2_months
--passcode <passcode>                    Specify the passcode to use for the build.
--apikey <apikey>                        Your RivieraBuild API key.
--appid <appid>                          Your App ID in RivieraBuild.
--note <note>                            The note to show in RivieraBuild
--projectdir <projectdir>                The directory of your project, for Git logs.
--slackhookurl <slackhookurl>            Your Slack webhook URL.
--slackchannel <slackchannel>            The Slack channel to post to.
-h, --help                               Show help information for this command
```

To use slack integration, on your slack domain, add an "Incoming WebHook" integration step.  Customize the name and icon of the webhook bot.  You can also set a default channel to post in.  This can be overridden by the --slackchannel parameters.  The webhook URL shown here is what you'll pass to --slackhookurl.
