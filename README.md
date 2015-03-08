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
Usage: rivierabuild upload <displayname> <ipa> <availability> [options]

Availabiliy option:
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

--verbose                                Show more details about what's happening.
--disablegitlog                          Disables appending the git log to the notes.
--randompasscode                         Generate a random passcode.
--note <note>                            The note to show in RivieraBuild.
--apikey <apikey>                        Your RivieraBuild API key.
--projectdir <projectdir>                The directory of your project, for Git logs.
--slackhookurl <slackhookurl>            Your Slack webhook URL.
--hipchatcolor <hipchatcolor>            Optional color for the notification posted on Hipchat.
--appid <appid>                          Your App ID in RivieraBuild.
--passcode <passcode>                    Specify the passcode to use for the build.
--slackchannel <slackchannel>            The Slack channel to post to.
--hipchatauthtoken <hipchatauthtoken>    Your Hipchat auth token. To get it: https://www.hipchat.com/account/api.
--hipchatroom <hipchatroom>              The Hipchat room id or name to post to.
-h, --help
```

To use slack integration, on your slack domain, add an "Incoming WebHook" integration step.  Customize the name and icon of the webhook bot.  You can also set a default channel to post in.  This can be overridden by the --slackchannel parameters.  The webhook URL shown here is what you'll pass to --slackhookurl.

## Example

Upload a build with generation of passcode
```
rivierabuild upload AnimalCrush /Users/myuser/myprojectdir/build.ipa 10_minutes --randompasscode --appid 34 --apikey 123esfe163dead532a18593dae5d05227b310ff4 --projectdir /Users/myuser/myprojectdir
```

Integration with Slack
```
rivierabuild upload AnimalCrush /Users/myuser/myprojectdir/build.ipa 10_minutes --appid 34 --apikey 123esfe163dead532a18593dae5d05227b310ff4 --slackhookurl https://hooks.slack.com/services/T02FRSTNH/BRSD/RJEdfAJA2GmvcZN0OaE4VeJO --slackchannel #general --passcode mypassword --projectdir /Users/myuser/myprojectdir
```

Integration with HipChat
```
rivierabuild upload AnimalCrush /Users/myuser/myprojectdir/build.ipa 10_minutes --appid 34 --apikey 123esfe163dead532a18593dae5d05227b310ff4 --passcode mypassword --projectdir /Users/myuser/myprojectdir --hipchatauthtoken njkOTK6cyxADmK79X5pCNOoSTtnJ4veCM --hipchatroom 123456
```
