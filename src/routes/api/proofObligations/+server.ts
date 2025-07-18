import type { RequestHandler } from './$types';
import * as checks from '$lib/schemas/proofObligation';
import checkApiSchema from '$lib/schemas/apiJsonCheck';
import { getProofObligation } from '$lib/server/db/proofObligationPages';
import { json } from '@sveltejs/kit';
import { proofObligation } from '$lib/server/db/schema';
import { inArray, notInArray } from 'drizzle-orm';
import { db } from '$lib/server/db';

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
		return json(
			{
				error: err.message || 'An error occurred while fetching proof obligations'
			},
			{ status: 500 }
		);
	}
};

export const DELETE: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.DELETE);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { ids, reversed } = result.data;
	try {
		await db
			.delete(proofObligation)
			.where(reversed ? notInArray(proofObligation.id, ids) : inArray(proofObligation.id, ids));
		return new Response(null, { status: 204 });
	} catch (err: any) {
		console.error(err);
		return json(
			{
				error: err.message || 'An error occurred while deleting proof obligations'
			},
			{ status: 500 }
		);
	}
};
