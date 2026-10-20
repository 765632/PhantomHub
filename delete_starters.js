const { Client, GatewayIntentBits, ChannelType } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    console.log(`Cleaning starters from: ${guild.name}\n`);

    // Delete any channels with no parent category (Discord defaults)
    for (const [, ch] of guild.channels.cache) {
        if (!ch.parentId && ch.type !== ChannelType.GuildCategory) {
            try { await ch.delete("Removing starter channel"); console.log(`  🗑️  #${ch.name}`); }
            catch (e) { console.log(`  ⚠️  #${ch.name}: ${e.message}`); }
        }
    }

    console.log("\nDone.");
    process.exit(0);
});
client.login(token);
