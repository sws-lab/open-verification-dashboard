import type { RequestHandler } from './$types';
import * as checks from '$lib/schemas/proofObligation';
import checkApiSchema from '$lib/schemas/apiJsonCheck';
import { getProofObligation } from '$lib/server/db/proofObligationPages';
import { json } from '@sveltejs/kit';
import { proofObligation } from '$lib/server/db/schema';
import { inArray, notInArray } from 'drizzle-orm';
import { db } from '$lib/server/db';
import { newProofObligation } from '$lib/server/proofObligations';

export const GET: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { page, projectId, revision, filter } = result.data;
	try {
		return json(await getProofObligation(page, projectId, revision, filter));
	} catch (err) {
		console.error(err);
		return json(
			{
				error: 'An error occurred while fetching proof obligations'
			},
			{ status: 500 }
		);
	}
};

export const PUT: RequestHandler = async ({ request }) => {
	// check the request body size to ensure it is not too large
	const maxSize = 520 * 1024 * 1024; // 500 MB
	const contentLength = request.headers.get('content-length');
	if (contentLength && parseInt(contentLength, 10) > maxSize) {
		return json({ error: 'Request body is too large' }, { status: 413 });
	}

	const result = await checkApiSchema(request, checks.PUT);
	if (!result.success) {
		return json(result, { status: 400 });
	}

	const insertionResult = await newProofObligation(
		result.data.projectId,
		result.data.revision,
		result.data.name,
		result.data.proofObligation
	);
	if (insertionResult.code !== 200) {
		return json({ error: insertionResult.error }, { status: insertionResult.code });
	}
	return json({ success: true }, { status: 200 });
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
	} catch (err) {
		console.error(err);
		return json(
			{
				error: 'An error occurred while deleting proof obligations'
			},
			{ status: 500 }
		);
	}
};
