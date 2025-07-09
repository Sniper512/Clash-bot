// Test visual attack planning endpoint specifically
import dotenv from "dotenv";
dotenv.config({ path: ".env.local" });

const SERVER_URL = "http://localhost:3000";

async function testVisualAttackPlanning() {
	console.log("🧪 Testing Visual Attack Planning Endpoint");
	console.log("==========================================");

	try {
		// Create a simple dummy base64 image for testing
		const dummyImage =
			"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

		console.log("📤 Sending request to /api/plan-attack-visual...");

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
				playerLevel: 11,
			}),
		});

		console.log("📥 Response status:", response.status);
		console.log("📥 Response headers:", Object.fromEntries(response.headers));

		const responseText = await response.text();
		console.log(
			"📥 Raw response (first 500 chars):",
			responseText.substring(0, 500)
		);

		try {
			const result = JSON.parse(responseText);

			if (result.success) {
				console.log("✅ Visual Attack Planning - Success!");
				console.log("🎯 Attack Plan Preview:");
				console.log("  - Base Layout:", result.attackPlan.baseLayout);
				console.log("  - Weaknesses:", result.attackPlan.weaknesses);
				console.log("  - Attack Vectors:", result.attackPlan.attackVectors);
				console.log("  - Success Metrics:", result.attackPlan.successMetrics);
			} else {
				console.log("❌ Visual Attack Planning - Failed:", result.error);
				console.log("📋 Details:", result.details);
			}
		} catch (parseError) {
			console.log("❌ Failed to parse JSON response:", parseError.message);
		}
	} catch (error) {
		console.log("❌ Request failed:", error.message);
	}
}

testVisualAttackPlanning();
