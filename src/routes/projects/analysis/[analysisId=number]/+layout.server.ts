import { db } from '$lib/server/db';
import { conflict, projects, proofObligation } from '$lib/server/db/schema';
import type { DashboardOutput } from '$lib/conflicts/conflict';
import { eq, lte, and } from 'drizzle-orm';
import type { LayoutServerLoad } from './$types';
import { error, isHttpError } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import { alias } from 'drizzle-orm/pg-core';
import type { Stats } from '$lib/conflicts/stats';

export const load: LayoutServerLoad = async ({ params }) => {
	const analysisId = Number(params.analysisId);

	try {
		const po1 = alias(proofObligation, 'po1');
		const po2 = alias(proofObligation, 'po2');
		const analysis = await db
			.select({
				id: conflict.id,
				revision: conflict.projectRevision,
				projectId: conflict.projectId,
				conflicts: conflict.conflicts,
				stats: conflict.stats,
				po1Name: po1.name,
				po2Name: po2.name
			})
			.from(conflict)
			.innerJoin(projects, eq(conflict.projectId, projects.id))
			.innerJoin(po1, eq(po1.id, conflict.proofObligationId1))
			.innerJoin(po2, eq(po2.id, conflict.proofObligationId2))
			.where(
				and(
					lte(conflict.projectRevision, projects.revision),
					eq(conflict.id, analysisId),
					eq(conflict.version, Number(env.VERSION))
				)
			);

		if (!analysis || analysis.length === 0) {
			error(404, 'Analysis not found.');
		}

		const currentAnalysis = analysis[0] as {
			id: number;
			revision: number;
			projectId: number;
			conflicts: DashboardOutput;
			stats: Stats;
			po1Name: string;
			po2Name: string;
		};

		return {
			analysis: currentAnalysis
		};
	} catch (err) {
		if (isHttpError(err)) {
			throw err;
		}
		console.error('Error fetching analysis:', err);
		error(500, 'Failed to load analysis data.');
	}
};
