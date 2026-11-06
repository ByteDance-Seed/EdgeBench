// finance_manager.js - Manage park finances
var main = function() {
    if (context.mode !== "normal") return;
    
    context.subscribe("interval.day", function() {
        // Pay off loan when we have surplus cash
        if (park.cash > 50000 && park.bankLoan > 0) {
            var payoff = Math.min(park.bankLoan, 10000);
            context.executeAction("parksetloan", {
                value: park.bankLoan - payoff
            }, function(r) {
                if (r.error === 0) {
                    console.log("Paid off " + payoff + " loan. Remaining: " + park.bankLoan);
                }
            });
        }
        
        // Set entrance fee based on park rating (if park charges entry)
        if (!park.getFlag("freeParkEntry")) {
            var fee = Math.min(Math.floor(park.rating / 10), 100);
            context.executeAction("parksetentrancefee", {value: fee});
        }
        
        // Start marketing campaign if cash allows
        // type: 0=freeEntry, 1=freeRides, 2=halfPriceEntry, 3=freeFoodDrinks, 4=ads, 5=umbrellas
        if (park.cash > 80000 && date.day === 1) {
            context.executeAction("parkmarketing", {
                type: 0,        // free entry campaign
                item: 0,
                duration: 4     // weeks
            }, function(r) {
                console.log("Marketing campaign: err=" + r.error);
            });
        }
    });
};

registerPlugin({
    name: "FinanceManager", version: "1.0", authors: ["sample"],
    type: "remote", licence: "MIT", targetApiVersion: 34, main: main
});
