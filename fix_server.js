const { Client, GatewayIntentBits, ChannelType } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    console.log(`Fixing: ${guild.name}\n`);

    // Delete these categories and all their children
    const killList = ["TRADING", "EVENTS", "BRAINROT ZONE"];

    for (const catName of killList) {
        const cat = guild.channels.cache.find(c => c.name.includes(catName) && c.type === ChannelType.GuildCategory);
        if (!cat) { console.log(`  ✓ "${catName}" already gone`); continue; }
        const children = guild.channels.cache.filter(c => c.parentId === cat.id);
        for (const [, ch] of children) {
            try { await ch.delete("cleanup"); console.log(`  🗑️  #${ch.name}`); } catch (e) { console.log(`  ⚠️  ${ch.name}: ${e.message}`); }
        }
        try { await cat.delete("cleanup"); console.log(`  🗑️  Category "${catName}"`); } catch (e) { console.log(`  ⚠️  ${e.message}`); }
    }

    // Create PHANTOMHUB category + code-sniper channel
    let phCat = guild.channels.cache.find(c => c.name === "PHANTOMHUB" && c.type === ChannelType.GuildCategory);
    if (!phCat) {
        phCat = await guild.channels.create({ name: "PHANTOMHUB", type: ChannelType.GuildCategory, reason: "PhantomHub update" });
        console.log(`  ✅ Category "PHANTOMHUB"`);
    }

    const existing = guild.channels.cache.find(c => c.parentId === phCat.id && c.name.includes("code-sniper"));
    if (!existing) {
        await guild.channels.create({ name: "🔑・code-sniper", type: ChannelType.GuildText, parent: phCat.id, reason: "PhantomHub update" });
        console.log(`  ✅ #code-sniper`);
    } else { console.log(`  ✓ #code-sniper exists`); }

    console.log(`\nDone.`);
    process.exit(0);
});

client.login(token);
