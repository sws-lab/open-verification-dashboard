import type { RequestHandler } from "./$types";
import * as checks from "$lib/schemas/proofObligations"
import checkApiSchema from "$lib/schemas/apiJsonCheck";
import { getProofObligation } from "$lib/server/db/proofObligationPages";
import { json } from "@sveltejs/kit";

export const GET: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { page, projectId, revision, filter } = result.data;
	try {
		return json(await getProofObligation(page, projectId, revision, filter));
	} catch (err: any) {
		console.error(err);
		return json({
			error: err.message || "An error occurred while fetching proof obligations"
		}, { status: 500 });
	}
}