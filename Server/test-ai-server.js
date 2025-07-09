// Test the AI Attack Analyzer server endpoints
import dotenv from "dotenv";
dotenv.config({ path: ".env.local" });

const SERVER_URL = "http://localhost:3000";

// Test function
async function testEndpoint(endpoint, data) {
	try {
		console.log(`\n🧪 Testing ${endpoint}...`);

		const response = await fetch(`${SERVER_URL}${endpoint}`, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify(data),
		});

		const result = await response.json();

		if (result.success) {
			console.log(`✅ ${endpoint} - Success!`);
			console.log(
				"Sample response:",
				JSON.stringify(result, null, 2).substring(0, 200) + "..."
			);
		} else {
			console.log(`❌ ${endpoint} - Failed:`, result.error);
		}
	} catch (error) {
		console.log(`❌ ${endpoint} - Error:`, error.message);
	}
}

async function runTests() {
	console.log("🤖 Testing AI Attack Analyzer Endpoints");
	console.log("========================================");

	// Test health endpoint
	try {
		const healthResponse = await fetch(`${SERVER_URL}/health`);
		const health = await healthResponse.json();
		console.log("✅ Health check:", health.message);
	} catch (error) {
		console.log(
			"❌ Server not running. Please start with: node ai-attack-analyzer.js"
		);
		return;
	}

	// Test base analysis
	await testEndpoint("/api/analyze-base", {
		troopComposition: "Giants: 10, Wizards: 20, Archers: 50, Wall Breakers: 8",
		targetResources: "Gold and Elixir priority",
	});

	// Test deployment optimization
	await testEndpoint("/api/optimize-deployment", {
		troopType: "Giant",
		quantity: 10,
		currentSituation: "Early battle phase, defenses still active",
		enemyDefenses: "Archer towers and cannons targeting",
	});

	// Test strategy adaptation
	await testEndpoint("/api/adapt-strategy", {
		battleProgress: 45,
		remainingTroops: "Wizards: 15, Archers: 30, Heroes available",
		enemyStatus: "Most defenses down, core still protected",
		objectives: "Need to reach storages for 2-star victory",
	});

	// Test army optimization
	await testEndpoint("/api/optimize-army", {
		targetBaseType: "farming base",
		availableTroops: "All troops available",
		attackGoal: "resource farming",
		townHallLevel: 11,
	});

	// Test visual attack planning with a dummy base64 image
	console.log("\n🧪 Testing /api/plan-attack-visual...");
	try {
		// Create a simple dummy base64 image for testing
		const dummyImage =
			"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

		const response = await fetch(`${SERVER_URL}/api/plan-attack-visual`, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify({
				baseImage: dummyImage,
				availableArmy:
					"Giants: 8, Wizards: 16, Archers: 40, Wall Breakers: 6, Barbarian King, Archer Queen",
				attackGoal: "resources",
			}),
		});

		const result = await response.json();

		if (result.success) {
			console.log(`✅ /api/plan-attack-visual - Success!`);
			console.log(
				"Sample response:",
				JSON.stringify(result, null, 2).substring(0, 300) + "..."
			);
		} else {
			console.log(`❌ /api/plan-attack-visual - Failed:`, result.error);
		}
	} catch (error) {
		console.log(`❌ /api/plan-attack-visual - Error:`, error.message);
	}

	// Test battle learning
	await testEndpoint("/api/learn-from-battle", {
		battleResult: "2 stars achieved",
		strategyUsed: "Giant-Wizard attack",
		troopsUsed: "Giants, Wizards, Archers, Wall Breakers",
		outcome: "Good resource gain, could improve timing",
	});

	console.log("\n🎉 Testing complete!");
}

runTests();
