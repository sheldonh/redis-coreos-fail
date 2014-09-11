var redis = require('haredis');
var client = redis.createClient([process.env.MASTER_PORT_10000_TCP_ADDR + ':10000']);

var start = process.env.COUNTER_START || 0;
var step = process.env.COUNTER_STEP || 5;
var interval = process.env.COUNTER_INTERVAL || 1000;

var makeInc = function(current, step, interval) {
	return function() {
		setTimeout(makeInc(current + step, step, interval), interval);

		client.rpush('debug:stack', current, function(err, reply) {
			if (err !== null) {
				console.log("error pushing counter " + current + ", aborting");
				throw err;
			} else {
				console.log("pushed counter " + current);
			}
		});
	}
}

makeInc(start, step, interval)();
