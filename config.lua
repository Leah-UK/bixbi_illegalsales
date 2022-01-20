Config = {}

Config.Debug = false

Config.FailChance = 4 -- Chance to fail sale. (4 = 1 in 4 (25%))
Config.AlertChance = 2 -- Chance on fail to alert police. (2 = 1 in 2 (50%)). Minimum = 1 (100% chance).
Config.AttemptSaleTime = 5 -- How many seconds it takes to attempt an item sale.
Config.CurrencySymbol = '$'
Config.MenuKeybind = nil -- To enable set to something like 'o'.
Config.MenuCommand = 'illegalmenu'
Config.MoneyItem = 'black_money' -- Item name of the money on a successful trade.

Config.Items = {
    processed_weed = { price_low = 15, price_high = 20, low_count = 3, high_count = 5, label = "Weed" },
    processed_cocaine = { price_low = 30, price_high = 50, low_count = 3, high_count = 5, label = "Cocaine" }
}

Config.UseBixbiTerritories = false -- Are you using bixbi_territories? If not, configure the below.
Config.RestrictToLocations = true -- When enabled you can only sell certain drugs in certain areas.
Config.Locations = {
    -- This is only used if Config.UseTerritories is disabled.
    -- You can find the name of a territory by using the command "/territory".
    SKID = {
        processed_weed = {}
    },
    CYPRE = {
        processed_weed = {},
        processed_cocaine = {}
    }
}