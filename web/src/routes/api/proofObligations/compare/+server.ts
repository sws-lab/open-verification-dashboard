import checkApiSchema from '$lib/schemas/apiJsonCheck';
import { json, type RequestHandler } from '@sveltejs/kit';
import * as checks from '$lib/schemas/proofObligationsComparison';
import { db } from '$lib/server/db';
import { conflict, proofObligation } from '$lib/server/db/schema';
import { and, eq, or, sql } from 'drizzle-orm';
import { env } from '$env/dynamic/private';
import { compareProofObligations } from '$lib/server/dashboard';
import { calculateStats, type Stats } from '$lib/conflicts/stats';

export const POST: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}

	const current_version = env.VERSION ? parseInt(env.VERSION, 10) : 0;
	let update_id: number | null = null;

	console.log(
		`Comparing proof obligations with IDs ${result.data.proofObligationId1} and ${result.data.proofObligationId2} at version ${current_version}`
	);

	try {
		const comparison = await db
			.select({ id: conflict.id, version: conflict.version })
			.from(conflict)
			.where(
				or(
					and(
						eq(conflict.proofObligationId1, result.data.proofObligationId1),
						eq(conflict.proofObligationId2, result.data.proofObligationId2)
					),
					and(
						eq(conflict.proofObligationId1, result.data.proofObligationId2),
						eq(conflict.proofObligationId2, result.data.proofObligationId1)
					)
				)
			)
			.limit(1);
		if (comparison.length > 0) {
			if (comparison[0].version === current_version) {
				console.log(
					`Found existing conflict with ID ${comparison[0].id} and matching version ${current_version}`
				);
				return json({ success: true, id: comparison[0].id });
			}
			console.log(
				`Found existing conflict with ID ${comparison[0].id} but version ${comparison[0].version} does not match current version ${current_version}`
			);
			update_id = comparison[0].id;
		} else {
			console.log('No existing conflict found, computing new comparison');
		}
	} catch (err) {
		console.error('Error fetching comparison:', err);
		return json({ success: false, error: 'Internal server error' }, { status: 500 });
	}

	const proofObligations = await db
		.select({
			id: proofObligation.id,
			projectId: proofObligation.projectId,
			projectRevision: proofObligation.projectRevision,
			proofObligation: proofObligation.proofObligation
		})
		.from(proofObligation)
		.where(
			or(
				eq(proofObligation.id, result.data.proofObligationId1),
				eq(proofObligation.id, result.data.proofObligationId2)
			)
		)
		.limit(2);

	if (proofObligations.length !== 2) {
		return json({ success: false, error: 'Proof obligations not found' }, { status: 404 });
	}

	const [proofObligation1, proofObligation2] = proofObligations;

	let dashboard_result;
	try {
		console.log('Waiting for dashboard process to complete...');
		const program_output = await compareProofObligations(proofObligation1, proofObligation2);
		if (!program_output.success) {
			return json(program_output, { status: 500 });
		}
		dashboard_result = program_output.data;
	} catch (err) {
		console.error('Error during dashboard process execution:', err);
		return json({ success: false, error: 'Internal server error' }, { status: 500 });
	}

	const stats: Stats = {};
	for (const [file, conflicts] of Object.entries(dashboard_result.conflicts)) {
		stats[file] = calculateStats(conflicts);
	}

	try {
		if (update_id !== null) {
			console.log(`Updating existing conflict with ID ${update_id}`);
			await db
				.update(conflict)
				.set({
					version: current_version,
					conflicts: dashboard_result,
					lastUpdated: sql`now()`
				})
				.where(eq(conflict.id, update_id));
			return json({ id: update_id });
		}
		const id = await db
			.insert(conflict)
			.values({
				version: current_version,
				projectId: proofObligation1.projectId,
				projectRevision: proofObligation1.projectRevision,
				proofObligationId1: proofObligation1.id,
				proofObligationId2: proofObligation2.id,
				conflicts: dashboard_result,
				stats: stats
			})
			.onConflictDoUpdate({
				target: conflict.id,
				set: {
					version: current_version,
					conflicts: dashboard_result,
					lastUpdated: sql`now()`
				}
			})
			.returning({ id: conflict.id });
		if (id.length > 0) {
			return json({ success: true, id: id[0].id });
		}
	} catch (err) {
		console.error('Error inserting conflict into database:', err);
		return json({ success: false, error: 'Internal server error' }, { status: 500 });
	}

	return json({ success: false, error: 'Should never be reached' }, { status: 418 });
};
