const { Client, GatewayIntentBits, ChannelType } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    console.log(`Nuking defaults from: ${guild.name}\n`);

    // Kill these default categories and everything inside them
    const defaultCats = ["text channels", "voice channels", "general"];

    for (const [, ch] of guild.channels.cache) {
        if (ch.type === ChannelType.GuildCategory && defaultCats.includes(ch.name.toLowerCase())) {
            // Delete all children first
            const children = guild.channels.cache.filter(c => c.parentId === ch.id);
            for (const [, child] of children) {
                try { await child.delete("nuke defaults"); console.log(`  🗑️  #${child.name}`); } catch (e) { console.log(`  ⚠️  ${child.name}: ${e.message}`); }
            }
            // Delete category
            try { await ch.delete("nuke defaults"); console.log(`  🗑️  Category "${ch.name}"`); } catch (e) { console.log(`  ⚠️  ${ch.name}: ${e.message}`); }
        }
    }

    // Also kill any orphan channels with no parent that aren't ours
    const ourCats = guild.channels.cache.filter(c => c.type === ChannelType.GuildCategory).map(c => c.id);
    for (const [, ch] of guild.channels.cache) {
        if (ch.type !== ChannelType.GuildCategory && !ch.parentId) {
            try { await ch.delete("nuke defaults"); console.log(`  🗑️  Orphan #${ch.name}`); } catch (e) { console.log(`  ⚠️  ${ch.name}: ${e.message}`); }
        }
    }

    console.log("\nDone.");
    process.exit(0);
});
client.login(token);
