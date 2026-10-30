// park_info.js - Displays park statistics
var main = function() {
    if (context.mode !== "normal") return;
    
    context.subscribe("interval.day", function() {
        console.log("=== Park Info ===");
        console.log("Date: Y" + date.year + " M" + date.month + " D" + date.day);
        console.log("Cash: " + park.cash);
        console.log("Company Value: " + park.companyValue);
        console.log("Bank Loan: " + park.bankLoan);
        console.log("Guests: " + park.guests);
        console.log("Rating: " + park.rating);
        console.log("Entrance Fee: " + park.entranceFee);
        console.log("Free Entry: " + park.getFlag("freeParkEntry"));
        
        var rides = map.rides;
        console.log("Rides: " + rides.length);
        for (var i = 0; i < rides.length; i++) {
            var r = rides[i];
            if (r.status === "open") {
                console.log("  " + r.name + " profit=" + r.totalProfit + 
                    " excitement=" + r.excitement + " intensity=" + r.intensity);
            }
        }
    });
};

registerPlugin({
    name: "ParkInfo", version: "1.0", authors: ["sample"],
    type: "remote", licence: "MIT", targetApiVersion: 34, main: main
});
