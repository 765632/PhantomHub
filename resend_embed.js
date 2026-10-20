const { Client, GatewayIntentBits, EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle, ChannelType } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    const codeCh = guild.channels.cache.find(c => c.name.includes("code-sniper"));
    if (!codeCh) { console.log("No code-sniper channel!"); process.exit(1); }

    // Delete old messages from bot
    try {
        const msgs = await codeCh.messages.fetch({ limit: 20 });
        const botMsgs = msgs.filter(m => m.author.id === client.user.id);
        for (const [, m] of botMsgs) { await m.delete(); }
        console.log(`Deleted ${botMsgs.size} old messages`);
    } catch (e) { console.log("Couldn't clean old msgs:", e.message); }

    // Single clean embed like brxxks
    const mainEmbed = new EmbedBuilder()
        .setColor(0x0a0a0a)
        .setTitle("PhantomHub's Code Sniper")
        .setDescription("Use the buttons below to manage your key")
        .setFooter({ text: "PhantomHub | v1\nPhantomHub • Key System" });

    const row1 = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId("view_script").setLabel("View Script").setStyle(ButtonStyle.Primary),
        new ButtonBuilder().setCustomId("redeem_key").setLabel("Redeem Key").setStyle(ButtonStyle.Success),
        new ButtonBuilder().setCustomId("key_info").setLabel("Key Info").setStyle(ButtonStyle.Secondary),
    );

    const row2 = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId("get_buyer_role").setLabel("Get Buyer Role").setStyle(ButtonStyle.Secondary),
        new ButtonBuilder().setCustomId("reset_hwid").setLabel("Reset HWID").setStyle(ButtonStyle.Danger),
    );

    await codeCh.send({ embeds: [mainEmbed], components: [row1, row2] });
    console.log("✅ Embed sent");
    process.exit(0);
});

client.login(token);
