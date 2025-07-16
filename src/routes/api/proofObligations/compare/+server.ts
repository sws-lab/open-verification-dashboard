import checkApiSchema from "$lib/schemas/apiJsonCheck";
import { json, type RequestHandler } from "@sveltejs/kit";
import * as checks from "$lib/schemas/proofObligationsComparison";
import { db } from "$lib/server/db";
import { conflict } from "$lib/server/db/schema";
import { and, eq } from "drizzle-orm";

export const POST: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}

	try {
		const comparison = await db.select({id: conflict.id})
			.from(conflict)
			.where(
				and(
					eq(conflict.proofObligationId1, result.data.proofObligationId1),
					eq(conflict.proofObligationId2, result.data.proofObligationId2),
				)
			).limit(1);
		if (comparison.length > 0) {
			return json({ id: comparison[0].id });
		}
	} catch (err) {
		console.error("Error fetching comparison:", err);
		return json({ success: false, error: "Internal server error" }, { status: 500 });
	}



	return json({ success: false, error: "Comparison not found (TODO)" }, { status: 404 });
}