import type { RequestHandler } from './$types';
import * as checks from '$lib/schemas/proofObligation';
import checkApiSchema from '$lib/schemas/apiJsonCheck';
import { getProofObligation } from '$lib/server/db/proofObligationPages';
import { json } from '@sveltejs/kit';
import { proofObligation } from '$lib/server/db/schema';
import { inArray, notInArray } from 'drizzle-orm';
import { db } from '$lib/server/db';
import { superValidate } from 'sveltekit-superforms';
import { zod4 } from 'sveltekit-superforms/adapters';
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
	const form = await superValidate(request, zod4(checks.PUT), {
		strict: true
	});
	if (!form.valid) {
		return json({ errors: form.errors }, { status: 400 });
	}
	const jsonData = JSON.parse(await form.data.proofObligation.text());
	const result = await newProofObligation(
		form.data.projectId,
		form.data.revision,
		form.data.name,
		jsonData
	);
	if (result.code !== 200) {
		return json({ errors: form.errors, error: result.error }, { status: result.code });
	}
	return json({ errors: form.errors, success: true }, { status: 200 });
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
