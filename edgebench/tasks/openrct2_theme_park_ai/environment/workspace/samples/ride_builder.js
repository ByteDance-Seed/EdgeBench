// ride_builder.js - Create rides via Game Actions
var main = function() {
    if (context.mode !== "normal") return;
    
    // List available ride objects
    var rideObjects = context.getAllObjects("ride");
    console.log("Available ride types: " + rideObjects.length);
    for (var i = 0; i < Math.min(rideObjects.length, 10); i++) {
        var obj = rideObjects[i];
        console.log("  [" + i + "] " + obj.identifier + " name=" + obj.name);
    }
    
    // Create a ride (carousel / merry-go-round)
    context.executeAction("ridecreate", {
        rideType: 36,           // ride type ID (varies by version)
        rideObject: 0,          // object index
        entranceObject: 0,      // entrance style
        colour1: 0, colour2: 0, // colours
        inspectionInterval: 2   // required parameter
    }, function(result) {
        if (result.error === 0) {
            console.log("Created ride ID: " + result.ride);
            // Set ride price
            context.executeAction("ridesetprice", {
                ride: result.ride,
                price: 20,      // $2.00
                isPrimaryPrice: true
            });
        } else {
            console.log("Failed to create ride: error " + result.error);
        }
    });
};

registerPlugin({
    name: "RideBuilder", version: "1.0", authors: ["sample"],
    type: "remote", licence: "MIT", targetApiVersion: 34, main: main
});
