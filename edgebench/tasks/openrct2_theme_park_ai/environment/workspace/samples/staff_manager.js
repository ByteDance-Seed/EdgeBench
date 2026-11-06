// staff_manager.js - Hire and manage staff
var main = function() {
    if (context.mode !== "normal") return;
    
    // Hire a handyman (type 0)
    context.executeAction("staffhire", {
        autoPosition: true,
        staffType: 0,       // 0=handyman, 1=mechanic, 2=security, 3=entertainer
        costumeIndex: 0,
        staffOrders: 15     // bitmask: 1=sweep, 2=water, 4=bins, 8=mow
    }, function(result) {
        if (result.error === 0) {
            console.log("Hired handyman, peep ID: " + result.peep);
        }
    });
    
    // Hire a mechanic (type 1)
    context.executeAction("staffhire", {
        autoPosition: true,
        staffType: 1,
        costumeIndex: 0,
        staffOrders: 3      // bitmask: 1=inspect, 2=fix
    }, function(result) {
        if (result.error === 0) {
            console.log("Hired mechanic, peep ID: " + result.peep);
        }
    });
};

registerPlugin({
    name: "StaffManager", version: "1.0", authors: ["sample"],
    type: "remote", licence: "MIT", targetApiVersion: 34, main: main
});
