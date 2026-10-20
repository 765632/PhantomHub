const { Client, GatewayIntentBits, ChannelType, PermissionsBitField } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    console.log(`Adding key-gen to: ${guild.name}\n`);

    const phCat = guild.channels.cache.find(c => c.name === "PHANTOMHUB" && c.type === ChannelType.GuildCategory);
    if (!phCat) { console.log("No PHANTOMHUB category found!"); process.exit(1); }

    const adminRole = guild.roles.cache.find(r => r.name.includes("Admin"));
    const modRole = guild.roles.cache.find(r => r.name.includes("Moderator"));

    // Create Verified role (given when key is redeemed)
    let verifiedRole = guild.roles.cache.find(r => r.name === "✅ Verified");
    if (!verifiedRole) {
        verifiedRole = await guild.roles.create({ name: "✅ Verified", color: "#00FF00", hoist: true, reason: "Key system" });
        console.log(`  ✅ Created role "✅ Verified"`);
    } else { console.log(`  ✓ Role "✅ Verified" exists`); }

    // Create private key-gen channel
    const existing = guild.channels.cache.find(c => c.name.includes("key-gen"));
    if (!existing) {
        const overwrites = [
            { id: guild.id, deny: [PermissionsBitField.Flags.ViewChannel] },
            { id: client.user.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] },
        ];
        if (adminRole) overwrites.push({ id: adminRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
        if (modRole) overwrites.push({ id: modRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });

        await guild.channels.create({
            name: "🔐・key-gen",
            type: ChannelType.GuildText,
            parent: phCat.id,
            permissionOverwrites: overwrites,
            reason: "Key system — admin only",
        });
        console.log(`  ✅ #key-gen (private)`);
    } else { console.log(`  ✓ #key-gen exists`); }

    console.log(`\nDone.`);
    process.exit(0);
});

client.login(token);
