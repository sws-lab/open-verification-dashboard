import { db } from '$lib/server/db';
import { conflict } from '$lib/server/db/schema';
import { type RequestHandler, json } from '@sveltejs/kit';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
	const { id } = params;
	const conflictId = Number(id);
	if (isNaN(conflictId)) {
		return json(
			{
				error: 'Invalid or missing conflict ID.'
			},
			{ status: 400 }
		);
	}
	try {
		const conflicts = await db
			.select({
				id: conflict.id,
				conflicts: conflict.conflicts
			})
			.from(conflict)
			.where(eq(conflict.id, conflictId))
			.limit(1);
		console.log('Retrieved conflicts:', conflicts);
		if (conflicts.length === 0) {
			return json(
				{
					error: 'Conflict not found.'
				},
				{ status: 404 }
			);
		}
		return new Response(JSON.stringify(conflicts[0].conflicts), {
			headers: {
				'Content-Type': 'application/json',
				'Content-Disposition': `attachment; filename=conflict_${id}.json`
			}
		});
	} catch (error) {
		console.error('Error retrieving conflict:', error);
		return json(
			{
				error: 'Database error: Unable to retrieve conflict.'
			},
			{ status: 500 }
		);
	}
};
