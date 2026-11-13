-- Server-only settings. This file is never sent to players, so the webhook stays private.
ServerConfig = {}

-- Posts a message to Discord when a player leaves dead or badly hurt (possible combat log).
ServerConfig.CombatLog = {
    -- Discord webhook URL. Leave empty to turn the feature off.
    -- Channel settings > Integrations > Webhooks > New webhook > Copy webhook URL
    webhook = '',

    -- Report players who leave while dead.
    logDead = true,

    -- Report players who leave alive with less health than this, in percent. 0 = off.
    lowHealth = 40,

    -- Also report when a player switches character in that state (multicharacter).
    logCharacterSwitch = true,

    -- Name the messages are posted under.
    botName = 'Combat log',
}
