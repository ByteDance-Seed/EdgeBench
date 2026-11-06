// Baseline OpenRCT2 AI plugin - minimal no-op that keeps the engine running.
// Agent should replace this with normal park-management logic.
var main = function() {
    if (context.mode !== "normal") return;
    context.executeAction("gamesetspeed", {speed: 4});

    var ticks = 0;
    context.subscribe("interval.tick", function() {
        ticks++;
        if (ticks % 600 === 0) {
            console.log("progress companyValue " + park.companyValue + ", rating " + park.rating +
                        ", guests " + park.guests + ", cash " + park.cash);
        }
    });
};

registerPlugin({
    name: "SEBenchBaseline",
    version: "1.0",
    authors: ["sebench"],
    type: "remote",
    licence: "MIT",
    targetApiVersion: 34,
    main: main
});
