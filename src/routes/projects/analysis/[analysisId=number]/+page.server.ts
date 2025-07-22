import { db } from '$lib/server/db';
import { conflict, projects } from '$lib/server/db/schema';
import type { DashboardOutput } from '$lib/types/conflict';
import { eq, lte, and } from 'drizzle-orm';
import type { PageServerLoad } from './$types';
import { error, isHttpError } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ params }) => {
	const analysisId = Number(params.analysisId);

	try {
		const analysis = await db
			.select({
				id: conflict.id,
				revision: conflict.projectRevision,
				projectId: conflict.projectId,
				conflicts: conflict.conflicts
			})
			.from(conflict)
			.innerJoin(projects, eq(conflict.projectId, projects.id))
			.where(and(lte(conflict.projectRevision, projects.revision), eq(conflict.id, analysisId)));

		if (!analysis || analysis.length === 0) {
			error(404, 'Analysis not found.');
		}

		const currentAnalysis = analysis[0] as {
			id: number;
			revision: number;
			projectId: number;
			conflicts: DashboardOutput[];
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
