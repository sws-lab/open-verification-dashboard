import { db } from '$lib/server/db';
import { proofObligation } from '$lib/server/db/schema';
import { eq } from 'drizzle-orm';
import { json, type RequestHandler } from '@sveltejs/kit';

export const GET: RequestHandler = async ({ params }) => {
	const { id } = params;
	let obligationId = Number(id);
	if (isNaN(obligationId)) {
		return json(
			{
				error: 'Invalid or missing proof obligation ID.'
			},
			{ status: 400 }
		);
	}
	const content = await db
		.select({ proofObligation })
		.from(proofObligation)
		.where(eq(proofObligation.id, obligationId))
		.limit(1);
	if (content.length === 0) {
		return json(
			{
				error: 'Proof obligation not found'
			},
			{
				status: 404
			}
		);
	}
	return new Response(JSON.stringify(content[0].proofObligation), {
		headers: {
			'Content-Type': 'application/json',
			'Content-Disposition': `attachment; filename=proof_obligation_${id}.json`
		}
	});
};
